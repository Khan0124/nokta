const fs = require('fs');
const path = require('path');
const { logger } = require('./logger');

const CONFIG_PATH = path.join(__dirname, 'dynamic_pricing.json');

let cachedConfig = null;
let lastLoaded = 0;
const CACHE_TTL_MS = 30 * 1000;

const loadConfig = () => {
  const now = Date.now();
  if (cachedConfig && now - lastLoaded < CACHE_TTL_MS) {
    return cachedConfig;
  }

  try {
    const raw = fs.readFileSync(CONFIG_PATH, 'utf-8');
    const parsed = JSON.parse(raw);

    if (!Array.isArray(parsed.adjustments)) {
      throw new Error('dynamic_pricing.json missing adjustments array');
    }

    cachedConfig = parsed;
    lastLoaded = now;
    return cachedConfig;
  } catch (error) {
    logger.warn('Failed to load dynamic pricing seed config, using empty defaults', {
      error: error.message,
      path: CONFIG_PATH
    });
    cachedConfig = { adjustments: [], availability: [] };
    lastLoaded = now;
    return cachedConfig;
  }
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
  channels: Array.isArray(adjustment.channels) ? [...adjustment.channels] : ['pos'],
  tenantId: adjustment.tenantId || null,
  priority: Number.isFinite(adjustment.priority) ? adjustment.priority : 100,
  startAt: adjustment.startAt || null,
  endAt: adjustment.endAt || null,
  stackable: typeof adjustment.stackable === 'boolean' ? adjustment.stackable : false
});

module.exports = {
  getBaseAdjustments() {
    const config = loadConfig();
    return config.adjustments.map(cloneAdjustment);
  },

  getBaseAvailability() {
    const config = loadConfig();
    return Array.isArray(config.availability) ? [...config.availability] : [];
  },

  clearCache() {
    cachedConfig = null;
    lastLoaded = 0;
  }
};
