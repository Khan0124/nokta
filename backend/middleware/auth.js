const jwt = require('jsonwebtoken');
const config = require('../config/config');
const { securityLogger } = require('../config/logger');
const redisManager = require('../config/redis');

// JWT Token validation middleware
const authenticateToken = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
      securityLogger.permissionDenied(null, 'API', 'No token provided', req.ip);
      return res.status(401).json({ 
        error: 'Access token required',
        code: 'TOKEN_MISSING'
      });
    }

    // Check if token is blacklisted
    const isBlacklisted = await redisManager.exists(`blacklist:${token}`);
    if (isBlacklisted) {
      securityLogger.permissionDenied(null, 'API', 'Token blacklisted', req.ip);
      return res.status(401).json({ 
        error: 'Token has been revoked',
        code: 'TOKEN_REVOKED'
      });
    }

    // Verify JWT token
    jwt.verify(token, config.jwt.secret, {
      issuer: config.jwt.issuer,
      audience: config.jwt.audience
    }, async (err, decoded) => {
      if (err) {
        let errorCode = 'TOKEN_INVALID';
        let errorMessage = 'Invalid token';
        
        if (err.name === 'TokenExpiredError') {
          errorCode = 'TOKEN_EXPIRED';
          errorMessage = 'Token has expired';
        } else if (err.name === 'JsonWebTokenError') {
          errorCode = 'TOKEN_MALFORMED';
          errorMessage = 'Token is malformed';
        }
        
        securityLogger.permissionDenied(null, 'API', errorMessage, req.ip);
        return res.status(401).json({ 
          error: errorMessage,
          code: errorCode
        });
      }

      // Check if user session exists in Redis
      const sessionKey = `session:${decoded.id}`;
      const session = await redisManager.get(sessionKey);
      
      if (!session) {
        securityLogger.permissionDenied(decoded.id, 'API', 'Session not found', req.ip);
        return res.status(401).json({ 
          error: 'Session expired',
          code: 'SESSION_EXPIRED'
        });
      }

      // Check if token matches session token
      if (session.token !== token) {
        securityLogger.permissionDenied(decoded.id, 'API', 'Token mismatch', req.ip);
        return res.status(401).json({ 
          error: 'Invalid session',
          code: 'SESSION_INVALID'
        });
      }

      // Add user info to request
      req.user = {
        id: decoded.id,
        username: decoded.username,
        email: decoded.email,
        role: decoded.role,
        tenantId: decoded.tenantId,
        branchId: decoded.branchId,
        permissions: decoded.permissions || []
      };

      // Log successful authentication
      securityLogger.loginAttempt(decoded.username, req.ip, true);
      
      next();
    });
  } catch (error) {
    securityLogger.permissionDenied(null, 'API', 'Authentication error', req.ip);
    return res.status(500).json({ 
      error: 'Authentication failed',
      code: 'AUTH_ERROR'
    });
  }
};

// Role-based access control middleware
const requireRole = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ 
        error: 'Authentication required',
        code: 'AUTH_REQUIRED'
      });
    }

    if (!roles.includes(req.user.role)) {
      securityLogger.permissionDenied(req.user.id, 'API', `Role ${req.user.role} not allowed`, req.ip);
      return res.status(403).json({ 
        error: 'Insufficient permissions',
        code: 'INSUFFICIENT_PERMISSIONS',
        required: roles,
        current: req.user.role
      });
    }

    next();
  };
};

// Permission-based access control middleware
const requirePermission = (...permissions) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ 
        error: 'Authentication required',
        code: 'AUTH_REQUIRED'
      });
    }

    const userPermissions = req.user.permissions || [];
    const hasPermission = permissions.every(permission => 
      userPermissions.includes(permission)
    );

    if (!hasPermission) {
      securityLogger.permissionDenied(req.user.id, 'API', `Permission denied: ${permissions.join(', ')}`, req.ip);
      return res.status(403).json({ 
        error: 'Insufficient permissions',
        code: 'INSUFFICIENT_PERMISSIONS',
        required: permissions,
        current: userPermissions
      });
    }

    next();
  };
};

// Tenant validation middleware
const validateTenant = async (req, res, next) => {
  try {
    const tenantId = req.headers['x-tenant-id'] || req.user?.tenantId;
    
    if (!tenantId) {
      return res.status(400).json({ 
        error: 'Tenant ID required',
        code: 'TENANT_ID_MISSING'
      });
    }

    // Check tenant in cache first
    const cacheKey = `tenant:${tenantId}`;
    let tenant = await redisManager.get(cacheKey);
    
    if (!tenant) {
      // If not in cache, fetch from database
      const db = require('../config/database');
      const result = await db.findOne('tenants', { id: tenantId, status: 'active' });
      
      if (!result) {
        return res.status(404).json({ 
          error: 'Tenant not found or inactive',
          code: 'TENANT_NOT_FOUND'
        });
      }
      
      // Cache tenant info for 1 hour
      await redisManager.setEx(cacheKey, result, 3600);
      tenant = result;
    }

    req.tenant = tenant;
    next();
  } catch (error) {
    return res.status(500).json({ 
      error: 'Tenant validation failed',
      code: 'TENANT_VALIDATION_ERROR'
    });
  }
};

// Branch validation middleware
const validateBranch = async (req, res, next) => {
  try {
    const branchId = req.headers['x-branch-id'] || req.user?.branchId;
    
    if (!branchId) {
      return res.status(400).json({ 
        error: 'Branch ID required',
        code: 'BRANCH_ID_MISSING'
      });
    }

    // Check if user has access to this branch
    if (req.user && req.user.role !== 'admin' && req.user.branchId !== branchId) {
      securityLogger.permissionDenied(req.user.id, 'BRANCH', `Access to branch ${branchId} denied`, req.ip);
      return res.status(403).json({ 
        error: 'Access to branch denied',
        code: 'BRANCH_ACCESS_DENIED'
      });
    }

    // Check branch in cache first
    const cacheKey = `branch:${branchId}`;
    let branch = await redisManager.get(cacheKey);
    
    if (!branch) {
      // If not in cache, fetch from database
      const db = require('../config/database');
      const result = await db.findOne('branches', { 
        id: branchId, 
        tenant_id: req.user?.tenantId || req.tenant?.id,
        is_active: 1
      });
      
      if (!result) {
        return res.status(404).json({ 
          error: 'Branch not found or inactive',
          code: 'BRANCH_NOT_FOUND'
        });
      }
      
      // Cache branch info for 1 hour
      await redisManager.setEx(cacheKey, result, 3600);
      branch = result;
    }

    req.branch = branch;
    next();
  } catch (error) {
    return res.status(500).json({ 
      error: 'Branch validation failed',
      code: 'BRANCH_VALIDATION_ERROR'
    });
  }
};

// Rate limiting middleware for specific endpoints
const createRateLimiter = (windowMs, maxRequests, keyGenerator = null) => {
  const rateLimit = require('express-rate-limit');
  
  return rateLimit({
    windowMs,
    max: maxRequests,
    keyGenerator: keyGenerator || ((req) => {
      // Use IP address by default, or user ID if authenticated
      return req.user ? req.user.id : req.ip;
    }),
    message: {
      error: 'Too many requests',
      code: 'RATE_LIMIT_EXCEEDED',
      retryAfter: Math.ceil(windowMs / 1000)
    },
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res) => {
      securityLogger.suspiciousActivity(
        req.user?.id || 'anonymous',
        req.ip,
        'Rate limit exceeded',
        { endpoint: req.originalUrl, limit: maxRequests }
      );
      
      res.status(429).json({
        error: 'Too many requests',
        code: 'RATE_LIMIT_EXCEEDED',
        retryAfter: Math.ceil(windowMs / 1000)
      });
    }
  });
};

// Session management middleware
const refreshSession = async (req, res, next) => {
  try {
    if (req.user) {
      // Extend session in Redis
      const sessionKey = `session:${req.user.id}`;
      const session = await redisManager.get(sessionKey);
      
      if (session) {
        // Extend session by 1 hour
        await redisManager.expire(sessionKey, 3600);
      }
    }
    next();
  } catch (error) {
    // Don't fail the request if session refresh fails
    next();
  }
};

// Logout middleware
const logout = async (req, res) => {
  try {
    if (req.user) {
      const token = req.headers['authorization']?.split(' ')[1];
      
      if (token) {
        // Add token to blacklist
        await redisManager.setEx(`blacklist:${token}`, { 
          userId: req.user.id, 
          timestamp: new Date().toISOString() 
        }, 86400); // 24 hours
        
        // Remove session
        await redisManager.del(`session:${req.user.id}`);
      }
      
      securityLogger.loginAttempt(req.user.username, req.ip, false, 'Logout');
    }
    
    res.json({ 
      success: true, 
      message: 'Logged out successfully' 
    });
  } catch (error) {
    res.status(500).json({ 
      error: 'Logout failed',
      code: 'LOGOUT_ERROR'
    });
  }
};

module.exports = {
  authenticateToken,
  requireRole,
  requirePermission,
  validateTenant,
  validateBranch,
  createRateLimiter,
  refreshSession,
  logout
};
