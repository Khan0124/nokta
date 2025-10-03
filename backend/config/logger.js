const winston = require('winston');
const DailyRotateFile = require('winston-daily-rotate-file');
const path = require('path');
const config = require('./config');

// Create logs directory if it doesn't exist
const fs = require('fs');
const logsDir = path.dirname(config.logging.file);
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

// Define log format
const logFormat = winston.format.combine(
  winston.format.timestamp({
    format: 'YYYY-MM-DD HH:mm:ss'
  }),
  winston.format.errors({ stack: true }),
  winston.format.json(),
  winston.format.printf(({ timestamp, level, message, ...meta }) => {
    let log = `${timestamp} [${level.toUpperCase()}]: ${message}`;
    
    if (Object.keys(meta).length > 0) {
      log += ` ${JSON.stringify(meta)}`;
    }
    
    return log;
  })
);

// Define console format for development
const consoleFormat = winston.format.combine(
  winston.format.colorize(),
  winston.format.timestamp({
    format: 'HH:mm:ss'
  }),
  winston.format.printf(({ timestamp, level, message, ...meta }) => {
    let log = `${timestamp} [${level}]: ${message}`;
    
    if (Object.keys(meta).length > 0) {
      log += ` ${JSON.stringify(meta)}`;
    }
    
    return log;
  })
);

// Create logger instance
const logger = winston.createLogger({
  level: config.logging.level,
  format: logFormat,
  defaultMeta: {
    service: 'nokta-pos-backend',
    version: '1.0.0'
  },
  transports: [
    // File transport for all logs
    new DailyRotateFile({
      filename: path.join(logsDir, 'app-%DATE%.log'),
      datePattern: 'YYYY-MM-DD',
      maxSize: config.logging.maxSize,
      maxFiles: config.logging.maxFiles,
      level: 'info'
    }),
    
    // File transport for error logs only
    new DailyRotateFile({
      filename: path.join(logsDir, 'error-%DATE%.log'),
      datePattern: 'YYYY-MM-DD',
      maxSize: config.logging.maxSize,
      maxFiles: config.logging.maxFiles,
      level: 'error'
    })
  ]
});

// Add console transport in development
if (config.server.env === 'development') {
  logger.add(new winston.transports.Console({
    format: consoleFormat,
    level: 'debug'
  }));
}

// Dedicated audit logger for compliance-sensitive events
const auditLogger = winston.createLogger({
  level: 'info',
  format: logFormat,
  defaultMeta: {
    service: 'nokta-pos-audit',
    version: '1.0.0'
  },
  transports: [
    new DailyRotateFile({
      filename: path.join(logsDir, 'audit-%DATE%.log'),
      datePattern: 'YYYY-MM-DD',
      maxSize: config.logging.maxSize,
      maxFiles: '90d',
      level: 'info'
    })
  ]
});

if (config.server.env === 'development') {
  auditLogger.add(new winston.transports.Console({
    format: consoleFormat,
    level: 'info'
  }));
}

// Add request logging middleware
const requestLogger = (req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - start;
    const logData = {
      method: req.method,
      url: req.originalUrl,
      status: res.statusCode,
      duration: `${duration}ms`,
      ip: req.ip || req.connection.remoteAddress,
      userAgent: req.get('User-Agent'),
      userId: req.user?.id || 'anonymous'
    };
    
    if (res.statusCode >= 400) {
      logger.warn('HTTP Request', logData);
    } else {
      logger.info('HTTP Request', logData);
    }
  });
  
  next();
};

// Add error logging middleware
const errorLogger = (err, req, res, next) => {
  logger.error('Unhandled Error', {
    error: err.message,
    stack: err.stack,
    method: req.method,
    url: req.originalUrl,
    ip: req.ip || req.connection.remoteAddress,
    userId: req.user?.id || 'anonymous'
  });
  
  next(err);
};

// Add database query logging
const queryLogger = (sql, params, duration) => {
  logger.debug('Database Query', {
    sql: sql.substring(0, 200) + (sql.length > 200 ? '...' : ''),
    params: params,
    duration: `${duration}ms`
  });
};

// Add security event logging
const securityLogger = {
  loginAttempt: (username, ip, success, reason = null) => {
    logger.info('Login Attempt', {
      username,
      ip,
      success,
      reason
    });
  },
  
  failedLogin: (username, ip, reason) => {
    logger.warn('Failed Login', {
      username,
      ip,
      reason
    });
  },
  
  suspiciousActivity: (userId, ip, activity, details) => {
    logger.warn('Suspicious Activity', {
      userId,
      ip,
      activity,
      details
    });
  },
  
  permissionDenied: (userId, resource, action, ip) => {
    logger.warn('Permission Denied', {
      userId,
      resource,
      action,
      ip
    });
  }
};

// Add performance logging
const performanceLogger = {
  slowQuery: (sql, duration, threshold = 1000) => {
    if (duration > threshold) {
      logger.warn('Slow Database Query', {
        sql: sql.substring(0, 200) + (sql.length > 200 ? '...' : ''),
        duration: `${duration}ms`,
        threshold: `${threshold}ms`
      });
    }
  },
  
  apiResponseTime: (endpoint, duration, threshold = 500) => {
    if (duration > threshold) {
      logger.warn('Slow API Response', {
        endpoint,
        duration: `${duration}ms`,
        threshold: `${threshold}ms`
      });
    }
  }
};

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully');
  logger.end();
});

process.on('SIGINT', () => {
  logger.info('SIGINT received, shutting down gracefully');
  logger.end();
});

module.exports = {
  logger,
  auditLogger,
  requestLogger,
  errorLogger,
  queryLogger,
  securityLogger,
  performanceLogger
};
