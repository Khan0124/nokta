const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcryptjs');
const moment = require('moment');
const databaseManager = require('../../config/database');
const { logger, auditLogger } = require('../../config/logger');
const {
  AppError,
  NotFoundError,
  ConflictError
} = require('../../middleware/errorHandler');

const SESSION_DURATION_MINUTES = 30;

const STEP_DEFINITIONS = [
  { key: 'company_profile', order: 1, required: true },
  { key: 'branch_setup', order: 2, required: true },
  { key: 'owner_account', order: 3, required: true },
  { key: 'billing_preferences', order: 4, required: false }
];

const STEP_LOOKUP = new Map(STEP_DEFINITIONS.map((definition) => [definition.key, definition]));

const toIsoString = (value) => {
  if (!value) {
    return null;
  }

  return value instanceof Date ? value.toISOString() : value;
};

const parseJsonColumn = (value) => {
  if (!value) {
    return {};
  }

  if (typeof value === 'object') {
    return value || {};
  }

  try {
    return JSON.parse(value);
  } catch (error) {
    logger.warn('Failed to parse JSON column during onboarding', {
      error: error.message
    });
    return {};
  }
};

const pick = (source, fields) => {
  if (!source) {
    return {};
  }

  return fields.reduce((acc, field) => {
    if (Object.prototype.hasOwnProperty.call(source, field) && source[field] !== undefined) {
      acc[field] = source[field];
    }

    return acc;
  }, {});
};

const sanitizeStepPayload = (stepKey, payload = {}) => {
  switch (stepKey) {
    case 'company_profile':
      return pick(payload, [
        'legalName',
        'tradeName',
        'domain',
        'industry',
        'country',
        'city',
        'address',
        'timezone',
        'currency',
        'employeesCount',
        'posDevices',
        'goLiveDate',
        'logo'
      ]);
    case 'branch_setup':
      return pick(payload, [
        'branchName',
        'branchCode',
        'branchAddress',
        'branchPhone',
        'branchEmail',
        'latitude',
        'longitude',
        'openingTime',
        'closingTime',
        'deliveryRadiusKm',
        'allowPickup'
      ]);
    case 'owner_account':
      return pick(payload, [
        'fullName',
        'email',
        'phone',
        'username',
        'password',
        'preferredLanguage'
      ]);
    case 'billing_preferences':
      return pick(payload, [
        'billingCycle',
        'paymentMethod',
        'taxId',
        'needInvoice',
        'financeContactName',
        'financeContactEmail'
      ]);
    default:
      return payload;
  }
};

const decorateStep = (row) => ({
  id: row.id,
  key: row.step_key,
  status: row.status,
  displayOrder: row.display_order,
  payload: parseJsonColumn(row.payload),
  completedAt: toIsoString(row.completed_at),
  lastError: row.last_error,
  createdAt: toIsoString(row.created_at),
  updatedAt: toIsoString(row.updated_at)
});

const computeProgress = (stepRows) => {
  const requiredSteps = stepRows.filter((row) => STEP_LOOKUP.get(row.key)?.required);
  const completedSteps = requiredSteps.filter((row) => row.status === 'completed');

  const total = requiredSteps.length;
  const completed = completedSteps.length;
  const percentage = total === 0 ? 0 : Math.round((completed / total) * 100);

  return {
    total,
    completed,
    percentage
  };
};

const determineNextStep = (stepRows) => {
  const ordered = [...stepRows].sort((a, b) => a.displayOrder - b.displayOrder);
  const pending = ordered.find((row) => !['completed', 'skipped'].includes(row.status));
  return pending ? pending.key : null;
};

const computeSessionStatus = (stepRows, currentStatus) => {
  if (currentStatus === 'completed') {
    return 'completed';
  }

  const progress = computeProgress(stepRows);
  return progress.completed === progress.total ? 'ready' : 'in_progress';
};

const decorateSession = (sessionRow, stepRows) => {
  const steps = stepRows.map(decorateStep).sort((a, b) => a.displayOrder - b.displayOrder);
  const progress = computeProgress(steps);

  return {
    id: sessionRow.id,
    token: sessionRow.token,
    tenantId: sessionRow.tenant_id,
    companyName: sessionRow.company_name,
    contactName: sessionRow.contact_name,
    contactEmail: sessionRow.contact_email,
    contactPhone: sessionRow.contact_phone,
    preferredLanguage: sessionRow.preferred_language,
    subscriptionPlan: sessionRow.subscription_plan,
    status: sessionRow.status,
    currentStep: sessionRow.current_step,
    expiresAt: toIsoString(sessionRow.expires_at),
    metadata: parseJsonColumn(sessionRow.metadata),
    completedAt: toIsoString(sessionRow.completed_at),
    createdAt: toIsoString(sessionRow.created_at),
    updatedAt: toIsoString(sessionRow.updated_at),
    steps,
    progress
  };
};

const fetchSession = async ({ token, connection, forUpdate = false }) => {
  const sql = `SELECT * FROM tenant_onboarding_sessions WHERE token = ? LIMIT 1${forUpdate ? ' FOR UPDATE' : ''}`;
  const [rows] = await connection.query(sql, [token]);
  return rows && rows.length > 0 ? rows[0] : null;
};

const fetchSteps = async ({ sessionId, connection }) => {
  const [rows] = await connection.query(
    `SELECT id, session_id, step_key, status, display_order, payload, completed_at, last_error, created_at, updated_at
     FROM tenant_onboarding_steps
     WHERE session_id = ?
     ORDER BY display_order ASC`,
    [sessionId]
  );

  return rows || [];
};

const expireSessionIfNeeded = async (sessionRow, connection) => {
  if (!sessionRow) {
    return sessionRow;
  }

  const terminalStates = ['completed', 'cancelled', 'expired'];
  if (terminalStates.includes(sessionRow.status)) {
    return sessionRow;
  }

  const expiresAt = new Date(sessionRow.expires_at);
  if (Number.isNaN(expiresAt.getTime())) {
    return sessionRow;
  }

  if (expiresAt.getTime() < Date.now()) {
    await connection.execute(
      `UPDATE tenant_onboarding_sessions
       SET status = 'expired', updated_at = CURRENT_TIMESTAMP
       WHERE id = ?`,
      [sessionRow.id]
    );

    sessionRow.status = 'expired';
  }

  return sessionRow;
};

const startOnboarding = async (payload) => {
  const token = uuidv4();
  const expiresAt = moment.utc().add(SESSION_DURATION_MINUTES, 'minutes').toDate();
  const metadata = {
    source: payload.source || 'self_service',
    estimatedPosDevices: payload.estimatedPosDevices || null,
    notes: payload.notes || null
  };

  return databaseManager.transaction(async (connection) => {
    const [insertResult] = await connection.execute(
      `INSERT INTO tenant_onboarding_sessions
         (token, company_name, contact_name, contact_email, contact_phone, preferred_language, subscription_plan, status, current_step, expires_at, metadata)
       VALUES (?, ?, ?, ?, ?, ?, ?, 'in_progress', ?, ?, ?)` ,
      [
        token,
        payload.companyName,
        payload.contactName,
        payload.contactEmail,
        payload.contactPhone,
        payload.preferredLanguage || 'ar',
        payload.subscriptionPlan || 'basic',
        'company_profile',
        expiresAt,
        JSON.stringify(metadata)
      ]
    );

    const sessionId = insertResult.insertId;

    for (const definition of STEP_DEFINITIONS) {
      await connection.execute(
        `INSERT INTO tenant_onboarding_steps (session_id, step_key, status, display_order)
         VALUES (?, ?, 'pending', ?)` ,
        [sessionId, definition.key, definition.order]
      );
    }

    await connection.execute(
      `INSERT INTO tenant_onboarding_events (session_id, event_type, actor_type, actor_identifier, details)
       VALUES (?, 'session_started', 'system', 'onboarding', ?)` ,
      [sessionId, JSON.stringify({ subscriptionPlan: payload.subscriptionPlan || 'basic' })]
    );

    const steps = await fetchSteps({ sessionId, connection });
    const sessionRow = await fetchSession({ token, connection });

    auditLogger.info('tenant_onboarding_started', {
      token,
      companyName: payload.companyName,
      contactEmail: payload.contactEmail,
      subscriptionPlan: payload.subscriptionPlan || 'basic'
    });

    return decorateSession(sessionRow, steps);
  });
};

const getOnboardingSession = async (token) => {
  return databaseManager.transaction(async (connection) => {
    const sessionRow = await fetchSession({ token, connection, forUpdate: true });

    if (!sessionRow) {
      throw new NotFoundError('Onboarding session');
    }

    await expireSessionIfNeeded(sessionRow, connection);

    const stepRows = await fetchSteps({ sessionId: sessionRow.id, connection });
    return decorateSession(sessionRow, stepRows);
  });
};

const submitOnboardingStep = async ({ token, stepKey, payload, status = 'completed' }) => {
  if (!STEP_LOOKUP.has(stepKey)) {
    throw new NotFoundError('Onboarding step');
  }

  return databaseManager.transaction(async (connection) => {
    const sessionRow = await fetchSession({ token, connection, forUpdate: true });

    if (!sessionRow) {
      throw new NotFoundError('Onboarding session');
    }

    await expireSessionIfNeeded(sessionRow, connection);

    if (sessionRow.status === 'expired') {
      throw new AppError('Onboarding session has expired', 410, 'ONBOARDING_EXPIRED');
    }

    if (['completed', 'cancelled'].includes(sessionRow.status)) {
      throw new ConflictError('Onboarding session is already finalized');
    }

    const [stepResult] = await connection.query(
      `SELECT * FROM tenant_onboarding_steps WHERE session_id = ? AND step_key = ? LIMIT 1 FOR UPDATE`,
      [sessionRow.id, stepKey]
    );

    if (!stepResult || stepResult.length === 0) {
      throw new NotFoundError('Onboarding step');
    }

    const stepRow = stepResult[0];
    const sanitizedPayload = sanitizeStepPayload(stepKey, payload);
    const payloadToPersist = { ...sanitizedPayload };

    if (stepKey === 'owner_account' && sanitizedPayload.password) {
      payloadToPersist.passwordHash = await bcrypt.hash(sanitizedPayload.password, 12);
      delete payloadToPersist.password;
    }

    await connection.execute(
      `UPDATE tenant_onboarding_steps
         SET status = ?, payload = ?, completed_at = ?, last_error = NULL, updated_at = CURRENT_TIMESTAMP
       WHERE id = ?`,
      [
        status,
        Object.keys(payloadToPersist).length > 0 ? JSON.stringify(payloadToPersist) : null,
        status === 'completed' ? new Date() : null,
        stepRow.id
      ]
    );

    await connection.execute(
      `INSERT INTO tenant_onboarding_events (session_id, event_type, actor_type, actor_identifier, details)
       VALUES (?, 'step_updated', 'applicant', ?, ?)` ,
      [sessionRow.id, stepKey, JSON.stringify({ status })]
    );

    const stepRows = await fetchSteps({ sessionId: sessionRow.id, connection });
    const nextStep = determineNextStep(stepRows.map(decorateStep));
    const nextStatus = computeSessionStatus(stepRows.map(decorateStep), sessionRow.status);

    await connection.execute(
      `UPDATE tenant_onboarding_sessions
         SET status = ?, current_step = ?, updated_at = CURRENT_TIMESTAMP
       WHERE id = ?`,
      [nextStatus, nextStep, sessionRow.id]
    );

    const updatedSession = await fetchSession({ token, connection });
    return decorateSession(updatedSession, stepRows);
  });
};

const completeOnboarding = async ({ token, acceptTerms, billingCycleOverride }) => {
  if (!acceptTerms) {
    throw new AppError('Terms must be accepted before completing onboarding', 400, 'ONBOARDING_TERMS_REQUIRED');
  }

  const completionResult = await databaseManager.transaction(async (connection) => {
    const sessionRow = await fetchSession({ token, connection, forUpdate: true });

    if (!sessionRow) {
      throw new NotFoundError('Onboarding session');
    }

    await expireSessionIfNeeded(sessionRow, connection);

    if (sessionRow.status === 'expired') {
      throw new AppError('Onboarding session has expired', 410, 'ONBOARDING_EXPIRED');
    }

    if (sessionRow.status === 'completed') {
      throw new ConflictError('Onboarding session is already completed');
    }

    if (sessionRow.status !== 'ready') {
      throw new ConflictError('Please finish all required steps before completing onboarding');
    }

    const stepRows = await fetchSteps({ sessionId: sessionRow.id, connection });
    const decoratedSteps = stepRows.map(decorateStep);

    const stepMap = new Map(decoratedSteps.map((step) => [step.key, step]));
    const companyProfile = stepMap.get('company_profile')?.payload || {};
    const branchSetup = stepMap.get('branch_setup')?.payload || {};
    const ownerAccount = stepMap.get('owner_account')?.payload || {};
    const billingPreferences = stepMap.get('billing_preferences')?.payload || {};

    if (!ownerAccount.passwordHash) {
      throw new AppError('Owner account step must include a password', 400, 'ONBOARDING_OWNER_PASSWORD_MISSING');
    }

    const now = new Date();

    const [tenantResult] = await connection.execute(
      `INSERT INTO tenants
         (name, domain, logo, phone, email, address, status, subscription_plan, settings, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, 'active', ?, ?, ?, ?)` ,
      [
        companyProfile.legalName || sessionRow.company_name,
        companyProfile.domain || null,
        companyProfile.logo || null,
        sessionRow.contact_phone || companyProfile.phone || null,
        sessionRow.contact_email || companyProfile.email || null,
        companyProfile.address || null,
        sessionRow.subscription_plan,
        JSON.stringify({
          language: sessionRow.preferred_language,
          timezone: companyProfile.timezone || null,
          industry: companyProfile.industry || null,
          source: 'self_service_onboarding'
        }),
        now,
        now
      ]
    );

    const tenantId = tenantResult.insertId;

    const [branchResult] = await connection.execute(
      `INSERT INTO branches
         (tenant_id, name, code, address, phone, email, latitude, longitude, opening_time, closing_time, is_main, is_active, settings)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, 1, ?)` ,
      [
        tenantId,
        branchSetup.branchName || `${sessionRow.company_name} - Main`,
        branchSetup.branchCode || null,
        branchSetup.branchAddress || null,
        branchSetup.branchPhone || sessionRow.contact_phone || null,
        branchSetup.branchEmail || sessionRow.contact_email || null,
        branchSetup.latitude ?? null,
        branchSetup.longitude ?? null,
        branchSetup.openingTime || null,
        branchSetup.closingTime || null,
        JSON.stringify({
          deliveryRadiusKm: branchSetup.deliveryRadiusKm ?? null,
          allowPickup: branchSetup.allowPickup ?? true
        })
      ]
    );

    const branchId = branchResult.insertId;

    const [userResult] = await connection.execute(
      `INSERT INTO users
         (tenant_id, branch_id, username, email, password_hash, full_name, phone, role, permissions, is_active, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, 'admin', ?, 1, ?, ?)` ,
      [
        tenantId,
        branchId,
        ownerAccount.username,
        ownerAccount.email,
        ownerAccount.passwordHash,
        ownerAccount.fullName,
        ownerAccount.phone || sessionRow.contact_phone || null,
        JSON.stringify(['tenants.manage', 'billing.manage', 'reports.view']),
        now,
        now
      ]
    );

    const userId = userResult.insertId;

    await connection.execute(
      `UPDATE tenant_onboarding_sessions
         SET status = 'completed', tenant_id = ?, current_step = NULL, completed_at = NOW(), updated_at = CURRENT_TIMESTAMP
       WHERE id = ?` ,
      [tenantId, sessionRow.id]
    );

    await connection.execute(
      `INSERT INTO tenant_onboarding_events (session_id, event_type, actor_type, actor_identifier, details)
       VALUES (?, 'session_completed', 'system', ?, ?)` ,
      [sessionRow.id, ownerAccount.email, JSON.stringify({ tenantId, userId })]
    );

    return {
      tenantId,
      branchId,
      userId,
      sessionRow,
      billingPreferences
    };
  });

  try {
    const { upsertSubscription } = require('./billing_service');

    await upsertSubscription({
      tenantId: completionResult.tenantId,
      payload: {
        planId: completionResult.sessionRow.subscription_plan,
        billingCycle: completionResult.billingPreferences.billingCycle || billingCycleOverride || 'monthly',
        paymentMethod: completionResult.billingPreferences.paymentMethod || 'invoice',
        seats: 1,
        notes: 'Auto-created during self-service onboarding',
        trialEndsAt: moment().add(7, 'days').toISOString()
      },
      actorId: completionResult.userId
    });
  } catch (error) {
    logger.warn('Failed to auto-create subscription after onboarding', {
      tenantId: completionResult.tenantId,
      error: error.message
    });
  }

  auditLogger.info('tenant_onboarding_completed', {
    tenantId: completionResult.tenantId,
    userId: completionResult.userId,
    source: 'self_service'
  });

  return getOnboardingSession(token);
};

module.exports = {
  startOnboarding,
  getOnboardingSession,
  submitOnboardingStep,
  completeOnboarding,
  STEP_DEFINITIONS,
  SESSION_DURATION_MINUTES
};
