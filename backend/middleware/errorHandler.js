const { logger } = require('../config/logger');

// Custom error classes
class AppError extends Error {
  constructor(message, statusCode, code = null, details = null) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

class ValidationError extends AppError {
  constructor(message, details = null) {
    super(message, 400, 'VALIDATION_ERROR', details);
  }
}

class AuthenticationError extends AppError {
  constructor(message = 'Authentication failed') {
    super(message, 401, 'AUTHENTICATION_ERROR');
  }
}

class AuthorizationError extends AppError {
  constructor(message = 'Insufficient permissions') {
    super(message, 403, 'AUTHORIZATION_ERROR');
  }
}

class NotFoundError extends AppError {
  constructor(resource = 'Resource') {
    super(`${resource} not found`, 404, 'NOT_FOUND_ERROR');
  }
}

class ConflictError extends AppError {
  constructor(message = 'Resource conflict') {
    super(message, 409, 'CONFLICT_ERROR');
  }
}

class RateLimitError extends AppError {
  constructor(message = 'Rate limit exceeded') {
    super(message, 429, 'RATE_LIMIT_ERROR');
  }
}

class DatabaseError extends AppError {
  constructor(message = 'Database operation failed', details = null) {
    super(message, 500, 'DATABASE_ERROR', details);
  }
}

class ExternalServiceError extends AppError {
  constructor(message = 'External service error', details = null) {
    super(message, 502, 'EXTERNAL_SERVICE_ERROR', details);
  }
}

// Error handler middleware
const errorHandler = (err, req, res, next) => {
  let error = err;

  // If it's not our custom error, create a generic one
  if (!error.isOperational) {
    error = new AppError(
      'Internal server error',
      500,
      'INTERNAL_SERVER_ERROR'
    );
  }

  // Log the error
  logger.error('Unhandled Error', {
    error: {
      message: error.message,
      stack: error.stack,
      code: error.code,
      details: error.details
    },
    request: {
      method: req.method,
      url: req.originalUrl,
      ip: req.ip || req.connection.remoteAddress,
      userAgent: req.get('User-Agent'),
      userId: req.user?.id || 'anonymous',
      body: req.body,
      query: req.query,
      params: req.params
    },
    timestamp: new Date().toISOString()
  });

  // Don't leak error details in production
  const isDevelopment = process.env.NODE_ENV === 'development';
  
  const errorResponse = {
    error: error.message,
    code: error.code,
    timestamp: new Date().toISOString(),
    path: req.originalUrl,
    method: req.method
  };

  // Add details in development only
  if (isDevelopment && error.details) {
    errorResponse.details = error.details;
  }

  // Add stack trace in development only
  if (isDevelopment && error.stack) {
    errorResponse.stack = error.stack;
  }

  // Handle specific error types
  if (error.code === 'VALIDATION_ERROR') {
    return res.status(error.statusCode).json({
      ...errorResponse,
      type: 'Validation Error',
      suggestions: getValidationSuggestions(error.details)
    });
  }

  if (error.code === 'DATABASE_ERROR') {
    // Don't expose database details in production
    if (!isDevelopment) {
      errorResponse.error = 'Database operation failed';
      delete errorResponse.details;
    }
  }

  // Handle JWT errors
  if (error.name === 'JsonWebTokenError') {
    error = new AuthenticationError('Invalid token');
  }

  if (error.name === 'TokenExpiredError') {
    error = new AuthenticationError('Token expired');
  }

  // Handle database constraint errors
  if (error.code === 'ER_DUP_ENTRY') {
    const field = error.sqlMessage.match(/Duplicate entry '(.+)' for key '(.+)'/);
    if (field) {
      error = new ConflictError(`${field[2]} already exists`);
    }
  }

  if (error.code === 'ER_NO_REFERENCED_ROW_2') {
    error = new ValidationError('Referenced record does not exist');
  }

  // Handle file upload errors
  if (error.code === 'LIMIT_FILE_SIZE') {
    error = new ValidationError('File size too large');
  }

  if (error.code === 'LIMIT_UNEXPECTED_FILE') {
    error = new ValidationError('Unexpected file field');
  }

  // Send error response
  res.status(error.statusCode || 500).json(errorResponse);
};

// Async error wrapper
const asyncHandler = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

// 404 handler
const notFoundHandler = (req, res) => {
  const error = new NotFoundError('Route');
  res.status(404).json({
    error: error.message,
    code: error.code,
    timestamp: new Date().toISOString(),
    path: req.originalUrl,
    method: req.method,
    suggestions: [
      'Check the URL for typos',
      'Verify the HTTP method (GET, POST, PUT, DELETE)',
      'Ensure the endpoint exists in the API documentation'
    ]
  });
};

// Validation suggestions helper
const getValidationSuggestions = (details) => {
  const suggestions = [];
  
  if (!details) return suggestions;

  details.forEach(detail => {
    switch (detail.type) {
      case 'string.email':
        suggestions.push(`Ensure ${detail.field} is a valid email address`);
        break;
      case 'string.min':
        suggestions.push(`Ensure ${detail.field} is at least ${detail.context.limit} characters long`);
        break;
      case 'string.max':
        suggestions.push(`Ensure ${detail.field} is no more than ${detail.context.limit} characters long`);
        break;
      case 'string.pattern.base':
        suggestions.push(`Ensure ${detail.field} matches the required format`);
        break;
      case 'number.base':
        suggestions.push(`Ensure ${detail.field} is a valid number`);
        break;
      case 'number.min':
        suggestions.push(`Ensure ${detail.field} is at least ${detail.context.limit}`);
        break;
      case 'number.max':
        suggestions.push(`Ensure ${detail.field} is no more than ${detail.context.limit}`);
        break;
      case 'any.required':
        suggestions.push(`Ensure ${detail.field} is provided`);
        break;
      case 'any.allowOnly':
        suggestions.push(`Ensure ${detail.field} is one of: ${detail.context.valids.join(', ')}`);
        break;
      default:
        suggestions.push(`Check the format of ${detail.field}`);
    }
  });

  return suggestions;
};

// Database error handler
const handleDatabaseError = (error, operation = 'Database operation') => {
  logger.error('Database Error', {
    operation,
    error: {
      code: error.code,
      errno: error.errno,
      sqlState: error.sqlState,
      sqlMessage: error.sqlMessage,
      message: error.message
    }
  });

  // Map common database errors to user-friendly messages
  switch (error.code) {
    case 'ER_DUP_ENTRY':
      throw new ConflictError('Record already exists');
    case 'ER_NO_REFERENCED_ROW_2':
      throw new ValidationError('Referenced record does not exist');
    case 'ER_ROW_IS_REFERENCED_2':
      throw new ConflictError('Cannot delete record - it is referenced by other records');
    case 'ER_DATA_TOO_LONG':
      throw new ValidationError('Data too long for field');
    case 'ER_BAD_NULL_ERROR':
      throw new ValidationError('Required field cannot be null');
    case 'ER_WRONG_VALUE_COUNT':
      throw new ValidationError('Incorrect number of values');
    case 'ER_ACCESS_DENIED_ERROR':
      throw new AuthenticationError('Database access denied');
    case 'ER_CONNECTION_ERROR':
      throw new DatabaseError('Database connection failed');
    case 'ER_QUERY_INTERRUPTED':
      throw new DatabaseError('Database query was interrupted');
    default:
      throw new DatabaseError(`${operation} failed`, {
        code: error.code,
        message: error.message
      });
  }
};

// External service error handler
const handleExternalServiceError = (error, service = 'External service') => {
  logger.error('External Service Error', {
    service,
    error: {
      message: error.message,
      code: error.code,
      statusCode: error.statusCode,
      response: error.response?.data
    }
  });

  if (error.statusCode === 401) {
    throw new AuthenticationError(`${service} authentication failed`);
  } else if (error.statusCode === 403) {
    throw new AuthorizationError(`${service} access denied`);
  } else if (error.statusCode === 404) {
    throw new NotFoundError(`${service} resource`);
  } else if (error.statusCode === 429) {
    throw new RateLimitError(`${service} rate limit exceeded`);
  } else if (error.statusCode >= 500) {
    throw new ExternalServiceError(`${service} is temporarily unavailable`);
  } else {
    throw new ExternalServiceError(`${service} error: ${error.message}`);
  }
};

// Graceful shutdown handler
const gracefulShutdown = (server, connections) => {
  return () => {
    logger.info('Received shutdown signal, starting graceful shutdown...');
    
    server.close(() => {
      logger.info('HTTP server closed');
      
      // Close database connections
      if (connections.database) {
        connections.database.close()
          .then(() => logger.info('Database connections closed'))
          .catch(err => logger.error('Error closing database connections:', err))
          .finally(() => {
            // Close Redis connections
            if (connections.redis) {
              connections.redis.close()
                .then(() => logger.info('Redis connections closed'))
                .catch(err => logger.error('Error closing Redis connections:', err))
                .finally(() => {
                  logger.info('Graceful shutdown completed');
                  process.exit(0);
                });
            } else {
              logger.info('Graceful shutdown completed');
              process.exit(0);
            }
          });
      } else {
        logger.info('Graceful shutdown completed');
        process.exit(0);
      }
    });

    // Force close after 30 seconds
    setTimeout(() => {
      logger.error('Forced shutdown after timeout');
      process.exit(1);
    }, 30000);
  };
};

module.exports = {
  AppError,
  ValidationError,
  AuthenticationError,
  AuthorizationError,
  NotFoundError,
  ConflictError,
  RateLimitError,
  DatabaseError,
  ExternalServiceError,
  errorHandler,
  asyncHandler,
  notFoundHandler,
  handleDatabaseError,
  handleExternalServiceError,
  gracefulShutdown
};
