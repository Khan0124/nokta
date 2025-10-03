const { logger } = require('../config/logger');
const { evaluateFlag } = require('../server/services/feature_flag_service');

const requireFeatureFlag = (flagKey, options = {}) => {
  const {
    scope = 'tenant',
    statusCode = 404,
    message = 'Feature not available',
    log = true
  } = options;

  return async (req, res, next) => {
    try {
      const tenantId = scope === 'global'
        ? null
        : options.tenantId
          ?? req.tenant?.id
          ?? req.user?.tenantId
          ?? req.headers['x-tenant-id'];

      const context = {
        tenantId,
        branchId: options.branchId
          ?? req.branch?.id
          ?? req.headers['x-branch-id']
          ?? req.user?.branchId,
        role: options.role ?? req.user?.role,
        userId: options.userId ?? req.user?.id,
        sessionId: req.headers['x-session-id']
      };

      const enabled = await evaluateFlag(flagKey, context);

      if (!enabled) {
        if (log) {
          logger.warn('Feature gate blocked request', {
            feature: flagKey,
            scope,
            tenantId,
            userId: req.user?.id,
            path: req.originalUrl
          });
        }

        return res.status(statusCode).json({
          error: message,
          code: 'FEATURE_DISABLED',
          feature: flagKey
        });
      }

      return next();
    } catch (error) {
      logger.error('Failed to evaluate feature flag', {
        feature: flagKey,
        error: error.message
      });
      return next(error);
    }
  };
};

module.exports = {
  requireFeatureFlag
};
