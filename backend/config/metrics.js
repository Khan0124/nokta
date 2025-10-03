const os = require('os');
const { monitorEventLoopDelay } = require('perf_hooks');
const config = require('./config');
const { performanceLogger } = require('./logger');

const metricsEnabled = !!config.monitoring.enabled;

const metricsStore = {
  startedAt: Date.now(),
  totalRequests: 0,
  totalErrors: 0,
  requestsByStatus: {},
  routeStats: {},
  recent: []
};

let eventLoopMonitor = null;
let eventLoopSupported = false;

if (metricsEnabled && typeof monitorEventLoopDelay === 'function') {
  eventLoopMonitor = monitorEventLoopDelay({ resolution: 20 });
  eventLoopMonitor.enable();
  eventLoopSupported = true;
}

const recordRecentRequest = (entry) => {
  metricsStore.recent.unshift(entry);
  if (metricsStore.recent.length > config.monitoring.recentSampleSize) {
    metricsStore.recent.pop();
  }
};

const requestMetricsMiddleware = (req, res, next) => {
  if (!metricsEnabled) {
    return next();
  }

  const start = process.hrtime.bigint();

  res.on('finish', () => {
    const durationMs = Number(process.hrtime.bigint() - start) / 1e6;
    const route = req.route?.path || req.originalUrl.split('?')[0];
    const method = req.method.toUpperCase();
    const status = res.statusCode;
    const key = `${method} ${route}`;

    metricsStore.totalRequests += 1;
    if (status >= 400) {
      metricsStore.totalErrors += 1;
    }

    metricsStore.requestsByStatus[status] = (metricsStore.requestsByStatus[status] || 0) + 1;

    const current = metricsStore.routeStats[key] || {
      count: 0,
      avgDuration: 0,
      maxDuration: 0,
      lastStatus: status,
      lastSeen: new Date().toISOString()
    };

    current.count += 1;
    current.avgDuration = current.avgDuration + ((durationMs - current.avgDuration) / current.count);
    current.maxDuration = Math.max(current.maxDuration, durationMs);
    current.lastStatus = status;
    current.lastSeen = new Date().toISOString();

    metricsStore.routeStats[key] = current;

    recordRecentRequest({
      method,
      route,
      status,
      durationMs: Number(durationMs.toFixed(2)),
      timestamp: current.lastSeen
    });

    performanceLogger.apiResponseTime(key, durationMs, config.monitoring.slowRequestThresholdMs);
  });

  next();
};

const getRequestsSnapshot = () => {
  const errorRate = metricsStore.totalRequests === 0
    ? 0
    : Number((metricsStore.totalErrors / metricsStore.totalRequests).toFixed(4));

  const requestsByStatus = Object.entries(metricsStore.requestsByStatus)
    .reduce((acc, [code, count]) => {
      acc[code] = count;
      return acc;
    }, {});

  const routeStats = Object.entries(metricsStore.routeStats)
    .reduce((acc, [routeKey, stats]) => {
      acc[routeKey] = {
        count: stats.count,
        avgDuration: Number(stats.avgDuration.toFixed(2)),
        maxDuration: Number(stats.maxDuration.toFixed(2)),
        lastStatus: stats.lastStatus,
        lastSeen: stats.lastSeen
      };
      return acc;
    }, {});

  return {
    enabled: metricsEnabled,
    startedAt: new Date(metricsStore.startedAt).toISOString(),
    totalRequests: metricsStore.totalRequests,
    totalErrors: metricsStore.totalErrors,
    errorRate,
    requestsByStatus,
    routeStats,
    recent: metricsStore.recent.slice(0)
  };
};

const getRuntimeMetrics = () => {
  const memoryUsage = process.memoryUsage();
  const cpuLoad = os.loadavg();

  const memorySummary = Object.entries(memoryUsage).reduce((acc, [key, value]) => {
    acc[key] = Number((value / (1024 * 1024)).toFixed(2));
    return acc;
  }, {});

  let eventLoop = { enabled: false };

  if (metricsEnabled && eventLoopSupported && eventLoopMonitor) {
    eventLoop = {
      enabled: true,
      min: Number((eventLoopMonitor.min / 1e6).toFixed(2)),
      max: Number((eventLoopMonitor.max / 1e6).toFixed(2)),
      mean: Number((eventLoopMonitor.mean / 1e6).toFixed(2)),
      stddev: Number((eventLoopMonitor.stddev / 1e6).toFixed(2))
    };
  }

  return {
    enabled: metricsEnabled,
    uptimeSeconds: Number(process.uptime().toFixed(0)),
    processId: process.pid,
    memoryMb: memorySummary,
    cpuLoad: {
      '1m': Number(cpuLoad[0].toFixed(2)),
      '5m': Number(cpuLoad[1].toFixed(2)),
      '15m': Number(cpuLoad[2].toFixed(2))
    },
    eventLoop
  };
};

module.exports = {
  metricsEnabled,
  requestMetricsMiddleware,
  getRequestsSnapshot,
  getRuntimeMetrics
};
