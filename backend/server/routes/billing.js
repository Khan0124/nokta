const express = require('express');
const { authenticateToken, requireRole, validateTenant } = require('../../middleware/auth');
const { requireFeatureFlag } = require('../../middleware/featureFlag');
const { validate, schemas } = require('../../middleware/validation');
const { asyncHandler } = require('../../middleware/errorHandler');
const {
  listPlans,
  upsertSubscription,
  updateSubscription,
  issueInvoice,
  recordPayment,
  getSubscriptionSummary,
  listInvoicesForSubscription,
  handleGatewayWebhook
} = require('../services/billing_service');

const router = express.Router();

router.post(
  '/gateways/webhook',
  validate(schemas.billing.webhook),
  asyncHandler(async (req, res) => {
    await handleGatewayWebhook(req.body);
    res.status(202).json({ status: 'accepted' });
  })
);

router.use(authenticateToken);
router.use(requireFeatureFlag('billing.saas', { statusCode: 404 }));
router.use(requireRole('admin', 'manager'));
router.use(validateTenant);

router.get(
  '/plans',
  asyncHandler(async (req, res) => {
    const plans = await listPlans();
    res.json({
      plans,
      generatedAt: new Date().toISOString()
    });
  })
);

router.get(
  '/subscriptions/current',
  asyncHandler(async (req, res) => {
    const tenantId = req.tenant?.id || req.user?.tenantId;
    const subscription = await getSubscriptionSummary({ tenantId });

    res.json({
      subscription,
      generatedAt: new Date().toISOString()
    });
  })
);

router.post(
  '/subscriptions',
  validate(schemas.billing.createSubscription),
  asyncHandler(async (req, res) => {
    const tenantId = req.tenant?.id || req.user?.tenantId;
    const subscription = await upsertSubscription({
      tenantId,
      payload: req.body,
      actorId: req.user?.id
    });

    res.status(201).json({ subscription });
  })
);

router.patch(
  '/subscriptions/:subscriptionId',
  validate(schemas.billing.updateSubscription),
  asyncHandler(async (req, res) => {
    const tenantId = req.tenant?.id || req.user?.tenantId;
    const subscription = await updateSubscription({
      tenantId,
      subscriptionId: req.params.subscriptionId,
      payload: req.body,
      actorId: req.user?.id
    });

    res.json({ subscription });
  })
);

router.get(
  '/subscriptions/:subscriptionId/invoices',
  asyncHandler(async (req, res) => {
    const tenantId = req.tenant?.id || req.user?.tenantId;
    const invoices = await listInvoicesForSubscription({
      tenantId,
      subscriptionId: req.params.subscriptionId
    });

    res.json({
      invoices,
      generatedAt: new Date().toISOString()
    });
  })
);

router.post(
  '/subscriptions/:subscriptionId/invoices',
  validate(schemas.billing.invoiceGenerate),
  asyncHandler(async (req, res) => {
    const tenantId = req.tenant?.id || req.user?.tenantId;
    const result = await issueInvoice({
      tenantId,
      subscriptionId: req.params.subscriptionId,
      payload: req.body,
      actorId: req.user?.id
    });

    res.status(201).json(result);
  })
);

router.post(
  '/subscriptions/:subscriptionId/invoices/:invoiceId/payments',
  validate(schemas.billing.recordPayment),
  asyncHandler(async (req, res) => {
    const tenantId = req.tenant?.id || req.user?.tenantId;
    const result = await recordPayment({
      tenantId,
      subscriptionId: req.params.subscriptionId,
      invoiceId: req.params.invoiceId,
      payload: { ...req.body, actorId: req.user?.id }
    });

    res.status(201).json(result);
  })
);

module.exports = router;
