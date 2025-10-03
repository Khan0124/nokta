const express = require('express');
const dynamicPricingService = require('../services/dynamic_pricing_service');
const { authenticateToken, requireRole, validateTenant } = require('../../middleware/auth');
const { requireFeatureFlag } = require('../../middleware/featureFlag');
const { validate, schemas } = require('../../middleware/validation');
const { asyncHandler } = require('../../middleware/errorHandler');

const router = express.Router();

router.use(authenticateToken);
router.use(validateTenant);
router.use(requireFeatureFlag('platform.dynamicPricing'));

router.get(
  '/',
  requireRole(['admin', 'manager']),
  validate(schemas.dynamicPricing.list, 'query'),
  asyncHandler(async (req, res) => {
    const tenantId = req.tenant?.id || req.user?.tenantId;
    const { includeExpired, branchId } = req.query;
    const adjustments = await dynamicPricingService.listAdjustments({
      tenantId,
      branchId,
      includeExpired
    });

    res.json({ adjustments });
  })
);

router.post(
  '/',
  requireRole(['admin', 'manager']),
  validate(schemas.dynamicPricing.create, 'body'),
  asyncHandler(async (req, res) => {
    const tenantId = req.tenant?.id || req.user?.tenantId;
    const actor = { id: req.user?.id, name: req.user?.fullName };
    const adjustments = await dynamicPricingService.upsertAdjustment({
      tenantId,
      payload: req.body,
      actor
    });

    res.status(201).json({ adjustments });
  })
);

router.put(
  '/:adjustmentId',
  requireRole(['admin', 'manager']),
  validate(schemas.dynamicPricing.update, 'body'),
  asyncHandler(async (req, res) => {
    const tenantId = req.tenant?.id || req.user?.tenantId;
    const actor = { id: req.user?.id, name: req.user?.fullName };
    const payload = { ...req.body, id: req.params.adjustmentId };
    const adjustments = await dynamicPricingService.upsertAdjustment({
      tenantId,
      payload,
      actor
    });

    res.json({ adjustments });
  })
);

router.delete(
  '/:adjustmentId',
  requireRole(['admin', 'manager']),
  asyncHandler(async (req, res) => {
    const tenantId = req.tenant?.id || req.user?.tenantId;
    const actor = { id: req.user?.id, name: req.user?.fullName };
    const adjustments = await dynamicPricingService.archiveAdjustment({
      tenantId,
      adjustmentId: req.params.adjustmentId,
      actor
    });

    res.status(202).json({ adjustments });
  })
);

router.post(
  '/evaluate',
  requireRole(['admin', 'manager', 'cashier']),
  validate(schemas.dynamicPricing.evaluate, 'body'),
  asyncHandler(async (req, res) => {
    const tenantId = req.tenant?.id || req.user?.tenantId;
    const result = await dynamicPricingService.evaluatePrice({
      tenantId,
      productId: req.body.productId,
      basePrice: req.body.basePrice,
      branchId: req.body.branchId,
      channel: req.body.channel,
      now: req.body.now ? new Date(req.body.now) : new Date()
    });

    res.json(result);
  })
);

module.exports = router;
