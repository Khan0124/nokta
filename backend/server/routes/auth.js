const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const config = require('../../config/config');
const databaseManager = require('../../config/database');
const redisManager = require('../../config/redis');
const { logger, securityLogger, auditLogger } = require('../../config/logger');
const { validate, schemas } = require('../../middleware/validation');
const { authenticateToken, createRateLimiter } = require('../../middleware/auth');
const { asyncHandler } = require('../../middleware/errorHandler');

const router = express.Router();

// Rate limiting for auth endpoints
const authLimiter = createRateLimiter(
  config.rateLimit.windowMs,
  config.rateLimit.authMaxRequests
);

const recordFailedLoginAttempt = async ({ userId = null, username, ip, reason }) => {
  try {
    const key = userId ? `failed_attempts:${userId}` : `failed_attempts:ip:${ip}`;
    const attempts = await redisManager.incr(key);

    if (attempts === 1) {
      await redisManager.expire(key, config.security.failedAttemptWindow);
    }

    if (userId && attempts >= config.security.lockoutThreshold) {
      await redisManager.setEx(`lockout:${userId}`, {
        attempts,
        reason: 'Too many failed login attempts',
        lockedAt: new Date().toISOString()
      }, config.security.lockoutDuration);

      securityLogger.failedLogin(username, ip, 'Account locked');
      auditLogger.warn('account_locked', {
        username,
        ip,
        attempts
      });

      return { locked: true, attempts };
    }

    securityLogger.failedLogin(username, ip, reason);
    return { locked: false, attempts };
  } catch (error) {
    logger.error('Failed to record login attempt', {
      username,
      ip,
      reason,
      error: error.message
    });
    securityLogger.failedLogin(username, ip, reason);
    return { locked: false, attempts: 0 };
  }
};

// Login endpoint
router.post('/login', 
  authLimiter,
  validate(schemas.auth.login),
  asyncHandler(async (req, res) => {
    const { username, password, rememberMe } = req.body;
    const clientIP = req.ip;

    try {
      // Find user by username or email
      const user = await databaseManager.findOne('users', 
        { username, is_active: 1 },
        'id, username, email, password_hash, full_name, role, tenant_id, branch_id, permissions'
      );

      if (!user) {
        await recordFailedLoginAttempt({
          username,
          ip: clientIP,
          reason: 'User not found'
        });

        return res.status(401).json({
          error: 'Invalid credentials',
          code: 'INVALID_CREDENTIALS'
        });
      }

      // Check if user account is locked
      const lockoutKey = `lockout:${user.id}`;
      const isLocked = await redisManager.exists(lockoutKey);
      if (isLocked) {
        const retryAfter = await redisManager.ttl(lockoutKey);
        securityLogger.failedLogin(username, clientIP, 'Account locked');
        return res.status(423).json({
          error: 'Account is temporarily locked due to multiple failed attempts',
          code: 'ACCOUNT_LOCKED',
          retryAfter: retryAfter > 0 ? retryAfter : config.security.lockoutDuration
        });
      }

      // Verify password
      const isValidPassword = await bcrypt.compare(password, user.password_hash);
      if (!isValidPassword) {
        const attempt = await recordFailedLoginAttempt({
          userId: user.id,
          username,
          ip: clientIP,
          reason: 'Invalid password'
        });

        if (attempt.locked) {
          return res.status(423).json({
            error: 'Account is temporarily locked due to multiple failed attempts',
            code: 'ACCOUNT_LOCKED',
            retryAfter: config.security.lockoutDuration
          });
        }

        return res.status(401).json({
          error: 'Invalid credentials',
          code: 'INVALID_CREDENTIALS'
        });
      }

      // Generate JWT token
      const tokenPayload = {
        id: user.id,
        username: user.username,
        email: user.email,
        role: user.role,
        tenantId: user.tenant_id,
        branchId: user.branch_id,
        permissions: user.permissions || []
      };

      const token = jwt.sign(tokenPayload, config.jwt.secret, {
        expiresIn: rememberMe ? config.jwt.refreshExpiresIn : config.jwt.expiresIn,
        issuer: config.jwt.issuer,
        audience: config.jwt.audience
      });

      // Update last login
      await databaseManager.update('users', 
        { last_login: new Date() },
        { id: user.id }
      );

      // Store session in Redis
      const sessionKey = `session:${user.id}`;
      const nowIso = new Date().toISOString();
      const sessionData = {
        token,
        role: user.role,
        tenantId: user.tenant_id,
        permissions: user.permissions || [],
        lastActivity: nowIso,
        createdAt: nowIso,
        ip: clientIP,
        userAgent: req.get('user-agent')
      };

      const sessionTTL = rememberMe ? 86400 * 30 : 86400; // 30 days or 1 day
      await redisManager.setEx(sessionKey, sessionData, sessionTTL);

      // Log successful login
      securityLogger.loginAttempt(username, clientIP, true);
      auditLogger.info('user_login_success', {
        userId: user.id,
        username: user.username,
        ip: clientIP,
        rememberMe
      });

      // Clear any failed login attempts
      await redisManager.del(`failed_attempts:${user.id}`);
      await redisManager.del(`failed_attempts:ip:${clientIP}`);

      res.json({
        success: true,
        token,
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          fullName: user.full_name,
          role: user.role,
          tenantId: user.tenant_id,
          branchId: user.branch_id,
          permissions: user.permissions || []
        },
        expiresIn: sessionTTL
      });

    } catch (error) {
      logger.error('Login error:', error);
      res.status(500).json({
        error: 'Authentication failed',
        code: 'AUTH_ERROR'
      });
    }
  })
);

// Register endpoint
router.post('/register',
  authLimiter,
  validate(schemas.auth.register),
  asyncHandler(async (req, res) => {
    const { username, email, password, fullName, phone, role, tenantId, branchId } = req.body;

    try {
      // Check if username or email already exists
      const existingUser = await databaseManager.findOne('users', 
        { username, tenant_id: tenantId },
        'id'
      );

      if (existingUser) {
        return res.status(409).json({
          error: 'Username already exists',
          code: 'USERNAME_EXISTS'
        });
      }

      const existingEmail = await databaseManager.findOne('users', 
        { email, tenant_id: tenantId },
        'id'
      );

      if (existingEmail) {
        return res.status(409).json({
          error: 'Email already exists',
          code: 'EMAIL_EXISTS'
        });
      }

      // Hash password
      const saltRounds = config.security.bcryptRounds;
      const passwordHash = await bcrypt.hash(password, saltRounds);

      // Create user
      const userId = await databaseManager.insert('users', {
        tenant_id: tenantId,
        branch_id: branchId,
        username,
        email,
        password_hash: passwordHash,
        full_name: fullName,
        phone,
        role,
        is_active: 1,
        permissions: [],
        created_at: new Date(),
        updated_at: new Date()
      });

      logger.info('User registered successfully', { userId, username, email });

      res.status(201).json({
        success: true,
        message: 'User registered successfully',
        userId
      });

    } catch (error) {
      logger.error('Registration error:', error);
      res.status(500).json({
        error: 'Registration failed',
        code: 'REGISTRATION_ERROR'
      });
    }
  })
);

// Logout endpoint
router.post('/logout',
  authenticateToken,
  asyncHandler(async (req, res) => {
    try {
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
      
      res.json({
        success: true,
        message: 'Logged out successfully'
      });
    } catch (error) {
      logger.error('Logout error:', error);
      res.status(500).json({
        error: 'Logout failed',
        code: 'LOGOUT_ERROR'
      });
    }
  })
);

// Refresh token endpoint
router.post('/refresh',
  authenticateToken,
  asyncHandler(async (req, res) => {
    try {
      const userId = req.user.id;
      const sessionKey = `session:${userId}`;
      
      // Get current session
      const session = await redisManager.get(sessionKey);
      if (!session) {
        return res.status(401).json({
          error: 'Session expired',
          code: 'SESSION_EXPIRED'
        });
      }

      // Generate new token
      const tokenPayload = {
        id: req.user.id,
        username: req.user.username,
        email: req.user.email,
        role: req.user.role,
        tenantId: req.user.tenantId,
        branchId: req.user.branchId,
        permissions: req.user.permissions || []
      };

      const newToken = jwt.sign(tokenPayload, config.jwt.secret, {
        expiresIn: config.jwt.expiresIn,
        issuer: config.jwt.issuer,
        audience: config.jwt.audience
      });

      // Update session with new token
      session.token = newToken;
      session.lastActivity = new Date().toISOString();
      
      await redisManager.setEx(sessionKey, session, 86400); // 1 day

      res.json({
        success: true,
        token: newToken,
        expiresIn: 86400
      });

    } catch (error) {
      logger.error('Token refresh error:', error);
      res.status(500).json({
        error: 'Token refresh failed',
        code: 'REFRESH_ERROR'
      });
    }
  })
);

// Change password endpoint
router.post('/change-password',
  authenticateToken,
  validate(schemas.auth.changePassword),
  asyncHandler(async (req, res) => {
    const { currentPassword, newPassword } = req.body;
    const userId = req.user.id;

    try {
      // Get current user with password
      const user = await databaseManager.findOne('users', 
        { id: userId },
        'password_hash'
      );

      if (!user) {
        return res.status(404).json({
          error: 'User not found',
          code: 'USER_NOT_FOUND'
        });
      }

      // Verify current password
      const isValidPassword = await bcrypt.compare(currentPassword, user.password_hash);
      if (!isValidPassword) {
        return res.status(400).json({
          error: 'Current password is incorrect',
          code: 'INVALID_CURRENT_PASSWORD'
        });
      }

      // Hash new password
      const saltRounds = config.security.bcryptRounds;
      const newPasswordHash = await bcrypt.hash(newPassword, saltRounds);

      // Update password
      await databaseManager.update('users',
        { password_hash: newPasswordHash, updated_at: new Date() },
        { id: userId }
      );

      // Invalidate all sessions for this user
      await redisManager.del(`session:${userId}`);

      logger.info('Password changed successfully', { userId });

      res.json({
        success: true,
        message: 'Password changed successfully'
      });

    } catch (error) {
      logger.error('Password change error:', error);
      res.status(500).json({
        error: 'Password change failed',
        code: 'PASSWORD_CHANGE_ERROR'
      });
    }
  })
);

// Forgot password endpoint
router.post('/forgot-password',
  authLimiter,
  validate(schemas.auth.forgotPassword),
  asyncHandler(async (req, res) => {
    const { email } = req.body;

    try {
      // Find user by email
      const user = await databaseManager.findOne('users', 
        { email, is_active: 1 },
        'id, username, email'
      );

      if (!user) {
        // Don't reveal if user exists or not
        return res.json({
          success: true,
          message: 'If an account with that email exists, a password reset link has been sent'
        });
      }

      // Generate reset token
      const resetToken = require('crypto').randomBytes(32).toString('hex');
      const resetTokenHash = await bcrypt.hash(resetToken, 10);

      // Store reset token in Redis with expiration
      const resetKey = `password_reset:${resetTokenHash}`;
      await redisManager.setEx(resetKey, {
        userId: user.id,
        email: user.email,
        timestamp: new Date().toISOString()
      }, 3600); // 1 hour

      // TODO: Send email with reset link
      // For now, just log the token
      logger.info('Password reset token generated', { 
        userId: user.id, 
        email: user.email,
        token: resetToken 
      });

      res.json({
        success: true,
        message: 'If an account with that email exists, a password reset link has been sent'
      });

    } catch (error) {
      logger.error('Forgot password error:', error);
      res.status(500).json({
        error: 'Password reset request failed',
        code: 'PASSWORD_RESET_ERROR'
      });
    }
  })
);

// Reset password endpoint
router.post('/reset-password',
  authLimiter,
  validate(schemas.auth.resetPassword),
  asyncHandler(async (req, res) => {
    const { token, newPassword } = req.body;

    try {
      // Hash the provided token to compare with stored hash
      const resetTokenHash = await bcrypt.hash(token, 10);
      
      // Find reset token in Redis
      const resetKey = `password_reset:${resetTokenHash}`;
      const resetData = await redisManager.get(resetKey);

      if (!resetData) {
        return res.status(400).json({
          error: 'Invalid or expired reset token',
          code: 'INVALID_RESET_TOKEN'
        });
      }

      // Hash new password
      const saltRounds = config.security.bcryptRounds;
      const newPasswordHash = await bcrypt.hash(newPassword, saltRounds);

      // Update user password
      await databaseManager.update('users',
        { password_hash: newPasswordHash, updated_at: new Date() },
        { id: resetData.userId }
      );

      // Remove reset token
      await redisManager.del(resetKey);

      // Invalidate all sessions for this user
      await redisManager.del(`session:${resetData.userId}`);

      logger.info('Password reset successfully', { userId: resetData.userId });

      res.json({
        success: true,
        message: 'Password reset successfully'
      });

    } catch (error) {
      logger.error('Password reset error:', error);
      res.status(500).json({
        error: 'Password reset failed',
        code: 'PASSWORD_RESET_ERROR'
      });
    }
  })
);

// Get current user profile
router.get('/profile',
  authenticateToken,
  asyncHandler(async (req, res) => {
    try {
      const userId = req.user.id;
      
      const user = await databaseManager.findOne('users',
        { id: userId },
        'id, username, email, full_name, phone, role, tenant_id, branch_id, permissions, avatar, created_at, last_login'
      );

      if (!user) {
        return res.status(404).json({
          error: 'User not found',
          code: 'USER_NOT_FOUND'
        });
      }

      res.json({
        success: true,
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          fullName: user.full_name,
          phone: user.phone,
          role: user.role,
          tenantId: user.tenant_id,
          branchId: user.branch_id,
          permissions: user.permissions || [],
          avatar: user.avatar,
          createdAt: user.created_at,
          lastLogin: user.last_login
        }
      });

    } catch (error) {
      logger.error('Get profile error:', error);
      res.status(500).json({
        error: 'Failed to get profile',
        code: 'PROFILE_ERROR'
      });
    }
  })
);

module.exports = router;
