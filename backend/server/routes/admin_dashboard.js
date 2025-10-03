const express = require('express');
const { authenticateToken, requireRole, validateTenant } = require('../../middleware/auth');
const { validate, schemas } = require('../../middleware/validation');
const { asyncHandler } = require('../../middleware/errorHandler');
const {
  loadOverviewMetrics,
  loadOrderTrends,
  loadDriverPerformance,
  loadReportPreview
} = require('../services/admin_dashboard_service');

const router = express.Router();

const DEFAULT_WIDGET_LAYOUT = [
  {
    id: 'sales-overview',
    title: 'Sales Overview',
    size: 'large',
    roles: ['admin', 'manager'],
    metrics: ['sales.total', 'sales.today', 'sales.averageOrderValue']
  },
  {
    id: 'active-orders',
    title: 'Active Orders',
    size: 'medium',
    roles: ['admin', 'manager'],
    metrics: ['orders.active', 'orders.byStatus.preparing', 'orders.byStatus.ready']
  },
  {
    id: 'top-products',
    title: 'Top Products',
    size: 'medium',
    roles: ['admin', 'manager'],
    metrics: ['topProducts']
  },
  {
    id: 'driver-performance',
    title: 'Driver Performance',
    size: 'large',
    roles: ['admin', 'manager'],
    metrics: ['driver.delivered', 'driver.avgDeliveryMinutes', 'driver.pendingRemittance']
  },
  {
    id: 'payments-mix',
    title: 'Payments Mix',
    size: 'small',
    roles: ['admin', 'manager'],
    metrics: ['payments.byMethod', 'payments.pending']
  }
];

const ROLE_PERMISSIONS = {
  admin: {
    widgets: ['sales-overview', 'active-orders', 'top-products', 'driver-performance', 'payments-mix'],
    reports: ['overview', 'sales', 'orders', 'drivers']
  },
  manager: {
    widgets: ['sales-overview', 'active-orders', 'top-products', 'driver-performance', 'payments-mix'],
    reports: ['overview', 'sales', 'orders']
  },
  cashier: {
    widgets: ['active-orders'],
    reports: []
  }
};

const resolveFilters = (req) => {
  const branchCandidate =
    req.query.branchId ?? req.headers['x-branch-id'] ?? req.user?.branchId ?? undefined;

  const branchId = branchCandidate !== undefined && branchCandidate !== null && branchCandidate !== ''
    ? Number(branchCandidate)
    : undefined;

  return {
    tenantId: req.tenant?.id || req.user?.tenantId,
    branchId: Number.isFinite(branchId) ? branchId : undefined,
    startDate: req.query.startDate,
    endDate: req.query.endDate
  };
};

router.use(authenticateToken);
router.use(requireRole('admin', 'manager'));
router.use(validateTenant);

router.get(
  '/overview',
  validate(schemas.adminDashboard.overviewQuery, 'query'),
  asyncHandler(async (req, res) => {
    const filters = resolveFilters(req);
    const data = await loadOverviewMetrics(filters);

    res.json({
      data,
      filters,
      generatedAt: new Date().toISOString()
    });
  })
);

router.get(
  '/orders/trends',
  validate(schemas.adminDashboard.trendQuery, 'query'),
  asyncHandler(async (req, res) => {
    const { granularity } = req.query;
    const filters = resolveFilters(req);
    const data = await loadOrderTrends({ granularity, ...filters });

    res.json({
      data,
      filters: { ...filters, granularity },
      generatedAt: new Date().toISOString()
    });
  })
);

router.get(
  '/drivers/performance',
  validate(schemas.adminDashboard.driverQuery, 'query'),
  asyncHandler(async (req, res) => {
    const filters = resolveFilters(req);
    const data = await loadDriverPerformance(filters);

    res.json({
      data,
      filters,
      generatedAt: new Date().toISOString()
    });
  })
);

router.get(
  '/reports/preview',
  validate(schemas.adminDashboard.reportQuery, 'query'),
  asyncHandler(async (req, res) => {
    const filters = resolveFilters(req);
    const report = await loadReportPreview({ type: req.query.type, ...filters });

    res.json({
      report,
      filters,
      generatedAt: new Date().toISOString()
    });
  })
);

router.get('/widgets/defaults', (req, res) => {
  res.json({
    widgets: DEFAULT_WIDGET_LAYOUT,
    roles: ROLE_PERMISSIONS,
    generatedAt: new Date().toISOString()
  });
});

module.exports = router;
