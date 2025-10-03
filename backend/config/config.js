const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const config = {
  // Server Configuration
  server: {
    port: parseInt(process.env.PORT) || 3001,
    host: process.env.HOST || '0.0.0.0',
    env: process.env.NODE_ENV || 'development',
    cors: {
      origin: process.env.CORS_ORIGIN?.split(',') || ['http://localhost:3000'],
      credentials: true
    }
  },

  // Database Configuration
  database: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT) || 3306,
    user: process.env.DB_USER || 'nokta_user',
    password: process.env.DB_PASSWORD || 'nokta_pass_2024',
    name: process.env.DB_NAME || 'nokta_pos',
    connectionLimit: parseInt(process.env.DB_CONNECTION_LIMIT) || 20,
    acquireTimeout: parseInt(process.env.DB_ACQUIRE_TIMEOUT) || 60000,
    timeout: parseInt(process.env.DB_TIMEOUT) || 60000,
    charset: 'utf8mb4',
    timezone: '+00:00'
  },

  // Redis Configuration
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT) || 6379,
    password: process.env.REDIS_PASSWORD || 'nokta_redis_2024',
    db: parseInt(process.env.REDIS_DB) || 0,
    retryDelayOnFailover: 100,
    maxRetriesPerRequest: 3
  },

  // JWT Configuration
  jwt: {
    secret: process.env.JWT_SECRET || 'nokta_jwt_secret_key_2024_change_in_production',
    expiresIn: process.env.JWT_EXPIRE || '7d',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRE || '30d',
    issuer: 'nokta-pos-system',
    audience: 'nokta-pos-users'
  },

  // Security Configuration
  security: {
    bcryptRounds: parseInt(process.env.BCRYPT_ROUNDS) || 12,
    sessionSecret: process.env.SESSION_SECRET || 'nokta_session_secret_2024',
    maxFileSize: parseInt(process.env.MAX_FILE_SIZE) || 10485760, // 10MB
    uploadPath: process.env.UPLOAD_PATH || './uploads',
    failedAttemptWindow: parseInt(process.env.FAILED_ATTEMPT_WINDOW) || 15 * 60,
    lockoutThreshold: parseInt(process.env.ACCOUNT_LOCK_THRESHOLD) || 5,
    lockoutDuration: parseInt(process.env.ACCOUNT_LOCK_DURATION) || 15 * 60,
    sessionInactivityTimeout: parseInt(process.env.SESSION_INACTIVITY_TIMEOUT) || 30 * 60
  },

  // Rate Limiting
  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
    maxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
    authMaxRequests: parseInt(process.env.AUTH_RATE_LIMIT_MAX_REQUESTS) || 5
  },

  // Email Configuration
  email: {
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT) || 587,
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
    secure: false
  },

  // SMS Configuration (Twilio)
  twilio: {
    accountSid: process.env.TWILIO_ACCOUNT_SID,
    authToken: process.env.TWILIO_AUTH_TOKEN,
    phoneNumber: process.env.TWILIO_PHONE_NUMBER
  },

  // Payment Configuration (Stripe)
  stripe: {
    secretKey: process.env.STRIPE_SECRET_KEY,
    webhookSecret: process.env.STRIPE_WEBHOOK_SECRET
  },

  // Logging Configuration
  logging: {
    level: process.env.LOG_LEVEL || 'info',
    file: process.env.LOG_FILE || './logs/app.log',
    maxSize: '20m',
    maxFiles: '14d',
    auditFile: process.env.AUDIT_LOG_FILE || './logs/audit.log'
  },

  // Monitoring Configuration
  monitoring: {
    enabled: process.env.ENABLE_METRICS === 'true',
    port: parseInt(process.env.METRICS_PORT) || 9090,
    errorRateThreshold: parseFloat(process.env.ERROR_RATE_THRESHOLD || '0.05'),
    slowRequestThresholdMs: parseInt(process.env.SLOW_REQUEST_THRESHOLD_MS) || 1000,
    recentSampleSize: parseInt(process.env.MONITORING_RECENT_SAMPLE) || 50
  },

  // Backup & Restore Configuration
  backup: {
    enabled: process.env.BACKUP_ENABLED !== 'false',
    directory: process.env.BACKUP_DIRECTORY || path.join(__dirname, '../backups'),
    retentionDays: parseInt(process.env.BACKUP_RETENTION_DAYS) || 30,
    schedule: process.env.BACKUP_SCHEDULE || '0 3 * * *',
    verificationSchedule: process.env.BACKUP_VERIFICATION_SCHEDULE || '0 6 1 * *',
    encryptionKey: process.env.BACKUP_ENCRYPTION_KEY || null
  },

  // Dynamic Pricing Configuration
  dynamicPricing: {
    namespace: process.env.DYNAMIC_PRICING_NAMESPACE || 'dynamic-pricing',
    cacheTtlSeconds: parseInt(process.env.DYNAMIC_PRICING_CACHE_TTL) || 30,
    defaultDurationHours: parseInt(process.env.DYNAMIC_PRICING_DEFAULT_DURATION_HOURS) || 6,
    maxActiveAdjustments: parseInt(process.env.DYNAMIC_PRICING_MAX_ACTIVE) || 200
  },

  // Feature Flag Configuration
  featureFlags: {
    namespace: process.env.FEATURE_FLAG_NAMESPACE || 'feature-flags',
    allowRuntimeUpdates: process.env.FEATURE_FLAGS_RUNTIME_UPDATES !== 'false',
    cacheTtlSeconds: parseInt(process.env.FEATURE_FLAGS_CACHE_TTL) || 15,
    auditTrail: process.env.FEATURE_FLAGS_AUDIT !== 'false'
  }
};

// Validation
const requiredFields = [
  'database.password',
  'database.user',
  'jwt.secret',
  'redis.password'
];

const validateConfig = () => {
  const errors = [];
  
  requiredFields.forEach(field => {
    const value = field.split('.').reduce((obj, key) => obj?.[key], config);
    if (!value || value.includes('your_') || value.includes('change_in_production')) {
      errors.push(`Missing or invalid configuration for: ${field}`);
    }
  });

  if (errors.length > 0) {
    throw new Error(`Configuration validation failed:\n${errors.join('\n')}`);
  }
};

// Only validate in production
if (config.server.env === 'production') {
  validateConfig();
}

module.exports = config;
