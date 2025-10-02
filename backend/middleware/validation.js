const Joi = require('joi');
const { logger } = require('../config/logger');

// Common validation schemas
const commonSchemas = {
  id: Joi.number().integer().positive().required(),
  uuid: Joi.string().uuid().required(),
  email: Joi.string().email().max(255).required(),
  phone: Joi.string().pattern(/^\+?[1-9]\d{1,14}$/).max(20),
  password: Joi.string().min(8).max(128).pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/).required(),
  username: Joi.string().alphanum().min(3).max(50).required(),
  name: Joi.string().min(2).max(255).required(),
  description: Joi.string().max(1000).allow('', null),
  amount: Joi.number().precision(2).min(0).required(),
  quantity: Joi.number().integer().min(0).required(),
  percentage: Joi.number().precision(2).min(0).max(100),
  date: Joi.date().iso().max('now'),
  boolean: Joi.boolean().required(),
  json: Joi.object().allow(null),
  pagination: Joi.object({
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20),
    sortBy: Joi.string().valid('id', 'name', 'created_at', 'updated_at').default('id'),
    sortOrder: Joi.string().valid('asc', 'desc').default('desc')
  })
};

// Authentication validation schemas
const authSchemas = {
  login: Joi.object({
    username: Joi.string().required(),
    password: Joi.string().required(),
    rememberMe: Joi.boolean().default(false)
  }),

  register: Joi.object({
    username: commonSchemas.username,
    email: commonSchemas.email,
    password: commonSchemas.password,
    confirmPassword: Joi.string().valid(Joi.ref('password')).required(),
    fullName: commonSchemas.name,
    phone: commonSchemas.phone,
    role: Joi.string().valid('customer', 'staff', 'manager', 'admin').default('customer'),
    tenantId: commonSchemas.id.optional(),
    branchId: commonSchemas.id.optional()
  }),

  changePassword: Joi.object({
    currentPassword: Joi.string().required(),
    newPassword: commonSchemas.password,
    confirmPassword: Joi.string().valid(Joi.ref('newPassword')).required()
  }),

  resetPassword: Joi.object({
    email: commonSchemas.email,
    token: Joi.string().required(),
    newPassword: commonSchemas.password,
    confirmPassword: Joi.string().valid(Joi.ref('newPassword')).required()
  }),

  forgotPassword: Joi.object({
    email: commonSchemas.email
  })
};

// User validation schemas
const userSchemas = {
  create: Joi.object({
    username: commonSchemas.username,
    email: commonSchemas.email,
    password: commonSchemas.password,
    fullName: commonSchemas.name,
    phone: commonSchemas.phone,
    role: Joi.string().valid('customer', 'staff', 'manager', 'admin').required(),
    tenantId: commonSchemas.id.required(),
    branchId: commonSchemas.id.optional(),
    isActive: commonSchemas.boolean.default(true),
    permissions: Joi.array().items(Joi.string()).default([])
  }),

  update: Joi.object({
    fullName: commonSchemas.name.optional(),
    phone: commonSchemas.phone.optional(),
    role: Joi.string().valid('customer', 'staff', 'manager', 'admin').optional(),
    branchId: commonSchemas.id.optional(),
    isActive: commonSchemas.boolean.optional(),
    permissions: Joi.array().items(Joi.string()).optional(),
    avatar: Joi.string().uri().optional()
  }),

  list: commonSchemas.pagination.keys({
    role: Joi.string().valid('customer', 'staff', 'manager', 'admin').optional(),
    isActive: commonSchemas.boolean.optional(),
    tenantId: commonSchemas.id.optional(),
    branchId: commonSchemas.id.optional(),
    search: Joi.string().max(100).optional()
  })
};

// Tenant validation schemas
const tenantSchemas = {
  create: Joi.object({
    name: commonSchemas.name,
    domain: Joi.string().domain().optional(),
    logo: Joi.string().uri().optional(),
    phone: commonSchemas.phone,
    email: commonSchemas.email,
    address: Joi.string().max(500).optional(),
    subscriptionPlan: Joi.string().valid('basic', 'premium', 'enterprise').default('basic'),
    subscriptionExpires: commonSchemas.date.optional(),
    settings: commonSchemas.json.optional()
  }),

  update: Joi.object({
    name: commonSchemas.name.optional(),
    domain: Joi.string().domain().optional(),
    logo: Joi.string().uri().optional(),
    phone: commonSchemas.phone.optional(),
    email: commonSchemas.email.optional(),
    address: Joi.string().max(500).optional(),
    subscriptionPlan: Joi.string().valid('basic', 'premium', 'enterprise').optional(),
    subscriptionExpires: commonSchemas.date.optional(),
    settings: commonSchemas.json.optional(),
    status: Joi.string().valid('active', 'suspended', 'cancelled').optional()
  })
};

// Branch validation schemas
const branchSchemas = {
  create: Joi.object({
    tenantId: commonSchemas.id.required(),
    name: commonSchemas.name,
    code: Joi.string().alphanum().max(20).optional(),
    address: Joi.string().max(500).optional(),
    phone: commonSchemas.phone,
    email: commonSchemas.email,
    latitude: Joi.number().min(-90).max(90).optional(),
    longitude: Joi.number().min(-180).max(180).optional(),
    openingTime: Joi.string().pattern(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/).optional(),
    closingTime: Joi.string().pattern(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/).optional(),
    isMain: commonSchemas.boolean.default(false),
    settings: commonSchemas.json.optional()
  }),

  update: Joi.object({
    name: commonSchemas.name.optional(),
    code: Joi.string().alphanum().max(20).optional(),
    address: Joi.string().max(500).optional(),
    phone: commonSchemas.phone.optional(),
    email: commonSchemas.email.optional(),
    latitude: Joi.number().min(-90).max(90).optional(),
    longitude: Joi.number().min(-180).max(180).optional(),
    openingTime: Joi.string().pattern(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/).optional(),
    closingTime: Joi.string().pattern(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/).optional(),
    isMain: commonSchemas.boolean.optional(),
    isActive: commonSchemas.boolean.optional(),
    settings: commonSchemas.json.optional()
  })
};

// Product validation schemas
const productSchemas = {
  create: Joi.object({
    tenantId: commonSchemas.id.required(),
    branchId: commonSchemas.id.required(),
    name: commonSchemas.name,
    description: commonSchemas.description,
    sku: Joi.string().alphanum().max(50).optional(),
    barcode: Joi.string().max(100).optional(),
    categoryId: commonSchemas.id.required(),
    price: commonSchemas.amount,
    costPrice: commonSchemas.amount.optional(),
    salePrice: commonSchemas.amount.optional(),
    stockQuantity: commonSchemas.quantity.default(0),
    minStockLevel: commonSchemas.quantity.default(0),
    maxStockLevel: commonSchemas.quantity.optional(),
    unit: Joi.string().max(20).default('piece'),
    isActive: commonSchemas.boolean.default(true),
    isTaxable: commonSchemas.boolean.default(true),
    taxRate: commonSchemas.percentage.default(0),
    images: Joi.array().items(Joi.string().uri()).max(10).optional(),
    attributes: commonSchemas.json.optional()
  }),

  update: Joi.object({
    name: commonSchemas.name.optional(),
    description: commonSchemas.description.optional(),
    sku: Joi.string().alphanum().max(50).optional(),
    barcode: Joi.string().max(100).optional(),
    categoryId: commonSchemas.id.optional(),
    price: commonSchemas.amount.optional(),
    costPrice: commonSchemas.amount.optional(),
    salePrice: commonSchemas.amount.optional(),
    stockQuantity: commonSchemas.quantity.optional(),
    minStockLevel: commonSchemas.quantity.optional(),
    maxStockLevel: commonSchemas.quantity.optional(),
    unit: Joi.string().max(20).optional(),
    isActive: commonSchemas.boolean.optional(),
    isTaxable: commonSchemas.boolean.optional(),
    taxRate: commonSchemas.percentage.optional(),
    images: Joi.array().items(Joi.string().uri()).max(10).optional(),
    attributes: commonSchemas.json.optional()
  }),

  list: commonSchemas.pagination.keys({
    categoryId: commonSchemas.id.optional(),
    isActive: commonSchemas.boolean.optional(),
    minPrice: commonSchemas.amount.optional(),
    maxPrice: commonSchemas.amount.optional(),
    inStock: commonSchemas.boolean.optional(),
    search: Joi.string().max(100).optional()
  })
};

// Order validation schemas
const orderSchemas = {
  create: Joi.object({
    tenantId: commonSchemas.id.required(),
    branchId: commonSchemas.id.required(),
    customerId: commonSchemas.id.optional(),
    customerName: Joi.string().max(255).optional(),
    customerPhone: commonSchemas.phone.optional(),
    customerEmail: commonSchemas.email.optional(),
    items: Joi.array().items(Joi.object({
      productId: commonSchemas.id.required(),
      quantity: commonSchemas.quantity.required(),
      unitPrice: commonSchemas.amount.required(),
      discount: commonSchemas.amount.default(0),
      notes: Joi.string().max(200).optional()
    })).min(1).required(),
    subtotal: commonSchemas.amount.required(),
    taxAmount: commonSchemas.amount.default(0),
    discountAmount: commonSchemas.amount.default(0),
    totalAmount: commonSchemas.amount.required(),
    paymentMethod: Joi.string().valid('cash', 'card', 'mobile_money', 'bank_transfer').required(),
    paymentStatus: Joi.string().valid('pending', 'paid', 'failed', 'refunded').default('pending'),
    orderStatus: Joi.string().valid('pending', 'confirmed', 'preparing', 'ready', 'delivered', 'cancelled').default('pending'),
    notes: Joi.string().max(500).optional(),
    deliveryAddress: Joi.string().max(500).optional(),
    deliveryFee: commonSchemas.amount.default(0),
    expectedDeliveryTime: commonSchemas.date.optional()
  }),

  update: Joi.object({
    orderStatus: Joi.string().valid('pending', 'confirmed', 'preparing', 'ready', 'delivered', 'cancelled').optional(),
    paymentStatus: Joi.string().valid('pending', 'paid', 'failed', 'refunded').optional(),
    notes: Joi.string().max(500).optional(),
    deliveryAddress: Joi.string().max(500).optional(),
    deliveryFee: commonSchemas.amount.optional(),
    expectedDeliveryTime: commonSchemas.date.optional()
  }),

  list: commonSchemas.pagination.keys({
    orderStatus: Joi.string().valid('pending', 'confirmed', 'preparing', 'ready', 'delivered', 'cancelled').optional(),
    paymentStatus: Joi.string().valid('pending', 'paid', 'failed', 'refunded').optional(),
    paymentMethod: Joi.string().valid('cash', 'card', 'mobile_money', 'bank_transfer').optional(),
    startDate: commonSchemas.date.optional(),
    endDate: commonSchemas.date.optional(),
    minAmount: commonSchemas.amount.optional(),
    maxAmount: commonSchemas.amount.optional(),
    customerId: commonSchemas.id.optional(),
    search: Joi.string().max(100).optional()
  })
};

// Category validation schemas
const categorySchemas = {
  create: Joi.object({
    tenantId: commonSchemas.id.required(),
    name: commonSchemas.name,
    description: commonSchemas.description,
    parentId: commonSchemas.id.optional(),
    image: Joi.string().uri().optional(),
    isActive: commonSchemas.boolean.default(true),
    sortOrder: Joi.number().integer().min(0).default(0)
  }),

  update: Joi.object({
    name: commonSchemas.name.optional(),
    description: commonSchemas.description.optional(),
    parentId: commonSchemas.id.optional(),
    image: Joi.string().uri().optional(),
    isActive: commonSchemas.boolean.optional(),
    sortOrder: Joi.number().integer().min(0).optional()
  })
};

// File upload validation schemas
const fileSchemas = {
  upload: Joi.object({
    file: Joi.object({
      fieldname: Joi.string().required(),
      originalname: Joi.string().required(),
      encoding: Joi.string().required(),
      mimetype: Joi.string().valid('image/jpeg', 'image/png', 'image/gif', 'image/webp', 'application/pdf').required(),
      size: Joi.number().max(10 * 1024 * 1024).required() // 10MB max
    }).required()
  })
};

// Generic validation middleware
const validate = (schema, property = 'body') => {
  return (req, res, next) => {
    const { error, value } = schema.validate(req[property], {
      abortEarly: false,
      stripUnknown: true,
      convert: true
    });

    if (error) {
      const errorDetails = error.details.map(detail => ({
        field: detail.path.join('.'),
        message: detail.message,
        type: detail.type
      }));

      logger.warn('Validation failed', {
        endpoint: req.originalUrl,
        method: req.method,
        errors: errorDetails,
        ip: req.ip,
        userId: req.user?.id || 'anonymous'
      });

      return res.status(400).json({
        error: 'Validation failed',
        code: 'VALIDATION_ERROR',
        details: errorDetails
      });
    }

    // Replace request data with validated data
    req[property] = value;
    next();
  };
};

// Sanitize input data
const sanitize = (req, res, next) => {
  const sanitizeValue = (value) => {
    if (typeof value === 'string') {
      // Remove potential XSS vectors
      return value
        .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
        .replace(/javascript:/gi, '')
        .replace(/on\w+\s*=/gi, '')
        .trim();
    }
    if (Array.isArray(value)) {
      return value.map(sanitizeValue);
    }
    if (typeof value === 'object' && value !== null) {
      const sanitized = {};
      for (const [key, val] of Object.entries(value)) {
        sanitized[key] = sanitizeValue(val);
      }
      return sanitized;
    }
    return value;
  };

  // Sanitize body, query, and params
  if (req.body) req.body = sanitizeValue(req.body);
  if (req.query) req.query = sanitizeValue(req.query);
  if (req.params) req.params = sanitizeValue(req.params);

  next();
};

module.exports = {
  validate,
  sanitize,
  schemas: {
    common: commonSchemas,
    auth: authSchemas,
    user: userSchemas,
    tenant: tenantSchemas,
    branch: branchSchemas,
    product: productSchemas,
    order: orderSchemas,
    category: categorySchemas,
    file: fileSchemas
  }
};
