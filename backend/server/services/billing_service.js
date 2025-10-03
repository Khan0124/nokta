const path = require('path');
const fs = require('fs');
const fsp = require('fs/promises');
const moment = require('moment');
const PDFDocument = require('pdfkit');
const { v4: uuidv4 } = require('uuid');
const databaseManager = require('../../config/database');
const { logger } = require('../../config/logger');
const { getGateway, listGateways } = require('./payment_gateways');

const INVOICE_STORAGE_DIR = path.join(__dirname, '../../storage/invoices');
const INVOICE_PUBLIC_PREFIX = 'storage/invoices';
const MISSING_TABLE_ERROR = 'ER_NO_SUCH_TABLE';

const PLAN_DEFINITIONS = [
  {
    id: 'basic',
    name: 'Basic',
    tier: 'basic',
    currency: 'USD',
    trialDays: 7,
    billingCycles: {
      monthly: { amount: 49, currency: 'USD', graceDays: 5 },
      yearly: { amount: 499, currency: 'USD', graceDays: 10 }
    },
    features: [
      'Up to 2 POS terminals',
      'Basic product catalog sync',
      'Offline receipt queue',
      'Email support (business hours)'
    ],
    usage: {
      posDevices: 2,
      products: 2000,
      callCenterSeats: 2,
      driverSeats: 5,
      analyticsExports: 10
    }
  },
  {
    id: 'pro',
    name: 'Pro',
    tier: 'pro',
    currency: 'USD',
    trialDays: 14,
    billingCycles: {
      monthly: { amount: 89, currency: 'USD', graceDays: 7 },
      yearly: { amount: 899, currency: 'USD', graceDays: 14 }
    },
    features: [
      'Unlimited POS terminals',
      'Advanced inventory with transfers',
      'Call center queue dashboards',
      'Driver GPS settlement reports',
      'Priority chat + email support'
    ],
    usage: {
      posDevices: 8,
      products: 10000,
      callCenterSeats: 10,
      driverSeats: 25,
      analyticsExports: 50
    }
  },
  {
    id: 'premium',
    name: 'Premium',
    tier: 'premium',
    currency: 'USD',
    trialDays: 21,
    billingCycles: {
      monthly: { amount: 149, currency: 'USD', graceDays: 10 },
      yearly: { amount: 1490, currency: 'USD', graceDays: 21 }
    },
    features: [
      'Franchise-ready multi-tenant controls',
      'Realtime analytics and BI exports',
      'Dedicated success manager',
      'Unlimited driver & call center seats',
      'Custom integrations via webhooks'
    ],
    usage: {
      posDevices: null,
      products: null,
      callCenterSeats: null,
      driverSeats: null,
      analyticsExports: null
    }
  }
];

const isMissingTableError = (error) => error?.code === MISSING_TABLE_ERROR;

const toNumber = (value, fallback = 0) => {
  const numeric = Number(value);
  return Number.isFinite(numeric) ? numeric : fallback;
};

const toMoney = (value) => Number.parseFloat((Number(value) || 0).toFixed(2));

const ensureDirectory = async (dir) => {
  await fsp.mkdir(dir, { recursive: true });
};

const transformPlanRow = (row) => ({
  id: row.id,
  name: row.name,
  tier: row.tier,
  currency: row.currency,
  trialDays: row.trial_days ?? null,
  billingCycles: {
    monthly: {
      amount: toMoney(row.monthly_price),
      currency: row.currency,
      graceDays: row.monthly_grace_days ?? 7
    },
    yearly: {
      amount: toMoney(row.yearly_price),
      currency: row.currency,
      graceDays: row.yearly_grace_days ?? 14
    }
  },
  features: Array.isArray(row.features) ? row.features : JSON.parse(row.features || '[]'),
  usage: typeof row.limits === 'string' ? JSON.parse(row.limits || '{}') : row.limits || {}
});

const loadPlansFromDatabase = async () => {
  try {
    const rows = await databaseManager.query(
      'SELECT id, name, tier, currency, monthly_price, yearly_price, monthly_grace_days, yearly_grace_days, trial_days, features, limits FROM subscription_plans WHERE is_active = 1'
    );

    if (!rows || rows.length === 0) {
      return null;
    }

    return rows.map(transformPlanRow);
  } catch (error) {
    if (isMissingTableError(error)) {
      return null;
    }

    logger.error('Failed to load subscription plans from database', { error: error.message });
    return null;
  }
};

const fetchPlanById = async (planId) => {
  try {
    const rows = await databaseManager.query(
      'SELECT id, name, tier, currency, monthly_price, yearly_price, monthly_grace_days, yearly_grace_days, trial_days, features, limits FROM subscription_plans WHERE id = ? LIMIT 1',
      [planId]
    );

    if (rows && rows.length > 0) {
      return transformPlanRow(rows[0]);
    }
  } catch (error) {
    if (!isMissingTableError(error)) {
      logger.error('Failed to fetch plan from database', { planId, error: error.message });
    }
  }

  const fallback = PLAN_DEFINITIONS.find((plan) => plan.id === planId);

  if (!fallback) {
    throw new Error(`Unknown subscription plan: ${planId}`);
  }

  return fallback;
};

const listPlans = async () => {
  const dbPlans = await loadPlansFromDatabase();
  return dbPlans && dbPlans.length > 0 ? dbPlans : PLAN_DEFINITIONS;
};

const computePeriodEnd = (start, billingCycle) => {
  const base = moment(start);
  return billingCycle === 'yearly' ? base.clone().add(1, 'year').toDate() : base.clone().add(1, 'month').toDate();
};

const generateInvoiceNumber = () => {
  const stamp = moment().format('YYYYMMDD');
  return `INV-${stamp}-${Math.floor(Math.random() * 90000 + 10000)}`;
};

const decorateInvoice = (row) => ({
  id: row.id,
  subscriptionId: row.subscription_id,
  invoiceNumber: row.invoice_number,
  periodStart: row.period_start,
  periodEnd: row.period_end,
  issueDate: row.issue_date,
  dueDate: row.due_date,
  currency: row.currency,
  subtotalAmount: toMoney(row.subtotal_amount),
  taxAmount: toMoney(row.tax_amount),
  totalAmount: toMoney(row.total_amount),
  amountPaid: toMoney(row.amount_paid),
  status: row.status,
  pdfPath: row.pdf_path,
  pdfGeneratedAt: row.pdf_generated_at,
  notes: row.notes,
  lineItems: typeof row.line_items === 'string' ? JSON.parse(row.line_items || '[]') : row.line_items || []
});

const decoratePayment = (row) => ({
  id: row.id,
  invoiceId: row.invoice_id,
  provider: row.provider,
  reference: row.provider_reference,
  amount: toMoney(row.amount),
  currency: row.currency,
  status: row.status,
  paidAt: row.paid_at,
  metadata: typeof row.metadata === 'string' ? JSON.parse(row.metadata || '{}') : row.metadata || {}
});

const loadSubscriptionRow = async ({ tenantId, subscriptionId }) => {
  try {
    const params = [];
    let sql = 'SELECT * FROM tenant_subscriptions WHERE ';

    if (subscriptionId) {
      sql += 'id = ?';
      params.push(subscriptionId);
    } else {
      sql += 'tenant_id = ?';
      params.push(tenantId);
    }

    sql += ' LIMIT 1';

    const rows = await databaseManager.query(sql, params);
    return rows && rows.length > 0 ? rows[0] : null;
  } catch (error) {
    if (isMissingTableError(error)) {
      logger.warn('tenant_subscriptions table missing when loading subscription');
      return null;
    }

    throw error;
  }
};

const decorateSubscription = async (row) => {
  if (!row) {
    return null;
  }

  const plan = await fetchPlanById(row.plan_id);
  const planCycle = plan.billingCycles[row.billing_cycle];

  let invoices = [];
  try {
    invoices = await databaseManager.query(
      `SELECT id, subscription_id, invoice_number, period_start, period_end, issue_date, due_date, currency, subtotal_amount, tax_amount, total_amount, amount_paid, status, pdf_path, pdf_generated_at, line_items, notes
       FROM subscription_invoices
       WHERE subscription_id = ?
       ORDER BY issue_date DESC
       LIMIT 24`,
      [row.id]
    );
  } catch (error) {
    if (!isMissingTableError(error)) {
      logger.error('Failed to load invoices for subscription', { subscriptionId: row.id, error: error.message });
    }
    invoices = [];
  }

  let payments = [];
  try {
    payments = await databaseManager.query(
      `SELECT id, invoice_id, provider, provider_reference, amount, currency, status, paid_at, metadata
       FROM subscription_payments
       WHERE invoice_id IN (
         SELECT id FROM subscription_invoices WHERE subscription_id = ?
       )
       ORDER BY created_at DESC
       LIMIT 50`,
      [row.id]
    );
  } catch (error) {
    if (!isMissingTableError(error)) {
      logger.error('Failed to load payments for subscription', { subscriptionId: row.id, error: error.message });
    }
    payments = [];
  }

  const decoratedInvoices = invoices.map(decorateInvoice);
  const decoratedPayments = payments.map(decoratePayment);

  const outstandingBalance = decoratedInvoices.reduce((balance, invoice) => {
    return balance + (toMoney(invoice.totalAmount) - toMoney(invoice.amountPaid));
  }, 0);

  const graceEndsAt = planCycle?.graceDays
    ? moment(row.current_period_end).add(planCycle.graceDays, 'days').toDate()
    : null;

  return {
    id: row.id,
    tenantId: row.tenant_id,
    planId: row.plan_id,
    status: row.status,
    billingCycle: row.billing_cycle,
    seats: row.seats,
    currency: row.currency,
    paymentMethod: row.payment_method,
    currentPeriod: {
      start: row.current_period_start,
      end: row.current_period_end,
      graceEndsAt
    },
    trialEndsAt: row.trial_ends_at,
    resumeAt: row.resume_at,
    cancelAt: row.cancel_at,
    notes: row.notes,
    plan,
    usageLimits: plan.usage,
    invoices: decoratedInvoices,
    payments: decoratedPayments,
    outstandingBalance: toMoney(outstandingBalance),
    gateways: listGateways()
  };
};

const upsertSubscription = async ({ tenantId, payload, actorId }) => {
  const plan = await fetchPlanById(payload.planId);
  const billingCycle = payload.billingCycle;
  const cyclePricing = plan.billingCycles[billingCycle];

  if (!cyclePricing) {
    throw new Error(`Plan ${plan.id} does not support ${billingCycle} billing`);
  }

  const now = new Date();
  const periodStart = now;
  const periodEnd = computePeriodEnd(periodStart, billingCycle);
  const trialEndsAt = payload.trialEndsAt
    ? new Date(payload.trialEndsAt)
    : plan.trialDays
      ? moment(periodStart).add(plan.trialDays, 'days').toDate()
      : null;

  return databaseManager.transaction(async (connection) => {
    const [existing] = await connection.query(
      'SELECT * FROM tenant_subscriptions WHERE tenant_id = ? LIMIT 1',
      [tenantId]
    );

    const subscriptionId = existing && existing.length > 0 ? existing[0].id : uuidv4();
    const meta = JSON.stringify({
      actorId,
      updatedAt: new Date().toISOString(),
      planFeatures: plan.features
    });

    if (existing && existing.length > 0) {
      await connection.query(
        `UPDATE tenant_subscriptions
         SET plan_id = ?,
             status = ?,
             billing_cycle = ?,
             seats = ?,
             currency = ?,
             payment_method = ?,
             current_period_start = ?,
             current_period_end = ?,
             trial_ends_at = ?,
             resume_at = NULL,
             cancel_at = NULL,
             notes = ?,
             meta = ?,
             updated_at = CURRENT_TIMESTAMP
         WHERE id = ?`,
        [
          plan.id,
          'active',
          billingCycle,
          payload.seats ?? existing[0].seats ?? 1,
          cyclePricing.currency,
          payload.paymentMethod,
          periodStart,
          periodEnd,
          trialEndsAt,
          payload.notes ?? existing[0].notes ?? null,
          meta,
          subscriptionId
        ]
      );
    } else {
      await connection.query(
        `INSERT INTO tenant_subscriptions
           (id, tenant_id, plan_id, status, billing_cycle, seats, currency, payment_method, current_period_start, current_period_end, trial_ends_at, notes, meta)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          subscriptionId,
          tenantId,
          plan.id,
          'active',
          billingCycle,
          payload.seats ?? 1,
          cyclePricing.currency,
          payload.paymentMethod,
          periodStart,
          periodEnd,
          trialEndsAt,
          payload.notes ?? null,
          meta
        ]
      );
    }

    return subscriptionId;
  }).then(async (subscriptionId) => {
    const row = await loadSubscriptionRow({ subscriptionId });
    return decorateSubscription(row);
  });
};

const updateSubscription = async ({ tenantId, subscriptionId, payload, actorId }) => {
  const row = await loadSubscriptionRow({ tenantId, subscriptionId });

  if (!row) {
    throw new Error('Subscription not found for tenant');
  }

  const plan = payload.planId ? await fetchPlanById(payload.planId) : await fetchPlanById(row.plan_id);
  const billingCycle = payload.billingCycle ?? row.billing_cycle;
  const cyclePricing = plan.billingCycles[billingCycle];

  const periodStart = payload.resumeAt ? new Date(payload.resumeAt) : row.current_period_start;
  const periodEnd = computePeriodEnd(periodStart, billingCycle);

  const status = payload.status ?? row.status;

  await databaseManager.query(
    `UPDATE tenant_subscriptions
     SET plan_id = ?,
         status = ?,
         billing_cycle = ?,
         seats = ?,
         currency = ?,
         payment_method = COALESCE(?, payment_method),
         current_period_start = ?,
         current_period_end = ?,
         trial_ends_at = COALESCE(?, trial_ends_at),
         resume_at = ?,
         cancel_at = ?,
         notes = COALESCE(?, notes),
         meta = JSON_SET(COALESCE(meta, JSON_OBJECT()), '$.lastActorId', ?, '$.updatedAt', ?),
         updated_at = CURRENT_TIMESTAMP
     WHERE id = ? AND tenant_id = ?`,
    [
      plan.id,
      status,
      billingCycle,
      payload.seats ?? row.seats,
      cyclePricing.currency,
      payload.paymentMethod ?? null,
      periodStart,
      periodEnd,
      payload.trialEndsAt ?? null,
      status === 'suspended' ? payload.resumeAt ?? computePeriodEnd(new Date(), billingCycle) : null,
      status === 'cancelled' ? new Date() : null,
      payload.notes ?? null,
      actorId,
      new Date().toISOString(),
      row.id,
      tenantId
    ]
  );

  const updated = await loadSubscriptionRow({ subscriptionId: row.id });
  return decorateSubscription(updated);
};

const computeInvoiceTotals = (items) => {
  return items.reduce(
    (acc, item) => {
      const quantity = toNumber(item.quantity, 1);
      const unitPrice = toMoney(item.unitPrice);
      const lineSubtotal = quantity * unitPrice;
      const lineTax = (lineSubtotal * toNumber(item.taxRate, 0)) / 100;

      acc.subtotal += lineSubtotal;
      acc.tax += lineTax;
      acc.total += lineSubtotal + lineTax;
      return acc;
    },
    { subtotal: 0, tax: 0, total: 0 }
  );
};

const generateInvoicePdf = async ({ invoice, tenant, plan, items, totals }) => {
  await ensureDirectory(INVOICE_STORAGE_DIR);
  const fileName = `${invoice.invoiceNumber}.pdf`;
  const filePath = path.join(INVOICE_STORAGE_DIR, fileName);

  await new Promise((resolve, reject) => {
    const doc = new PDFDocument({ margin: 40 });
    const stream = fs.createWriteStream(filePath);

    stream.on('finish', resolve);
    stream.on('error', reject);

    doc.pipe(stream);

    doc.fontSize(20).text('Subscription Invoice', { align: 'center' });
    doc.moveDown();

    doc.fontSize(12).text(`Invoice Number: ${invoice.invoiceNumber}`);
    doc.text(`Tenant: ${tenant.name}`);
    doc.text(`Plan: ${plan.name} (${invoice.billingCycle.toUpperCase()})`);
    doc.text(`Issue Date: ${moment(invoice.issueDate).format('YYYY-MM-DD')}`);
    doc.text(`Due Date: ${invoice.dueDate ? moment(invoice.dueDate).format('YYYY-MM-DD') : 'Upon Receipt'}`);
    doc.text(`Billing Period: ${moment(invoice.periodStart).format('YYYY-MM-DD')} to ${moment(invoice.periodEnd).format('YYYY-MM-DD')}`);
    doc.moveDown();

    const tableTop = doc.y;
    doc.text('Description', 50, tableTop, { continued: true });
    doc.text('Qty', 250, tableTop, { continued: true });
    doc.text('Unit Price', 320, tableTop, { continued: true });
    doc.text('Tax %', 410, tableTop, { continued: true });
    doc.text('Line Total', 470, tableTop);
    doc.moveDown();

    items.forEach((item) => {
      const lineSubtotal = toMoney(toNumber(item.quantity, 1) * toMoney(item.unitPrice));
      const lineTax = toMoney((lineSubtotal * toNumber(item.taxRate, 0)) / 100);
      const lineTotal = toMoney(lineSubtotal + lineTax);

      doc.text(item.description, 50, doc.y, { continued: true });
      doc.text(String(item.quantity ?? 1), 250, doc.y, { continued: true });
      doc.text(`${invoice.currency} ${lineSubtotal.toFixed(2)}`, 320, doc.y, { continued: true });
      doc.text(`${toNumber(item.taxRate, 0).toFixed(2)}%`, 410, doc.y, { continued: true });
      doc.text(`${invoice.currency} ${lineTotal.toFixed(2)}`, 470, doc.y);
      doc.moveDown();
    });

    doc.moveDown();

    doc.text(`Subtotal: ${invoice.currency} ${totals.subtotal.toFixed(2)}`, { align: 'right' });
    doc.text(`Tax: ${invoice.currency} ${totals.tax.toFixed(2)}`, { align: 'right' });
    doc.text(`Total: ${invoice.currency} ${totals.total.toFixed(2)}`, { align: 'right' });

    if (invoice.notes) {
      doc.moveDown();
      doc.text(`Notes: ${invoice.notes}`);
    }

    doc.end();
  });

  return {
    filePath,
    relativePath: path.join(INVOICE_PUBLIC_PREFIX, fileName)
  };
};

const issueInvoice = async ({ tenantId, subscriptionId, payload, actorId }) => {
  const subscriptionRow = await loadSubscriptionRow({ tenantId, subscriptionId });

  if (!subscriptionRow) {
    throw new Error('Subscription not found');
  }

  const plan = await fetchPlanById(subscriptionRow.plan_id);
  const items = payload.items || [
    {
      description: `${plan.name} plan (${payload.periodStart} - ${payload.periodEnd})`,
      quantity: 1,
      unitPrice: plan.billingCycles[subscriptionRow.billing_cycle].amount,
      taxRate: 0
    }
  ];

  const totals = computeInvoiceTotals(items);
  const invoiceId = uuidv4();
  const invoiceNumber = generateInvoiceNumber();
  const issueDate = payload.issueDate ? new Date(payload.issueDate) : new Date();
  const dueDate = payload.dueDate ? new Date(payload.dueDate) : null;
  const currency = payload.currency || subscriptionRow.currency;

  await databaseManager.query(
    `INSERT INTO subscription_invoices
       (id, subscription_id, invoice_number, period_start, period_end, issue_date, due_date, currency, subtotal_amount, tax_amount, total_amount, amount_paid, status, pdf_path, line_items, notes)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'open', NULL, ?, ?)`
    , [
      invoiceId,
      subscriptionRow.id,
      invoiceNumber,
      new Date(payload.periodStart),
      new Date(payload.periodEnd),
      issueDate,
      dueDate,
      currency,
      toMoney(totals.subtotal),
      toMoney(totals.tax),
      toMoney(totals.total),
      0,
      JSON.stringify(items),
      payload.notes ?? null
    ]
  );

  const tenant = {
    id: subscriptionRow.tenant_id,
    name: payload.tenantName || `Tenant ${subscriptionRow.tenant_id}`
  };

  try {
    const pdf = await generateInvoicePdf({
      invoice: {
        invoiceNumber,
        currency,
        issueDate,
        dueDate,
        periodStart: payload.periodStart,
        periodEnd: payload.periodEnd,
        billingCycle: subscriptionRow.billing_cycle,
        notes: payload.notes ?? null
      },
      tenant,
      plan,
      items,
      totals
    });

    await databaseManager.query(
      'UPDATE subscription_invoices SET pdf_path = ?, pdf_generated_at = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      [pdf.relativePath, new Date(), invoiceId]
    );
  } catch (error) {
    logger.error('Failed to generate invoice PDF', { invoiceId, error: error.message });
  }

  const invoiceRows = await databaseManager.query(
    'SELECT * FROM subscription_invoices WHERE id = ? LIMIT 1',
    [invoiceId]
  );

  const invoiceRow = invoiceRows && invoiceRows.length > 0 ? invoiceRows[0] : null;
  const decorated = invoiceRow ? decorateInvoice(invoiceRow) : null;

  return {
    invoice: decorated,
    subscription: await decorateSubscription(subscriptionRow)
  };
};

const recordPayment = async ({ tenantId, subscriptionId, invoiceId, payload }) => {
  const subscriptionRow = await loadSubscriptionRow({ tenantId, subscriptionId });

  if (!subscriptionRow) {
    throw new Error('Subscription not found');
  }

  const invoiceRows = await databaseManager.query(
    'SELECT * FROM subscription_invoices WHERE id = ? AND subscription_id = ? LIMIT 1',
    [invoiceId, subscriptionRow.id]
  );

  if (!invoiceRows || invoiceRows.length === 0) {
    throw new Error('Invoice not found for subscription');
  }

  const invoice = invoiceRows[0];
  const gateway = getGateway(payload.provider);

  const chargeResult = await gateway.charge({
    amount: payload.amount,
    currency: payload.currency || invoice.currency,
    description: `Subscription invoice ${invoice.invoice_number}`,
    metadata: {
      tenantId,
      subscriptionId: subscriptionRow.id,
      invoiceId,
      actor: payload.actorId || null
    }
  });

  const paymentId = uuidv4();
  const paidAt = payload.paidAt ? new Date(payload.paidAt) : new Date();

  await databaseManager.query(
    `INSERT INTO subscription_payments
       (id, invoice_id, provider, provider_reference, amount, currency, status, paid_at, metadata)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
    , [
      paymentId,
      invoiceId,
      payload.provider,
      chargeResult.reference || payload.reference,
      toMoney(payload.amount),
      (payload.currency || invoice.currency).toUpperCase(),
      payload.status || chargeResult.status,
      paidAt,
      JSON.stringify(payload.metadata || chargeResult.metadata || {})
    ]
  );

  const newAmountPaid = toMoney(invoice.amount_paid) + toMoney(payload.amount);
  const invoiceStatus = newAmountPaid >= toMoney(invoice.total_amount) ? 'paid' : invoice.status;

  await databaseManager.query(
    `UPDATE subscription_invoices
     SET amount_paid = ?, status = ?, updated_at = CURRENT_TIMESTAMP
     WHERE id = ?`,
    [toMoney(newAmountPaid), invoiceStatus, invoiceId]
  );

  const updatedInvoiceRows = await databaseManager.query(
    'SELECT * FROM subscription_invoices WHERE id = ? LIMIT 1',
    [invoiceId]
  );

  const updatedInvoice = updatedInvoiceRows && updatedInvoiceRows.length > 0
    ? decorateInvoice(updatedInvoiceRows[0])
    : null;

  return {
    payment: decoratePayment({
      id: paymentId,
      invoice_id: invoiceId,
      provider: payload.provider,
      provider_reference: chargeResult.reference || payload.reference,
      amount: payload.amount,
      currency: payload.currency || invoice.currency,
      status: payload.status || chargeResult.status,
      paid_at: paidAt,
      metadata: payload.metadata || chargeResult.metadata || {}
    }),
    invoice: updatedInvoice
  };
};

const getSubscriptionSummary = async ({ tenantId, subscriptionId }) => {
  const row = await loadSubscriptionRow({ tenantId, subscriptionId });
  return decorateSubscription(row);
};

const listInvoicesForSubscription = async ({ tenantId, subscriptionId }) => {
  const row = await loadSubscriptionRow({ tenantId, subscriptionId });

  if (!row) {
    return [];
  }

  try {
    const invoices = await databaseManager.query(
      `SELECT id, subscription_id, invoice_number, period_start, period_end, issue_date, due_date, currency, subtotal_amount, tax_amount, total_amount, amount_paid, status, pdf_path, pdf_generated_at, line_items, notes
       FROM subscription_invoices
       WHERE subscription_id = ?
       ORDER BY issue_date DESC`,
      [row.id]
    );

    return invoices.map(decorateInvoice);
  } catch (error) {
    if (isMissingTableError(error)) {
      return [];
    }

    throw error;
  }
};

const handleGatewayWebhook = async ({ provider, eventType, data }) => {
  logger.info('Billing webhook received', { provider, eventType });

  if (!provider || !eventType) {
    throw new Error('Provider and event type are required');
  }

  if (provider === 'stripe' && eventType === 'invoice.payment_succeeded') {
    const invoiceNumber = data?.invoiceNumber || data?.data?.object?.number;
    if (invoiceNumber) {
      try {
        await databaseManager.query(
          `UPDATE subscription_invoices
           SET status = 'paid', amount_paid = total_amount, updated_at = CURRENT_TIMESTAMP
           WHERE invoice_number = ?`,
          [invoiceNumber]
        );
      } catch (error) {
        if (isMissingTableError(error)) {
          logger.warn('subscription_invoices table missing when processing webhook');
        } else {
          throw error;
        }
      }
    }
  }

  if (provider === 'local_bank' && eventType === 'payment_settled') {
    const reference = data?.reference;
    if (reference) {
      try {
        await databaseManager.query(
          `UPDATE subscription_payments
           SET status = 'succeeded', updated_at = CURRENT_TIMESTAMP
           WHERE provider_reference = ?`,
          [reference]
        );
      } catch (error) {
        if (isMissingTableError(error)) {
          logger.warn('subscription_payments table missing when processing webhook');
        } else {
          throw error;
        }
      }
    }
  }

  return { accepted: true };
};

module.exports = {
  listPlans,
  upsertSubscription,
  updateSubscription,
  issueInvoice,
  recordPayment,
  getSubscriptionSummary,
  listInvoicesForSubscription,
  handleGatewayWebhook
};
