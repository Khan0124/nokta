const crypto = require('crypto');
const config = require('../../config/config');
const redisManager = require('../../config/redis');
const { logger } = require('../../config/logger');
const featureFlagsConfig = require('../../config/featureFlags');

const GLOBAL_SCOPE = 'global';

let baseCache = {
  expiresAt: 0,
  flags: null
};

const normalizeRollout = (raw = {}) => {
  if (!raw || typeof raw !== 'object') {
    return { strategy: 'all', percentage: 100 };
  }

  const strategy = raw.strategy || 'all';
  const normalized = { strategy };

  if (strategy === 'percentage') {
    const percentage = Number(raw.percentage);
    normalized.percentage = Number.isFinite(percentage)
      ? Math.min(Math.max(percentage, 0), 100)
      : 0;
  }

  if (strategy === 'roles' && Array.isArray(raw.roles)) {
    normalized.roles = raw.roles;
  }

  if (strategy === 'branches' && Array.isArray(raw.branches)) {
    normalized.branches = raw.branches;
  }

  if (raw.segment) {
    normalized.segment = raw.segment;
  }

  return normalized;
};

const cloneFlag = (flag) => ({
  key: flag.key,
  description: flag.description ?? '',
  enabled: flag.enabled ?? false,
  tags: Array.isArray(flag.tags) ? [...flag.tags] : [],
  owner: flag.owner ?? null,
  since: flag.since ?? null,
  environments: Array.isArray(flag.environments) ? [...flag.environments] : [],
  rollout: normalizeRollout(flag.rollout),
  notes: flag.notes ?? null,
  defaultEnabled: typeof flag.defaultEnabled === 'boolean' ? flag.defaultEnabled : Boolean(flag.defaultEnabled),
  sources: { ...(flag.sources || {}) },
  updatedAt: flag.updatedAt,
  updatedBy: flag.updatedBy,
  updatedByName: flag.updatedByName
});

const getBaseFlags = () => {
  const now = Date.now();
  if (baseCache.flags && baseCache.expiresAt > now) {
    return baseCache.flags;
  }

  const base = featureFlagsConfig.getBaseFlags();
  baseCache = {
    flags: base,
    expiresAt: now + (config.featureFlags.cacheTtlSeconds * 1000)
  };

  return base;
};

const getCacheKey = (tenantId = GLOBAL_SCOPE) => {
  const scope = tenantId || GLOBAL_SCOPE;
  return `${config.featureFlags.namespace}:${scope}`;
};

const fetchOverrides = async (tenantId = GLOBAL_SCOPE) => {
  try {
    const key = getCacheKey(tenantId);
    const overrides = await redisManager.get(key);
    return overrides || {};
  } catch (error) {
    logger.error('Failed to fetch feature flag overrides', {
      tenantId,
      error: error.message
    });
    return {};
  }
};

const persistOverrides = async (tenantId, overrides) => {
  const key = getCacheKey(tenantId);
  await redisManager.set(key, overrides);
};

const applyRuntimeOverride = (target, override, sourceKey) => {
  if (!override) {
    return target;
  }

  if (Object.prototype.hasOwnProperty.call(override, 'enabled')) {
    target.enabled = Boolean(override.enabled);
  }

  if (Object.prototype.hasOwnProperty.call(override, 'rollout')) {
    target.rollout = normalizeRollout(override.rollout);
  }

  if (Object.prototype.hasOwnProperty.call(override, 'notes')) {
    target.notes = override.notes;
  }

  if (override.updatedAt) {
    target.updatedAt = override.updatedAt;
  }

  if (Object.prototype.hasOwnProperty.call(override, 'updatedBy')) {
    target.updatedBy = override.updatedBy;
  }

  if (Object.prototype.hasOwnProperty.call(override, 'updatedByName')) {
    target.updatedByName = override.updatedByName;
  }

  target.sources = target.sources || {};
  target.sources[sourceKey] = {
    enabled: override.enabled,
    rollout: override.rollout ? normalizeRollout(override.rollout) : undefined,
    notes: override.notes,
    updatedAt: override.updatedAt,
    updatedBy: override.updatedBy,
    updatedByName: override.updatedByName
  };

  return target;
};

const determineActiveSource = (flag) => {
  if (flag.sources?.tenant) {
    return 'tenant';
  }
  if (flag.sources?.global) {
    return 'global';
  }
  if (flag.sources?.environment) {
    return 'environment';
  }
  if (flag.sources?.default) {
    return 'default';
  }
  return 'unknown';
};

const computeBucket = (seed) => {
  const hash = crypto
    .createHash('sha1')
    .update(seed)
    .digest('hex');

  const slice = hash.substring(0, 8);
  return parseInt(slice, 16) % 100;
};

const evaluateRollout = (flag, context = {}) => {
  if (!flag.enabled) {
    return false;
  }

  const strategy = flag.rollout?.strategy || 'all';

  if (strategy === 'all') {
    return true;
  }

  if (strategy === 'percentage') {
    const seed = `${flag.key}:${context.userId || context.sessionId || context.tenantId || 'global'}`;
    const bucket = computeBucket(seed);
    return bucket < (flag.rollout?.percentage ?? 0);
  }

  if (strategy === 'roles') {
    if (!context.role) {
      return false;
    }
    return Array.isArray(flag.rollout?.roles)
      ? flag.rollout.roles.includes(context.role)
      : false;
  }

  if (strategy === 'branches') {
    if (context.branchId == null) {
      return false;
    }
    const branchId = Array.isArray(flag.rollout?.branches)
      ? flag.rollout.branches
      : [];
    return branchId.includes(Number(context.branchId)) || branchId.includes(String(context.branchId));
  }

  return flag.enabled;
};

const listFlags = async ({ tenantId, includeMetadata = false, context = {} } = {}) => {
  const baseFlags = getBaseFlags();
  const globalOverrides = await fetchOverrides(GLOBAL_SCOPE);
  const tenantOverrides = tenantId ? await fetchOverrides(tenantId) : {};

  const keys = new Set([
    ...Object.keys(baseFlags),
    ...Object.keys(globalOverrides),
    ...Object.keys(tenantOverrides)
  ]);

  const results = [];

  keys.forEach((key) => {
    const base = baseFlags[key]
      ? cloneFlag(baseFlags[key])
      : cloneFlag({ key });

    if (!base.key) {
      base.key = key;
    }

    if (globalOverrides[key]) {
      applyRuntimeOverride(base, globalOverrides[key], 'global');
    }

    if (tenantOverrides[key]) {
      applyRuntimeOverride(base, tenantOverrides[key], 'tenant');
    }

    const evaluationContext = {
      tenantId,
      branchId: context.branchId,
      role: context.role,
      userId: context.userId,
      sessionId: context.sessionId
    };

    const response = {
      key,
      description: base.description,
      enabled: base.enabled,
      evaluation: evaluateRollout(base, evaluationContext),
      rollout: base.rollout,
      tags: base.tags,
      owner: base.owner,
      since: base.since,
      notes: base.notes,
      defaultEnabled: base.defaultEnabled,
      environments: base.environments,
      activeSource: determineActiveSource(base)
    };

    if (includeMetadata) {
      response.sources = base.sources;
      response.updatedAt = base.updatedAt;
      response.updatedBy = base.updatedBy;
      response.updatedByName = base.updatedByName;
    }

    results.push(response);
  });

  return results.sort((a, b) => a.key.localeCompare(b.key));
};

const getFlag = async (flagKey, options = {}) => {
  const flags = await listFlags(options);
  return flags.find((flag) => flag.key === flagKey) || null;
};

const updateFlag = async (flagKey, payload, { tenantId, actor, scope = 'tenant' } = {}) => {
  if (!config.featureFlags.allowRuntimeUpdates) {
    throw new Error('Runtime updates for feature flags are disabled');
  }

  const targetScope = scope === 'global' ? GLOBAL_SCOPE : tenantId;

  if (!targetScope) {
    throw new Error('Tenant ID is required for tenant-scoped updates');
  }

  const overrides = await fetchOverrides(targetScope);

  overrides[flagKey] = {
    enabled: payload.enabled,
    rollout: normalizeRollout(payload.rollout),
    notes: payload.notes ?? null,
    updatedAt: new Date().toISOString(),
    updatedBy: actor?.id ?? null,
    updatedByName: actor?.username || actor?.email || null
  };

  await persistOverrides(targetScope, overrides);
  baseCache.expiresAt = 0;

  return getFlag(flagKey, { tenantId });
};

const removeOverride = async (flagKey, { tenantId, scope = 'tenant' } = {}) => {
  const targetScope = scope === 'global' ? GLOBAL_SCOPE : tenantId;

  if (!targetScope) {
    throw new Error('Tenant ID is required for tenant-scoped removals');
  }

  const overrides = await fetchOverrides(targetScope);
  if (overrides[flagKey]) {
    delete overrides[flagKey];
    await persistOverrides(targetScope, overrides);
  }

  baseCache.expiresAt = 0;
  return getFlag(flagKey, { tenantId });
};

const evaluateFlag = async (flagKey, context = {}) => {
  const flag = await getFlag(flagKey, {
    tenantId: context.tenantId,
    context,
    includeMetadata: true
  });

  if (!flag) {
    return false;
  }

  return flag.evaluation;
};

module.exports = {
  listFlags,
  getFlag,
  updateFlag,
  removeOverride,
  evaluateFlag,
  GLOBAL_SCOPE
};
