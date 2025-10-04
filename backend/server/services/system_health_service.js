const os = require('os');
const config = require('../../config/config');
const databaseManager = require('../../config/database');
const redisManager = require('../../config/redis');
const metrics = require('../../config/metrics');

const normalizeHealth = (result) => {
  if (!result) {
    return { status: 'unknown', timestamp: new Date().toISOString() };
  }

  return {
    ...result,
    timestamp: result.timestamp || new Date().toISOString()
  };
};

const getSystemHealth = async () => {
  const [dbResult, redisResult] = await Promise.allSettled([
    databaseManager.healthCheck(),
    redisManager.healthCheck()
  ]);

  const database = dbResult.status === 'fulfilled'
    ? normalizeHealth(dbResult.value)
    : {
        status: 'unhealthy',
        error: dbResult.reason?.message || 'Database health check failed',
        timestamp: new Date().toISOString()
      };

  const cache = redisResult.status === 'fulfilled'
    ? normalizeHealth(redisResult.value)
    : {
        status: 'unhealthy',
        error: redisResult.reason?.message || 'Cache health check failed',
        timestamp: new Date().toISOString()
      };

  const components = [database.status, cache.status];
  const status = components.every(s => s === 'healthy') ? 'healthy' : 'degraded';

  return {
    status,
    timestamp: new Date().toISOString(),
    service: {
      version: '1.0.0',
      environment: config.server.env,
      uptimeSeconds: Number(process.uptime().toFixed(0))
    },
    database,
    cache
  };
};

const getOperationalAlerts = () => {
  if (!metrics.metricsEnabled) {
    return {
      enabled: false,
      alerts: [],
      generatedAt: new Date().toISOString()
    };
  }

  const alerts = [];
  const snapshot = metrics.getRequestsSnapshot();

  if (snapshot.totalRequests >= Math.max(25, config.monitoring.recentSampleSize) &&
      snapshot.errorRate > config.monitoring.errorRateThreshold) {
    alerts.push({
      type: 'error-rate',
      severity: 'high',
      message: `API error rate ${snapshot.errorRate * 100}% exceeded threshold of ${config.monitoring.errorRateThreshold * 100}%`,
      errorRate: snapshot.errorRate,
      threshold: config.monitoring.errorRateThreshold
    });
  }

  Object.entries(snapshot.routeStats).forEach(([route, stats]) => {
    if (stats.maxDuration > config.monitoring.slowRequestThresholdMs) {
      alerts.push({
        type: 'slow-route',
        severity: 'medium',
        route,
        maxDuration: stats.maxDuration,
        thresholdMs: config.monitoring.slowRequestThresholdMs,
        lastStatus: stats.lastStatus,
        lastSeen: stats.lastSeen
      });
    }
  });

  const memoryUsage = process.memoryUsage();
  const rssMb = memoryUsage.rss / (1024 * 1024);
  const totalMemMb = os.totalmem() / (1024 * 1024);
  const usagePercent = Number(((rssMb / totalMemMb) * 100).toFixed(2));

  if (usagePercent > 80) {
    alerts.push({
      type: 'memory-pressure',
      severity: 'medium',
      rssMb: Number(rssMb.toFixed(2)),
      totalMb: Number(totalMemMb.toFixed(2)),
      usagePercent
    });
  }

  return {
    enabled: true,
    generatedAt: new Date().toISOString(),
    alerts
  };
};

const getRuntimeMetrics = () => {
  const runtime = metrics.getRuntimeMetrics();
  const cpus = os.cpus();

  return {
    service: {
      version: '1.0.0',
      environment: config.server.env
    },
    runtime,
    resources: {
      cpuCount: cpus.length,
      platform: process.platform,
      nodeVersion: process.version
    }
  };
};

module.exports = {
  getSystemHealth,
  getOperationalAlerts,
  getRuntimeMetrics
};
