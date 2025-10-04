const express = require('express');
const router = express.Router();

const { authenticateToken, requireRole } = require('../../middleware/auth');
const { asyncHandler } = require('../../middleware/errorHandler');
const metrics = require('../../config/metrics');
const systemHealthService = require('../services/system_health_service');
const backupService = require('../services/backup_service');

const adminOrManager = requireRole('admin', 'manager');
const adminOnly = requireRole('admin');

router.use(authenticateToken);
router.use(adminOrManager);

router.get('/health', asyncHandler(async (req, res) => {
  const health = await systemHealthService.getSystemHealth();
  res.json(health);
}));

router.get('/alerts', asyncHandler(async (req, res) => {
  const alerts = systemHealthService.getOperationalAlerts();
  res.json(alerts);
}));

router.get('/metrics', asyncHandler(async (req, res) => {
  if (!metrics.metricsEnabled) {
    return res.status(404).json({
      enabled: false,
      message: 'Metrics collection is disabled. Set ENABLE_METRICS=true to enable.'
    });
  }

  res.json(metrics.getRequestsSnapshot());
}));

router.get('/metrics/prometheus', asyncHandler(async (req, res) => {
  if (!metrics.metricsEnabled) {
    return res.status(404).type('text/plain').send('# Metrics disabled');
  }

  const snapshot = metrics.getRequestsSnapshot();
  const lines = [
    '# HELP nokta_http_requests_total Total HTTP requests processed',
    '# TYPE nokta_http_requests_total counter',
    `nokta_http_requests_total ${snapshot.totalRequests}`,
    '# HELP nokta_http_errors_total Total HTTP errors (status >= 400)',
    '# TYPE nokta_http_errors_total counter',
    `nokta_http_errors_total ${snapshot.totalErrors}`,
    '# HELP nokta_http_error_rate Error rate for HTTP requests',
    '# TYPE nokta_http_error_rate gauge',
    `nokta_http_error_rate ${snapshot.errorRate}`,
  ];

  Object.entries(snapshot.requestsByStatus).forEach(([statusCode, count]) => {
    lines.push('# TYPE nokta_http_status_total counter');
    lines.push(
      `nokta_http_status_total{code="${statusCode}"} ${count}`
    );
  });

  Object.entries(snapshot.routeStats).forEach(([routeKey, stats]) => {
    lines.push('# TYPE nokta_route_duration_seconds gauge');
    lines.push(
      `nokta_route_duration_seconds{route="${routeKey}",stat="avg"} ${stats.avgDuration / 1000}`
    );
    lines.push(
      `nokta_route_duration_seconds{route="${routeKey}",stat="max"} ${stats.maxDuration / 1000}`
    );
  });

  res.type('text/plain').send(`${lines.join('\n')}\n`);
}));

router.get('/metrics/runtime', (req, res) => {
  res.json(systemHealthService.getRuntimeMetrics());
});

router.get('/backups/plan', adminOnly, (req, res) => {
  res.json(backupService.getBackupPlan());
});

router.get('/backups', adminOnly, asyncHandler(async (req, res) => {
  const backups = await backupService.listBackups();
  res.json(backups);
}));

router.post('/backups/run', adminOnly, asyncHandler(async (req, res) => {
  const dryRun = req.query.dryRun === 'true';
  const result = await backupService.createDatabaseBackup({
    initiatedBy: req.user.id,
    dryRun
  });

  res.status(result.executed ? 201 : 202).json(result);
}));

router.post('/backups/purge', adminOnly, asyncHandler(async (req, res) => {
  const result = await backupService.purgeExpiredBackups();
  res.json(result);
}));

module.exports = router;
