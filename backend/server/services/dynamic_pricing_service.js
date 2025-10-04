const { v4: uuid } = require('uuid');
const config = require('../../config/config');
const dynamicPricingConfig = require('../../config/dynamicPricing');
const redisManager = require('../../config/redis');
const { logger } = require('../../config/logger');

const GLOBAL_SCOPE = 'global';
const DEFAULT_CHANNEL = 'pos';

const namespace = config.dynamicPricing?.namespace || 'dynamic-pricing';
const ttlSeconds = config.dynamicPricing?.cacheTtlSeconds || 30;

const toDateOrNull = (value) => {
  if (!value) return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
};

const cloneAdjustment = (adjustment) => ({
  id: adjustment.id,
  name: adjustment.name,
  description: adjustment.description || '',
  type: adjustment.type || 'percentage',
  value: typeof adjustment.value === 'number' ? adjustment.value : null,
  fixedPrice: typeof adjustment.fixedPrice === 'number' ? adjustment.fixedPrice : null,
  productIds: Array.isArray(adjustment.productIds) ? [...adjustment.productIds] : [],
  categoryIds: Array.isArray(adjustment.categoryIds) ? [...adjustment.categoryIds] : [],
  branchIds: Array.isArray(adjustment.branchIds) ? [...adjustment.branchIds] : [],
  channels: Array.isArray(adjustment.channels) ? [...adjustment.channels] : [DEFAULT_CHANNEL],
  tenantId: adjustment.tenantId || null,
  priority: Number.isFinite(adjustment.priority) ? adjustment.priority : 100,
  stackable: typeof adjustment.stackable === 'boolean' ? adjustment.stackable : false,
  startAt: toDateOrNull(adjustment.startAt)?.toISOString() || null,
  endAt: toDateOrNull(adjustment.endAt)?.toISOString() || null,
  status: adjustment.status || inferStatus(adjustment),
  createdAt: adjustment.createdAt || new Date().toISOString(),
  createdBy: adjustment.createdBy || null,
  updatedAt: adjustment.updatedAt || adjustment.createdAt || new Date().toISOString(),
  updatedBy: adjustment.updatedBy || adjustment.createdBy || null
});

function inferStatus(adjustment) {
  const now = Date.now();
  const start = toDateOrNull(adjustment.startAt);
  const end = toDateOrNull(adjustment.endAt);

  if (end && end.getTime() < now) return 'expired';
  if (start && start.getTime() > now) return 'scheduled';
  return 'active';
}

const getCacheKey = (tenantId = GLOBAL_SCOPE) => {
  const scope = tenantId || GLOBAL_SCOPE;
  return `${namespace}:${scope}`;
};

const fetchOverrides = async (tenantId = GLOBAL_SCOPE) => {
  try {
    const stored = await redisManager.get(getCacheKey(tenantId));
    if (!stored || !Array.isArray(stored.adjustments)) {
      return { adjustments: [] };
    }
    return {
      adjustments: stored.adjustments.map(cloneAdjustment)
    };
  } catch (error) {
    logger.warn('Failed to load dynamic pricing overrides from Redis', {
      tenantId,
      error: error.message
    });
    return { adjustments: [] };
  }
};

const persistOverrides = async (tenantId, overrides) => {
  const payload = {
    adjustments: overrides.adjustments.map(cloneAdjustment)
  };
  await redisManager.set(getCacheKey(tenantId), payload, ttlSeconds);
};

const isAdjustmentActive = (adjustment, { now = new Date(), channel = DEFAULT_CHANNEL, branchId = null }) => {
  if (!adjustment.channels.includes(channel)) {
    return false;
  }

  if (adjustment.branchIds.length > 0 && branchId && !adjustment.branchIds.includes(branchId)) {
    return false;
  }

  const start = adjustment.startAt ? new Date(adjustment.startAt) : null;
  const end = adjustment.endAt ? new Date(adjustment.endAt) : null;

  if (start && start > now) {
    return false;
  }

  if (end && end < now) {
    return false;
  }

  return adjustment.status !== 'disabled' && adjustment.status !== 'archived';
};

const applyAdjustment = (adjustment, basePrice) => {
  if (adjustment.type === 'availability') {
    return { price: basePrice, available: false };
  }

  if (adjustment.type === 'fixed' && typeof adjustment.fixedPrice === 'number') {
    return { price: adjustment.fixedPrice, available: true };
  }

  if (adjustment.type === 'percentage' && typeof adjustment.value === 'number') {
    const delta = basePrice * (adjustment.value / 100);
    const computed = Math.max(basePrice - delta, 0);
    return { price: Number(computed.toFixed(2)), available: true };
  }

  return { price: basePrice, available: true };
};

const sortAdjustments = (a, b) => {
  if (a.priority === b.priority) {
    return new Date(b.startAt || 0) - new Date(a.startAt || 0);
  }
  return a.priority - b.priority;
};

const selectEligibleAdjustments = (adjustments, { productId, branchId, channel, now }) => {
  return adjustments
    .filter((adjustment) => {
      if (adjustment.productIds.length > 0 && !adjustment.productIds.includes(productId)) {
        return false;
      }
      return true;
    })
    .filter((adjustment) => isAdjustmentActive(adjustment, { branchId, channel, now }))
    .sort(sortAdjustments);
};

const mergeAdjustments = (base, overrides) => {
  const map = new Map();
  base.forEach((adj) => map.set(adj.id, cloneAdjustment(adj)));
  overrides.forEach((adj) => map.set(adj.id, cloneAdjustment(adj)));
  return Array.from(map.values()).sort(sortAdjustments);
};

module.exports = {
  async listAdjustments({ tenantId = GLOBAL_SCOPE, branchId = null, includeExpired = false } = {}) {
    const baseAdjustments = dynamicPricingConfig.getBaseAdjustments();
    const overrides = await fetchOverrides(tenantId);
    let combined = mergeAdjustments(baseAdjustments, overrides.adjustments);

    if (!includeExpired) {
      const now = new Date();
      combined = combined.filter((adjustment) => {
        if (!adjustment.endAt) return true;
        return new Date(adjustment.endAt) >= now;
      });
    }

    combined = combined.filter((adjustment) => adjustment.status !== 'archived');

    if (branchId) {
      combined = combined.filter((adjustment) => {
        return adjustment.branchIds.length === 0 || adjustment.branchIds.includes(branchId);
      });
    }

    return combined;
  },

  async upsertAdjustment({ tenantId = GLOBAL_SCOPE, payload, actor }) {
    const overrides = await fetchOverrides(tenantId);
    const now = new Date().toISOString();
    let existingIndex = -1;

    if (payload.id) {
      existingIndex = overrides.adjustments.findIndex((item) => item.id === payload.id);
    }

    if (existingIndex >= 0) {
      const updated = {
        ...overrides.adjustments[existingIndex],
        ...payload,
        updatedAt: now,
        updatedBy: actor?.id || null
      };
      overrides.adjustments[existingIndex] = cloneAdjustment(updated);
    } else {
      const id = payload.id || uuid();
      const adjustment = cloneAdjustment({
        ...payload,
        id,
        createdAt: now,
        createdBy: actor?.id || null,
        updatedAt: now,
        updatedBy: actor?.id || null
      });
      overrides.adjustments.push(adjustment);
    }

    overrides.adjustments.sort(sortAdjustments);
    await persistOverrides(tenantId, overrides);

    return overrides.adjustments;
  },

  async archiveAdjustment({ tenantId = GLOBAL_SCOPE, adjustmentId, actor }) {
    const overrides = await fetchOverrides(tenantId);
    const index = overrides.adjustments.findIndex((item) => item.id === adjustmentId);
    if (index === -1) {
      return overrides.adjustments;
    }

    overrides.adjustments[index] = {
      ...overrides.adjustments[index],
      status: 'archived',
      updatedAt: new Date().toISOString(),
      updatedBy: actor?.id || null
    };

    await persistOverrides(tenantId, overrides);
    return overrides.adjustments;
  },

  async evaluatePrice({
    tenantId = GLOBAL_SCOPE,
    productId,
    basePrice,
    branchId = null,
    channel = DEFAULT_CHANNEL,
    now = new Date()
  }) {
    const adjustments = await this.listAdjustments({ tenantId, branchId, includeExpired: false });
    const eligible = selectEligibleAdjustments(adjustments, { productId, branchId, channel, now });

    if (eligible.length === 0) {
      return { price: basePrice, applied: [] };
    }

    let price = basePrice;
    const applied = [];

    for (const adjustment of eligible) {
      const { price: adjustedPrice, available } = applyAdjustment(adjustment, price);
      if (!available) {
        return { price: 0, applied: [adjustment], available: false };
      }

      if (adjustment.stackable || applied.length === 0) {
        price = adjustedPrice;
        applied.push(adjustment);
      }

      if (!adjustment.stackable) {
        break;
      }
    }

    return { price: Number(price.toFixed(2)), applied, available: true };
  }
};
