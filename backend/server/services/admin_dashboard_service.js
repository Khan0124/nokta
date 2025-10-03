const databaseManager = require('../../config/database');
const { logger } = require('../../config/logger');

const MISSING_TABLE_ERROR = 'ER_NO_SUCH_TABLE';

const isMissingTableError = (error) => error?.code === MISSING_TABLE_ERROR;

const safeNumber = (value, fallback = 0) => {
  const numeric = Number(value);
  return Number.isFinite(numeric) ? numeric : fallback;
};

const buildOrderFilters = ({ tenantId, branchId, startDate, endDate }) => {
  const clauses = ['o.tenant_id = ?'];
  const params = [tenantId];

  if (branchId) {
    clauses.push('o.branch_id = ?');
    params.push(branchId);
  }

  if (startDate) {
    clauses.push('o.created_at >= ?');
    params.push(startDate);
  }

  if (endDate) {
    clauses.push('o.created_at <= ?');
    params.push(endDate);
  }

  return { where: clauses.join(' AND '), params };
};

const buildDriverFilters = ({ tenantId, branchId, startDate, endDate }) => {
  const clauses = ['tenant_id = ?'];
  const params = [tenantId];

  if (branchId) {
    clauses.push('branch_id = ?');
    params.push(branchId);
  }

  if (startDate) {
    clauses.push('created_at >= ?');
    params.push(startDate);
  }

  if (endDate) {
    clauses.push('created_at <= ?');
    params.push(endDate);
  }

  return { where: clauses.join(' AND '), params };
};

const defaultOverview = () => ({
  sales: {
    total: 0,
    today: 0,
    discounts: 0,
    deliveryFees: 0,
    averageOrderValue: 0
  },
  orders: {
    count: 0,
    active: 0,
    cancelled: 0,
    byStatus: {}
  },
  payments: {
    byMethod: [],
    pending: 0
  },
  customers: {
    newToday: 0,
    returning: 0
  },
  topProducts: []
});

const loadOverviewMetrics = async (filters) => {
  try {
    const overview = defaultOverview();
    const { where, params } = buildOrderFilters(filters);

    const [totals] = await databaseManager.query(
      `SELECT
        COALESCE(SUM(o.total_amount), 0) AS total_sales,
        COALESCE(SUM(CASE WHEN DATE(o.created_at) = CURRENT_DATE THEN o.total_amount END), 0) AS sales_today,
        COALESCE(SUM(o.discount_amount), 0) AS discounts,
        COALESCE(SUM(o.delivery_fee), 0) AS delivery_fees,
        COUNT(*) AS order_count,
        COALESCE(SUM(CASE WHEN o.status IN ('preparing','ready','on_way') THEN 1 ELSE 0 END), 0) AS active_orders,
        COALESCE(SUM(CASE WHEN o.status = 'cancelled' THEN 1 ELSE 0 END), 0) AS cancelled_orders
      FROM orders o
      WHERE ${where}`,
      params
    );

    if (totals) {
      overview.sales.total = safeNumber(totals.total_sales);
      overview.sales.today = safeNumber(totals.sales_today);
      overview.sales.discounts = safeNumber(totals.discounts);
      overview.sales.deliveryFees = safeNumber(totals.delivery_fees);
      overview.sales.averageOrderValue = totals.order_count > 0
        ? safeNumber(totals.total_sales) / safeNumber(totals.order_count, 1)
        : 0;

      overview.orders.count = safeNumber(totals.order_count);
      overview.orders.active = safeNumber(totals.active_orders);
      overview.orders.cancelled = safeNumber(totals.cancelled_orders);
    }

    const statusRows = await databaseManager.query(
      `SELECT o.status, COUNT(*) AS count
       FROM orders o
       WHERE ${where}
       GROUP BY o.status`,
      params
    );

    overview.orders.byStatus = statusRows.reduce((acc, row) => {
      acc[row.status] = safeNumber(row.count);
      return acc;
    }, {});

    const paymentRows = await databaseManager.query(
      `SELECT o.payment_method AS method,
              COUNT(*) AS count,
              COALESCE(SUM(o.total_amount), 0) AS total
       FROM orders o
       WHERE ${where}
       GROUP BY o.payment_method
       ORDER BY total DESC`,
      params
    );

    overview.payments.byMethod = paymentRows.map((row) => ({
      method: row.method,
      count: safeNumber(row.count),
      total: safeNumber(row.total)
    }));

    const pendingPayments = await databaseManager.query(
      `SELECT COUNT(*) AS pending
       FROM orders o
       WHERE ${where}
         AND o.payment_status IN ('pending', 'failed')`,
      params
    );

    overview.payments.pending = pendingPayments.length > 0
      ? safeNumber(pendingPayments[0].pending)
      : 0;

    const customerRows = await databaseManager.query(
      `SELECT
          COALESCE(SUM(CASE WHEN DATE(o.created_at) = CURRENT_DATE THEN 1 ELSE 0 END), 0) AS new_today,
          COALESCE(SUM(CASE WHEN o.customer_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS identified_orders
       FROM orders o
       WHERE ${where}`,
      params
    );

    if (customerRows.length > 0) {
      overview.customers.newToday = safeNumber(customerRows[0].new_today);
      overview.customers.returning = Math.max(
        safeNumber(customerRows[0].identified_orders) - overview.customers.newToday,
        0
      );
    }

    const productRows = await databaseManager.query(
      `SELECT
          oi.product_name AS name,
          COALESCE(SUM(oi.quantity), 0) AS quantity,
          COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS revenue
       FROM order_items oi
       INNER JOIN orders o ON o.id = oi.order_id
       WHERE ${where}
       GROUP BY oi.product_id, oi.product_name
       ORDER BY revenue DESC
       LIMIT 5`,
      params
    );

    overview.topProducts = productRows.map((row) => ({
      name: row.name,
      quantity: safeNumber(row.quantity),
      revenue: safeNumber(row.revenue)
    }));

    return overview;
  } catch (error) {
    if (isMissingTableError(error)) {
      logger.warn('Admin overview tables missing', { context: 'loadOverviewMetrics' });
      return defaultOverview();
    }

    logger.error('Failed to load admin overview metrics', { error: error.message });
    throw error;
  }
};

const GRANULARITY_FORMATS = {
  hour: '%Y-%m-%d %H:00',
  day: '%Y-%m-%d',
  week: '%x-%v',
  month: '%Y-%m'
};

const loadOrderTrends = async ({ granularity = 'day', ...filters }) => {
  const format = GRANULARITY_FORMATS[granularity] || GRANULARITY_FORMATS.day;

  try {
    const { where, params } = buildOrderFilters(filters);

    const rows = await databaseManager.query(
      `SELECT
         DATE_FORMAT(o.created_at, '${format}') AS bucket,
         COUNT(*) AS order_count,
         COALESCE(SUM(o.total_amount), 0) AS total_sales,
         COALESCE(SUM(o.discount_amount), 0) AS discounts
       FROM orders o
       WHERE ${where}
       GROUP BY bucket
       ORDER BY bucket ASC`,
      params
    );

    return rows.map((row) => ({
      bucket: row.bucket,
      orders: safeNumber(row.order_count),
      sales: safeNumber(row.total_sales),
      discounts: safeNumber(row.discounts)
    }));
  } catch (error) {
    if (isMissingTableError(error)) {
      logger.warn('Admin trend tables missing', { context: 'loadOrderTrends' });
      return [];
    }

    logger.error('Failed to load order trends', { error: error.message });
    throw error;
  }
};

const loadDriverPerformance = async (filters) => {
  try {
    const { where, params } = buildDriverFilters(filters);

    const summaryRows = await databaseManager.query(
      `SELECT
         driver_id,
         COALESCE(SUM(CASE WHEN status = 'delivered' THEN 1 ELSE 0 END), 0) AS delivered,
         COALESCE(SUM(CASE WHEN status IN ('failed','cancelled') THEN 1 ELSE 0 END), 0) AS exceptions,
         COALESCE(AVG(TIMESTAMPDIFF(MINUTE, picked_at, delivered_at)), 0) AS avg_delivery_minutes,
         COALESCE(SUM(collected_amount), 0) AS collected_amount
       FROM driver_tasks
       WHERE ${where}
       GROUP BY driver_id
       ORDER BY delivered DESC
       LIMIT 10`,
      params
    );

    const settlementRows = await databaseManager.query(
      `SELECT
         driver_id,
         COALESCE(SUM(completed_assignments), 0) AS completed_assignments,
         COALESCE(SUM(collected_cash), 0) AS cash,
         COALESCE(SUM(collected_non_cash), 0) AS non_cash,
         COALESCE(SUM(pending_remittance), 0) AS pending_remittance
       FROM driver_settlements
       WHERE tenant_id = ?
       GROUP BY driver_id`,
      [filters.tenantId]
    );

    const settlementMap = settlementRows.reduce((acc, row) => {
      acc[row.driver_id] = row;
      return acc;
    }, {});

    return summaryRows.map((row) => {
      const settlement = settlementMap[row.driver_id] || {};
      return {
        driverId: row.driver_id,
        delivered: safeNumber(row.delivered),
        exceptions: safeNumber(row.exceptions),
        avgDeliveryMinutes: safeNumber(row.avg_delivery_minutes),
        collectedAmount: safeNumber(row.collected_amount),
        completedShifts: safeNumber(settlement.completed_assignments),
        cashCollected: safeNumber(settlement.cash),
        nonCashCollected: safeNumber(settlement.non_cash),
        pendingRemittance: safeNumber(settlement.pending_remittance)
      };
    });
  } catch (error) {
    if (isMissingTableError(error)) {
      logger.warn('Driver performance tables missing', { context: 'loadDriverPerformance' });
      return [];
    }

    logger.error('Failed to load driver performance metrics', { error: error.message });
    throw error;
  }
};

const loadReportPreview = async ({ type, ...filters }) => {
  if (type === 'sales') {
    const data = await loadOrderTrends({ granularity: 'day', ...filters });
    return { type, rows: data };
  }

  if (type === 'drivers') {
    const rows = await loadDriverPerformance(filters);
    return { type, rows };
  }

  if (type === 'orders') {
    const overview = await loadOverviewMetrics(filters);
    const total = safeNumber(overview.orders.count);
    const rows = Object.entries(overview.orders.byStatus).map(([status, count]) => ({
      status,
      count,
      percentage: total > 0 ? Number(((count / total) * 100).toFixed(2)) : 0
    }));

    return { type, rows, total };
  }

  const overview = await loadOverviewMetrics(filters);
  return { type: 'overview', rows: overview };
};

module.exports = {
  loadOverviewMetrics,
  loadOrderTrends,
  loadDriverPerformance,
  loadReportPreview
};
