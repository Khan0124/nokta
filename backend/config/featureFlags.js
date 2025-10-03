const fs = require('fs');
const path = require('path');
const { logger } = require('./logger');

const FLAGS_FILE = path.join(__dirname, 'feature_flags.json');

let cachedDefaults = null;
let cachedEnvOverrides;

const normalizeRollout = (raw = {}) => {
  if (!raw || typeof raw !== 'object') {
    return { strategy: 'all', percentage: 100 };
  }

  const strategy = raw.strategy || 'all';
  const rollout = { strategy };

  if (strategy === 'percentage') {
    const percentage = Number(raw.percentage);
    rollout.percentage = Number.isFinite(percentage)
      ? Math.min(Math.max(percentage, 0), 100)
      : 0;
  }

  if (strategy === 'roles' && Array.isArray(raw.roles)) {
    rollout.roles = raw.roles;
  }

  if (strategy === 'branches' && Array.isArray(raw.branches)) {
    rollout.branches = raw.branches;
  }

  if (raw.segment) {
    rollout.segment = raw.segment;
  }

  return rollout;
};

const createEmptyFlag = (key) => ({
  key,
  description: '',
  enabled: false,
  tags: [],
  owner: null,
  since: null,
  environments: [],
  rollout: normalizeRollout(),
  notes: null,
  defaultEnabled: false,
  sources: {}
});

const applyOverride = (target, override, sourceKey) => {
  if (override == null || typeof override !== 'object') {
    return target;
  }

  if (Object.prototype.hasOwnProperty.call(override, 'description')) {
    target.description = override.description ?? target.description;
  }

  if (Object.prototype.hasOwnProperty.call(override, 'enabled')) {
    target.enabled = Boolean(override.enabled);
  }

  if (Object.prototype.hasOwnProperty.call(override, 'tags')) {
    target.tags = Array.isArray(override.tags) ? override.tags : target.tags;
  }

  if (Object.prototype.hasOwnProperty.call(override, 'owner')) {
    target.owner = override.owner ?? target.owner;
  }

  if (Object.prototype.hasOwnProperty.call(override, 'since')) {
    target.since = override.since ?? target.since;
  }

  if (Object.prototype.hasOwnProperty.call(override, 'environments')) {
    target.environments = Array.isArray(override.environments)
      ? override.environments
      : target.environments;
  }

  if (Object.prototype.hasOwnProperty.call(override, 'notes')) {
    target.notes = override.notes ?? target.notes;
  }

  if (Object.prototype.hasOwnProperty.call(override, 'rollout')) {
    target.rollout = normalizeRollout(override.rollout);
  }

  target.sources = target.sources || {};
  target.sources[sourceKey] = {
    enabled: override.enabled,
    rollout: Object.prototype.hasOwnProperty.call(override, 'rollout')
      ? normalizeRollout(override.rollout)
      : undefined,
    notes: override.notes
  };

  return target;
};

const loadDefaults = () => {
  if (cachedDefaults) {
    return cachedDefaults;
  }

  try {
    if (!fs.existsSync(FLAGS_FILE)) {
      cachedDefaults = {};
      return cachedDefaults;
    }

    const raw = fs.readFileSync(FLAGS_FILE, 'utf8');
    const parsed = JSON.parse(raw);
    const defaults = {};

    Object.entries(parsed).forEach(([key, value]) => {
      const entry = createEmptyFlag(key);
      applyOverride(entry, value, 'default');
      entry.defaultEnabled = entry.enabled;
      defaults[key] = entry;
    });

    cachedDefaults = defaults;
  } catch (error) {
    logger.error('Failed to load default feature flags', { error: error.message });
    cachedDefaults = {};
  }

  return cachedDefaults;
};

const parseEnvironmentOverrides = () => {
  if (cachedEnvOverrides !== undefined) {
    return cachedEnvOverrides;
  }

  const envValue = process.env.FEATURE_FLAGS;
  if (!envValue) {
    cachedEnvOverrides = {};
    return cachedEnvOverrides;
  }

  try {
    const parsed = JSON.parse(envValue);
    const overrides = {};

    Object.entries(parsed).forEach(([key, value]) => {
      if (typeof value === 'boolean') {
        overrides[key] = { enabled: value };
        return;
      }

      if (value && typeof value === 'object') {
        overrides[key] = value;
      }
    });

    cachedEnvOverrides = overrides;
  } catch (error) {
    logger.error('Invalid FEATURE_FLAGS environment override', { error: error.message });
    cachedEnvOverrides = {};
  }

  return cachedEnvOverrides;
};

const getBaseFlags = () => {
  const defaults = loadDefaults();
  const envOverrides = parseEnvironmentOverrides();
  const keys = new Set([
    ...Object.keys(defaults),
    ...Object.keys(envOverrides)
  ]);

  const merged = {};

  keys.forEach((key) => {
    const base = defaults[key]
      ? { ...defaults[key], sources: { ...defaults[key].sources } }
      : createEmptyFlag(key);

    if (envOverrides[key]) {
      applyOverride(base, envOverrides[key], 'environment');
    }

    merged[key] = base;
  });

  return merged;
};

const refresh = () => {
  cachedDefaults = null;
  cachedEnvOverrides = undefined;
  return getBaseFlags();
};

module.exports = {
  FLAGS_FILE,
  getBaseFlags,
  loadDefaults,
  parseEnvironmentOverrides,
  refresh
};
