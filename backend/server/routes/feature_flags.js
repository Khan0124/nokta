const express = require('express');
const { authenticateToken, requireRole } = require('../../middleware/auth');
const { validate, schemas } = require('../../middleware/validation');
const { asyncHandler } = require('../../middleware/errorHandler');
const {
  listFlags,
  getFlag,
  updateFlag,
  removeOverride
} = require('../services/feature_flag_service');

const router = express.Router();
const adminOnly = requireRole('admin');

const resolveTenantId = (value) => {
  if (value === undefined || value === null || value === '') {
    return undefined;
  }
  const parsed = Number(value);
  return Number.isNaN(parsed) ? undefined : parsed;
};

router.use(authenticateToken);

router.get(
  '/',
  validate(schemas.featureFlags.list, 'query'),
  asyncHandler(async (req, res) => {
    const {
      scope,
      tenantId: queryTenantId,
      includeMetadata,
      branchId,
      role,
      userId
    } = req.query;

    const effectiveScope = scope || 'tenant';
    const isGlobal = effectiveScope === 'global';
    const isAdmin = req.user?.role === 'admin';
    let tenantId = resolveTenantId(queryTenantId);

    if (isGlobal && !isAdmin) {
      return res.status(403).json({
        error: 'Global feature flag scope requires administrator role',
        code: 'FEATURE_FLAG_SCOPE_FORBIDDEN'
      });
    }

    if (!isGlobal) {
      if (!tenantId) {
        tenantId = resolveTenantId(req.user?.tenantId);
      }

      if (!tenantId) {
        return res.status(400).json({
          error: 'Tenant ID required for tenant scope',
          code: 'TENANT_ID_MISSING'
        });
      }

      if (
        queryTenantId &&
        !isAdmin &&
        resolveTenantId(queryTenantId) !== resolveTenantId(req.user?.tenantId)
      ) {
        return res.status(403).json({
          error: 'Access to other tenant feature flags is not allowed',
          code: 'FEATURE_FLAG_SCOPE_FORBIDDEN'
        });
      }
    } else {
      tenantId = undefined;
    }

    const evaluationContext = {
      tenantId: tenantId ?? resolveTenantId(req.user?.tenantId),
      branchId: branchId ?? req.headers['x-branch-id'] ?? req.user?.branchId,
      role: role ?? req.user?.role,
      userId: userId ?? req.user?.id,
      sessionId: req.headers['x-session-id']
    };

    const flags = await listFlags({
      tenantId,
      includeMetadata,
      context: evaluationContext
    });

    res.json({
      data: flags,
      scope: effectiveScope,
      tenantId: tenantId ?? null,
      generatedAt: new Date().toISOString()
    });
  })
);

router.get(
  '/:flagKey',
  validate(schemas.featureFlags.scope, 'query'),
  asyncHandler(async (req, res) => {
    const { scope, tenantId: queryTenantId } = req.query;
    const effectiveScope = scope || 'tenant';
    const isGlobal = effectiveScope === 'global';

    let tenantId = resolveTenantId(queryTenantId);
    if (!isGlobal) {
      tenantId = tenantId ?? resolveTenantId(req.user?.tenantId);
      if (!tenantId) {
        return res.status(400).json({
          error: 'Tenant ID required for tenant scope',
          code: 'TENANT_ID_MISSING'
        });
      }
    } else if (req.user?.role !== 'admin') {
      return res.status(403).json({
        error: 'Global feature flag scope requires administrator role',
        code: 'FEATURE_FLAG_SCOPE_FORBIDDEN'
      });
    }

    const flag = await getFlag(req.params.flagKey, { tenantId });

    if (!flag) {
      return res.status(404).json({
        error: 'Feature flag not found',
        code: 'FEATURE_FLAG_NOT_FOUND'
      });
    }

    res.json({
      data: flag,
      scope: effectiveScope,
      tenantId: tenantId ?? null
    });
  })
);

router.put(
  '/:flagKey',
  adminOnly,
  validate(schemas.featureFlags.scope, 'query'),
  validate(schemas.featureFlags.update, 'body'),
  asyncHandler(async (req, res) => {
    const { scope, tenantId: queryTenantId } = req.query;
    const effectiveScope = scope || 'tenant';
    let tenantId = resolveTenantId(queryTenantId);

    if (effectiveScope !== 'global') {
      tenantId = tenantId ?? resolveTenantId(req.user?.tenantId);
      if (!tenantId) {
        return res.status(400).json({
          error: 'Tenant ID required for tenant scope updates',
          code: 'TENANT_ID_MISSING'
        });
      }
    }

    const flag = await updateFlag(
      req.params.flagKey,
      req.body,
      {
        tenantId,
        actor: req.user,
        scope: effectiveScope
      }
    );

    res.json({
      data: flag,
      scope: effectiveScope,
      tenantId: tenantId ?? null,
      updatedAt: new Date().toISOString()
    });
  })
);

router.delete(
  '/:flagKey',
  adminOnly,
  validate(schemas.featureFlags.scope, 'query'),
  asyncHandler(async (req, res) => {
    const { scope, tenantId: queryTenantId } = req.query;
    const effectiveScope = scope || 'tenant';
    let tenantId = resolveTenantId(queryTenantId);

    if (effectiveScope !== 'global') {
      tenantId = tenantId ?? resolveTenantId(req.user?.tenantId);
      if (!tenantId) {
        return res.status(400).json({
          error: 'Tenant ID required for tenant scope updates',
          code: 'TENANT_ID_MISSING'
        });
      }
    }

    await removeOverride(req.params.flagKey, {
      tenantId,
      scope: effectiveScope
    });

    res.status(204).send();
  })
);

module.exports = router;
