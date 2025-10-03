const express = require('express');
const {
  authenticateToken,
  requireRole,
  validateTenant
} = require('../../middleware/auth');
const { validate, schemas } = require('../../middleware/validation');
const { asyncHandler } = require('../../middleware/errorHandler');
const {
  startOnboarding,
  getOnboardingSession,
  submitOnboardingStep,
  completeOnboarding,
  SESSION_DURATION_MINUTES
} = require('../services/tenant_onboarding_service');

const router = express.Router();

router.post(
  '/onboarding/start',
  validate(schemas.tenant.onboardingStart),
  asyncHandler(async (req, res) => {
    const session = await startOnboarding({
      ...req.body,
      ipAddress: req.ip
    });

    res.status(201).json({
      session,
      expiresInMinutes: SESSION_DURATION_MINUTES
    });
  })
);

router.get(
  '/onboarding/:token',
  validate(schemas.tenant.onboardingToken, 'params'),
  asyncHandler(async (req, res) => {
    const session = await getOnboardingSession(req.params.token);
    res.json({
      session,
      expiresInMinutes: SESSION_DURATION_MINUTES
    });
  })
);

router.post(
  '/onboarding/:token/steps',
  validate(schemas.tenant.onboardingToken, 'params'),
  validate(schemas.tenant.onboardingStepSubmission),
  asyncHandler(async (req, res) => {
    const session = await submitOnboardingStep({
      token: req.params.token,
      stepKey: req.body.stepKey,
      payload: req.body.payload,
      status: req.body.status
    });

    res.json({ session });
  })
);

router.post(
  '/onboarding/:token/complete',
  validate(schemas.tenant.onboardingToken, 'params'),
  validate(schemas.tenant.onboardingCompletion),
  asyncHandler(async (req, res) => {
    const session = await completeOnboarding({
      token: req.params.token,
      acceptTerms: req.body.acceptTerms,
      billingCycleOverride: req.body.billingCycle
    });

    res.status(202).json({
      message: 'Tenant onboarding completed',
      session
    });
  })
);

router.use(authenticateToken);
router.use(requireRole('admin', 'manager'));
router.use(validateTenant);

router.get(
  '/',
  asyncHandler(async (req, res) => {
    res.json({
      message: 'Tenant management endpoints will be delivered in a future iteration.'
    });
  })
);

module.exports = router;
