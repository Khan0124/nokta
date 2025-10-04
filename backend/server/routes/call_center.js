const express = require('express');
const crypto = require('crypto');
const databaseManager = require('../../config/database');
const redisManager = require('../../config/redis');
const { logger } = require('../../config/logger');
const { authenticateToken, requireRole, validateTenant } = require('../../middleware/auth');
const { requireFeatureFlag } = require('../../middleware/featureFlag');
const { validate, schemas } = require('../../middleware/validation');
const { asyncHandler } = require('../../middleware/errorHandler');

const router = express.Router();

const CALL_QUEUE_TTL_SECONDS = 60 * 60; // 1 hour snapshot retention
const FALLBACK_ORDER_TTL_SECONDS = 60 * 60 * 24; // 24 hours for queued orders

const isMissingTableError = (error) => error?.code === 'ER_NO_SUCH_TABLE';

const toSafeNumber = (value, fallback = 0) => {
  const numeric = Number(value);
  return Number.isFinite(numeric) ? numeric : fallback;
};

const resolveTenantId = (req, override) => override || req.tenant?.id || req.user?.tenantId;

const queueCacheKey = (tenantId) => `call_center:queue:${tenantId}`;
const fallbackOrderKey = (tenantId, token) => `call_center:fallback_order:${tenantId}:${token}`;

const loadQueue = async (tenantId) => {
  try {
    const snapshot = await redisManager.get(queueCacheKey(tenantId));
    return Array.isArray(snapshot) ? snapshot : [];
  } catch (error) {
    logger.warn('Unable to load call center queue snapshot from Redis', { tenantId, error: error.message });
    return [];
  }
};

const decorateQueueEntries = async (tenantId) => {
  const queue = await loadQueue(tenantId);
  if (!queue.length) {
    return [];
  }

  const phones = queue
    .map((entry) => entry.phone)
    .filter((phone) => typeof phone === 'string' && phone.length > 0);

  const customersByPhone = new Map();

  if (phones.length) {
    try {
      const rows = await databaseManager.query(
        `SELECT id, full_name AS fullName, phone, preferred_branch_id AS preferredBranchId,
                loyalty_points AS loyaltyPoints, last_order_at AS lastOrderAt
           FROM customers
          WHERE tenant_id = ?
            AND phone IN (${phones.map(() => '?').join(',')})`,
        [tenantId, ...phones]
      );

      rows.forEach((row) => {
        if (row.phone) {
          customersByPhone.set(row.phone, row);
        }
      });
    } catch (error) {
      if (!isMissingTableError(error)) {
        throw error;
      }
      logger.info('Call center queue decoration fallback (customers table missing)', { tenantId });
    }
  }

  return queue.map((entry, index) => {
    const customer = entry.phone ? customersByPhone.get(entry.phone) : null;
    const waitingSince = entry.startedAt || entry.queuedAt || entry.waitingSince || new Date().toISOString();
    const basePriority = Number.isFinite(entry.priority)
      ? entry.priority
      : Math.min(100, 50 + Math.round((customer?.loyaltyPoints || 0) / 20));

    return {
      id: entry.id || `${entry.phone || 'call'}-${index}`,
      callerNumber: entry.phone || entry.callerNumber || 'unknown',
      displayName: entry.displayName || customer?.fullName || entry.phone || 'Unknown Caller',
      status: entry.status || 'queued',
      waitingSince,
      priority: basePriority,
      customerId: entry.customerId || customer?.id || null,
      lastOrderId: entry.lastOrderId || null,
      notes: entry.notes || null,
      agentId: entry.agentId || null,
      preferredBranchId: customer?.preferredBranchId || null,
      loyaltyPoints: customer?.loyaltyPoints || 0,
      lastOrderAt: customer?.lastOrderAt || null,
    };
  });
};

const persistQueue = async (tenantId, queue) => {
  try {
    await redisManager.set(queueCacheKey(tenantId), queue, CALL_QUEUE_TTL_SECONDS);
  } catch (error) {
    logger.warn('Unable to persist call center queue snapshot to Redis', { tenantId, error: error.message });
  }
};

const removePhoneFromQueue = async (tenantId, phone) => {
  const queue = await loadQueue(tenantId);
  if (queue.length === 0) return;

  const trimmed = queue.filter((entry) => entry.phone !== phone);
  if (trimmed.length !== queue.length) {
    await persistQueue(tenantId, trimmed);
  }
};

const upsertQueueEntry = async (tenantId, entry) => {
  const queue = await loadQueue(tenantId);
  const existingIndex = queue.findIndex((item) => item.phone === entry.phone);

  if (existingIndex >= 0) {
    queue[existingIndex] = { ...queue[existingIndex], ...entry };
  } else {
    queue.push(entry);
  }

  await persistQueue(tenantId, queue);
};

const fetchBranchCandidate = async (tenantId, preferredBranchId = null) => {
  try {
    if (preferredBranchId) {
      const rows = await databaseManager.query(
        'SELECT id, name, latitude, longitude, is_main, is_active FROM branches WHERE tenant_id = ? AND id = ? LIMIT 1',
        [tenantId, preferredBranchId]
      );
      if (rows.length > 0) {
        return rows[0];
      }
    }

    const rows = await databaseManager.query(
      'SELECT id, name, latitude, longitude, is_main, is_active FROM branches WHERE tenant_id = ? AND is_active = 1 ORDER BY is_main DESC, id ASC LIMIT 1',
      [tenantId]
    );
    return rows.length > 0 ? rows[0] : null;
  } catch (error) {
    if (isMissingTableError(error)) {
      return preferredBranchId ? { id: preferredBranchId } : null;
    }
    throw error;
  }
};

const fetchCustomerSearchResults = async ({ tenantId, query, limit }) => {
  try {
    const rows = await databaseManager.query(
      `SELECT c.id, c.full_name AS fullName, c.phone, c.alternate_phone AS alternatePhone,
              c.email, c.preferred_branch_id AS preferredBranchId, c.loyalty_points AS loyaltyPoints,
              c.last_order_at AS lastOrderAt, ca.id AS addressId, ca.address_line1 AS addressLine1,
              ca.address_line2 AS addressLine2, ca.city, ca.latitude, ca.longitude
         FROM customers c
         LEFT JOIN customer_addresses ca ON ca.id = c.default_address_id
        WHERE c.tenant_id = ?
          AND (
            c.phone LIKE ? OR
            c.alternate_phone LIKE ? OR
            c.full_name LIKE ?
          )
        ORDER BY (c.last_order_at IS NULL), c.last_order_at DESC
        LIMIT ?`,
      [tenantId, `%${query}%`, `%${query}%`, `%${query}%`, limit]
    );

    return rows;
  } catch (error) {
    if (isMissingTableError(error)) {
      logger.info('Customer search falling back to default stub (customers table missing)', { tenantId });
      return [];
    }
    throw error;
  }
};

const attachRecentOrderHistory = async (tenantId, customers, limit = 3) => {
  if (!customers.length) return customers;

  const customerIds = customers.filter((customer) => customer.id).map((customer) => customer.id);
  const phones = customers.map((customer) => customer.phone);

  try {
    const rows = await databaseManager.query(
      `SELECT o.id, o.order_number AS orderNumber, o.customer_id AS customerId,
              o.customer_phone AS customerPhone, o.total_amount AS totalAmount,
              o.status, o.created_at AS createdAt
         FROM orders o
        WHERE o.tenant_id = ?
          AND (
            (o.customer_id IS NOT NULL AND o.customer_id IN (${customerIds.length ? customerIds.map(() => '?').join(',') : 'NULL'})) OR
            o.customer_phone IN (${phones.map(() => '?').join(',')})
          )
        ORDER BY o.created_at DESC` ,
      [tenantId, ...customerIds, ...phones]
    );

    const grouped = new Map();
    rows.forEach((row) => {
      const key = row.customerId || row.customerPhone;
      if (!grouped.has(key)) {
        grouped.set(key, []);
      }
      if (grouped.get(key).length < limit) {
        grouped.get(key).push(row);
      }
    });

    return customers.map((customer) => {
      const historyKey = customer.id || customer.phone;
      return {
        ...customer,
        recentOrders: grouped.get(historyKey) || []
      };
    });
  } catch (error) {
    if (isMissingTableError(error)) {
      logger.info('Order history fallback triggered (orders table missing)', { tenantId });
      return customers.map((customer) => ({ ...customer, recentOrders: [] }));
    }
    throw error;
  }
};

const collectDashboardMetrics = async (tenantId, range = 'today', branchId = null) => {
  const now = new Date();
  const defaultMetrics = {
    tenantId,
    branchId,
    range,
    queueLength: 0,
    activeCalls: 0,
    completedCalls: 0,
    abandonedCalls: 0,
    callbacksScheduled: 0,
    averageHandleTimeSeconds: 0,
    averageWaitTimeSeconds: 0,
    serviceLevelTargetSeconds: 30,
    serviceLevelAchievement: 0,
    ordersCreated: 0,
    updatedAt: now.toISOString()
  };

  const queue = await loadQueue(tenantId);
  defaultMetrics.queueLength = queue.length;
  defaultMetrics.activeCalls = queue.filter((entry) => entry.status === 'active').length;

  const rangeClause = {
    today: 'AND created_at >= CURRENT_DATE()',
    '7d': 'AND created_at >= (CURRENT_DATE() - INTERVAL 7 DAY)',
    '30d': 'AND created_at >= (CURRENT_DATE() - INTERVAL 30 DAY)'
  }[range] || 'AND created_at >= CURRENT_DATE()';

  try {
    const rows = await databaseManager.query(
      `SELECT
         COUNT(*) AS totalCalls,
         SUM(status = 'active') AS activeCalls,
         SUM(status = 'queued') AS queuedCalls,
         SUM(disposition = 'completed') AS completedCalls,
         SUM(disposition = 'callback') AS callbacks,
         SUM(disposition = 'abandoned') AS abandonedCalls,
         AVG(handle_time_seconds) AS avgHandle,
         AVG(wait_time_seconds) AS avgWait,
         SUM(CASE WHEN wait_time_seconds <= 30 THEN 1 ELSE 0 END) AS withinServiceLevel
       FROM call_center_calls
      WHERE tenant_id = ?
        ${branchId ? 'AND (branch_id = ? OR branch_id IS NULL)' : ''}
        ${rangeClause}`,
      branchId ? [tenantId, branchId] : [tenantId]
    );

    if (rows.length) {
      const stats = rows[0];
      defaultMetrics.activeCalls = toSafeNumber(stats.activeCalls, defaultMetrics.activeCalls);
      defaultMetrics.completedCalls = toSafeNumber(stats.completedCalls);
      defaultMetrics.abandonedCalls = toSafeNumber(stats.abandonedCalls);
      defaultMetrics.callbacksScheduled = toSafeNumber(stats.callbacks);
      defaultMetrics.averageHandleTimeSeconds = toSafeNumber(stats.avgHandle, 0);
      defaultMetrics.averageWaitTimeSeconds = toSafeNumber(stats.avgWait, 0);
      const totalForSla = toSafeNumber(stats.totalCalls, 0);
      defaultMetrics.serviceLevelAchievement = totalForSla > 0
        ? Math.round((toSafeNumber(stats.withinServiceLevel, 0) / totalForSla) * 100)
        : 0;
    }
  } catch (error) {
    if (!isMissingTableError(error)) {
      throw error;
    }
    logger.info('Call center metrics fallback (call_center_calls table missing)', { tenantId });
  }

  try {
    const orders = await databaseManager.query(
      `SELECT COUNT(*) AS ordersCreated
         FROM orders
        WHERE tenant_id = ?
          AND source = 'call_center'
          ${branchId ? 'AND branch_id = ?' : ''}
          ${rangeClause}`,
      branchId ? [tenantId, branchId] : [tenantId]
    );
    if (orders.length) {
      defaultMetrics.ordersCreated = toSafeNumber(orders[0].ordersCreated, 0);
    }
  } catch (error) {
    if (!isMissingTableError(error)) {
      throw error;
    }
  }

  return defaultMetrics;
};

router.use(authenticateToken);
router.use(requireFeatureFlag('callCenter.routing', { statusCode: 404 }));
router.use(requireRole('staff', 'manager', 'admin'));
router.use(validateTenant);

router.get('/queue',
  validate(schemas.callCenter.queue, 'query'),
  asyncHandler(async (req, res) => {
    const tenantId = resolveTenantId(req, req.query.tenantId);
    const queue = await decorateQueueEntries(tenantId);
    res.json({
      tenantId,
      count: queue.length,
      results: queue,
    });
  })
);

router.get('/dashboard',
  validate(schemas.callCenter.dashboard, 'query'),
  asyncHandler(async (req, res) => {
    const tenantId = resolveTenantId(req, req.query.tenantId);
    const metrics = await collectDashboardMetrics(tenantId, req.query.range, req.query.branchId || null);
    res.json(metrics);
  })
);

router.get('/customers/search',
  validate(schemas.callCenter.search, 'query'),
  asyncHandler(async (req, res) => {
    const tenantId = resolveTenantId(req, req.query.tenantId);
    const limit = req.query.limit;
    const baseResults = await fetchCustomerSearchResults({ tenantId, query: req.query.q, limit });

    const results = req.query.includeHistory
      ? await attachRecentOrderHistory(tenantId, baseResults, 3)
      : baseResults.map((customer) => ({ ...customer, recentOrders: [] }));

    const queue = await loadQueue(tenantId);
    const decorated = results.map((customer) => ({
      ...customer,
      queueStatus: queue.find((entry) => entry.phone === customer.phone) || null
    }));

    res.json({
      query: req.query.q,
      count: decorated.length,
      results: decorated
    });
  })
);

router.get('/calls/recent',
  validate(schemas.callCenter.recentCalls, 'query'),
  asyncHandler(async (req, res) => {
    const tenantId = resolveTenantId(req, req.query.tenantId);
    const limit = req.query.limit;
    const offset = (req.query.page - 1) * limit;

    try {
      const rows = await databaseManager.query(
        `SELECT id, tenant_id AS tenantId, branch_id AS branchId, agent_id AS agentId,
                customer_id AS customerId, order_id AS orderId, phone, status, disposition,
                wait_time_seconds AS waitTimeSeconds, handle_time_seconds AS handleTimeSeconds,
                started_at AS startedAt, ended_at AS endedAt, notes, metadata, created_at AS createdAt
           FROM call_center_calls
          WHERE tenant_id = ?
            ${req.query.branchId ? 'AND (branch_id = ? OR branch_id IS NULL)' : ''}
          ORDER BY created_at DESC
          LIMIT ? OFFSET ?`,
        req.query.branchId ? [tenantId, req.query.branchId, limit, offset] : [tenantId, limit, offset]
      );

      res.json({
        page: req.query.page,
        limit,
        count: rows.length,
        results: rows
      });
    } catch (error) {
      if (isMissingTableError(error)) {
        return res.json({ page: req.query.page, limit, count: 0, results: [] });
      }
      throw error;
    }
  })
);

router.post('/calls',
  validate(schemas.callCenter.logCall),
  asyncHandler(async (req, res) => {
    const tenantId = resolveTenantId(req, req.body.tenantId);
    const agentId = req.user?.id || null;
    const payload = {
      phone: req.body.phone,
      status: req.body.status,
      disposition: req.body.disposition,
      wait_time_seconds: req.body.waitTimeSeconds,
      handle_time_seconds: req.body.handleTimeSeconds ?? Math.max(0, Math.floor((new Date(req.body.endedAt || Date.now()) - new Date(req.body.startedAt)) / 1000)),
      notes: req.body.notes,
      tags: req.body.tags,
      tenant_id: tenantId,
      branch_id: req.body.branchId || req.user?.branchId || null,
      agent_id: agentId,
      customer_id: req.body.customerId || null,
      order_id: req.body.orderId || null,
      started_at: new Date(req.body.startedAt),
      ended_at: req.body.endedAt ? new Date(req.body.endedAt) : null
    };

    try {
      const insertId = await databaseManager.insert('call_center_calls', {
        ...payload,
        metadata: JSON.stringify({ tags: req.body.tags }),
        created_at: new Date()
      });

      if (payload.status === 'queued' || payload.status === 'active') {
        await upsertQueueEntry(tenantId, {
          phone: payload.phone,
          status: payload.status,
          startedAt: payload.started_at,
          agentId,
          tenantId,
          notes: payload.notes || null
        });
      } else {
        await removePhoneFromQueue(tenantId, payload.phone);
      }

      res.status(201).json({
        success: true,
        id: insertId,
        tenantId,
        persisted: 'database'
      });
    } catch (error) {
      if (!isMissingTableError(error)) {
        throw error;
      }

      const fallbackToken = crypto.randomUUID();
      const fallbackRecord = {
        id: fallbackToken,
        ...payload,
        created_at: new Date().toISOString()
      };

      await redisManager.set(fallbackOrderKey(tenantId, fallbackToken), fallbackRecord, FALLBACK_ORDER_TTL_SECONDS);

      if (payload.status === 'queued' || payload.status === 'active') {
        await upsertQueueEntry(tenantId, {
          phone: payload.phone,
          status: payload.status,
          startedAt: payload.started_at,
          agentId,
          tenantId,
          notes: payload.notes || null
        });
      }

      res.status(202).json({
        success: true,
        id: fallbackToken,
        tenantId,
        persisted: 'redis'
      });
    }
  })
);

router.post('/orders',
  validate(schemas.callCenter.createOrder),
  asyncHandler(async (req, res) => {
    const tenantId = resolveTenantId(req, req.body.tenantId);
    const branchCandidate = await fetchBranchCandidate(tenantId, req.body.branchId || req.user?.branchId || req.body.customer?.preferredBranchId);

    const orderPayload = {
      tenantId,
      branchId: branchCandidate?.id || null,
      customer: req.body.customer,
      items: req.body.items,
      delivery: req.body.delivery,
      payment: req.body.payment,
      metadata: req.body.metadata,
      campaignCode: req.body.campaignCode || null,
      createdAt: new Date().toISOString()
    };

    const calculateTotals = () => {
      const subtotal = req.body.items.reduce((acc, item) => acc + (item.quantity * item.unitPrice - item.discount), 0);
      const total = subtotal + req.body.payment.tipAmount + (req.body.delivery.type === 'delivery' ? toSafeNumber(req.body.delivery.fee, 0) : 0);
      return { subtotal, total };
    };

    const { subtotal, total } = calculateTotals();

    const buildOrderNumber = () => {
      const timestamp = Date.now().toString().slice(-6);
      const branchSegment = orderPayload.branchId ? orderPayload.branchId.toString().padStart(3, '0') : '000';
      return `CC-${branchSegment}-${timestamp}`;
    };

    try {
      const result = await databaseManager.transaction(async (connection) => {
        const [orderResult] = await connection.execute(
          `INSERT INTO orders
             (tenant_id, branch_id, order_number, source, status, payment_status, subtotal_amount,
              total_amount, customer_id, customer_name, customer_phone, customer_email, delivery_address,
              delivery_city, delivery_latitude, delivery_longitude, delivery_type, delivery_notes,
              scheduled_at, metadata, campaign_code, created_at, updated_at)
           VALUES (?, ?, ?, 'call_center', 'pending', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())`,
          [
            tenantId,
            orderPayload.branchId,
            buildOrderNumber(),
            orderPayload.payment.status,
            subtotal,
            total,
            orderPayload.customer.id || null,
            orderPayload.customer.fullName,
            orderPayload.customer.phone,
            orderPayload.customer.email || null,
            orderPayload.delivery.addressLine1 || orderPayload.customer.addressLine1 || null,
            orderPayload.delivery.city || orderPayload.customer.city || null,
            orderPayload.delivery.latitude || orderPayload.customer.latitude || null,
            orderPayload.delivery.longitude || orderPayload.customer.longitude || null,
            orderPayload.delivery.type,
            orderPayload.delivery.notes || orderPayload.customer.notes || null,
            orderPayload.delivery.scheduledAt || null,
            JSON.stringify(orderPayload.metadata),
            orderPayload.campaignCode || null
          ]
        );

        const orderId = orderResult.insertId;

        for (const item of orderPayload.items) {
          await connection.execute(
            `INSERT INTO order_items
               (order_id, product_id, product_name, quantity, unit_price, discount_amount, modifiers, notes)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)` ,
            [
              orderId,
              item.productId,
              item.name,
              item.quantity,
              item.unitPrice,
              item.discount || 0,
              JSON.stringify(item.modifiers || []),
              item.notes || null
            ]
          );
        }

        if (req.body.callId) {
          await connection.execute(
            'UPDATE call_center_calls SET order_id = ?, status = "completed", disposition = "completed", updated_at = NOW() WHERE id = ? AND tenant_id = ?',
            [orderId, req.body.callId, tenantId]
          );
        }

        return { orderId };
      });

      await removePhoneFromQueue(tenantId, orderPayload.customer.phone);

      res.status(201).json({
        success: true,
        tenantId,
        orderId: result.orderId,
        branchId: orderPayload.branchId,
        totals: { subtotal, total },
        persisted: 'database'
      });
    } catch (error) {
      if (!isMissingTableError(error)) {
        throw error;
      }

      const fallbackId = crypto.randomUUID();
      const fallbackData = {
        id: fallbackId,
        ...orderPayload,
        totals: { subtotal, total },
        status: 'queued',
        persisted: 'redis',
        createdAt: new Date().toISOString()
      };

      await redisManager.set(fallbackOrderKey(tenantId, fallbackId), fallbackData, FALLBACK_ORDER_TTL_SECONDS);
      await upsertQueueEntry(tenantId, {
        phone: orderPayload.customer.phone,
        status: 'queued',
        tenantId,
        agentId: req.user?.id || null,
        notes: orderPayload.metadata.notes || null,
        queuedAt: new Date().toISOString()
      });

      res.status(202).json({
        success: true,
        tenantId,
        orderId: fallbackId,
        branchId: orderPayload.branchId,
        totals: { subtotal, total },
        persisted: 'redis'
      });
    }
  })
);

module.exports = router;
module.exports.__private__ = {
  decorateQueueEntries,
};
