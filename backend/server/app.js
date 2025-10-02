const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const path = require('path');
const config = require('../config/config');
const { requestLogger, errorLogger } = require('../config/logger');
const { errorHandler, notFoundHandler } = require('../middleware/errorHandler');
const { sanitize } = require('../middleware/validation');

// Import route modules
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const tenantRoutes = require('./routes/tenants');
const branchRoutes = require('./routes/branches');
const productRoutes = require('./routes/products');
const orderRoutes = require('./routes/orders');
const categoryRoutes = require('./routes/categories');
const paymentRoutes = require('./routes/payments');
const inventoryRoutes = require('./routes/inventory');
const systemRoutes = require('./routes/system');

class App {
  constructor() {
    this.app = express();
    this.setupMiddleware();
    this.setupRoutes();
    this.setupErrorHandling();
  }

  setupMiddleware() {
    // Security middleware
    this.app.use(helmet({
      contentSecurityPolicy: {
        directives: {
          defaultSrc: ["'self'"],
          styleSrc: ["'self'", "'unsafe-inline'"],
          scriptSrc: ["'self'"],
          imgSrc: ["'self'", "data:", "https:"],
          connectSrc: ["'self'"],
          fontSrc: ["'self'"],
          objectSrc: ["'none'"],
          mediaSrc: ["'self'"],
          frameSrc: ["'none'"]
        }
      },
      hsts: {
        maxAge: 31536000,
        includeSubDomains: true,
        preload: true
      }
    }));

    // CORS configuration
    this.app.use(cors({
      origin: config.server.cors.origin,
      credentials: config.server.cors.credentials,
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization', 'X-Tenant-ID', 'X-Branch-ID'],
      exposedHeaders: ['X-Total-Count', 'X-Page-Count']
    }));

    // Compression
    this.app.use(compression());

    // Body parsing
    this.app.use(express.json({ 
      limit: config.security.maxFileSize,
      verify: (req, res, buf) => {
        req.rawBody = buf;
      }
    }));
    this.app.use(express.urlencoded({ 
      extended: true, 
      limit: config.security.maxFileSize 
    }));

    // Request logging
    this.app.use(requestLogger);

    // Input sanitization
    this.app.use(sanitize);

    // Trust proxy for accurate IP addresses
    this.app.set('trust proxy', 1);

    // Static files
    this.app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

    // Health check endpoint
    this.app.get('/health', (req, res) => {
      res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: config.server.env,
        version: '1.0.0'
      });
    });
  }

  setupRoutes() {
    // API versioning
    const apiVersion = '/api/v1';

    // Authentication routes (no auth required)
    this.app.use(`${apiVersion}/auth`, authRoutes);

    // Protected routes (auth required)
    this.app.use(`${apiVersion}/users`, userRoutes);
    this.app.use(`${apiVersion}/tenants`, tenantRoutes);
    this.app.use(`${apiVersion}/branches`, branchRoutes);
    this.app.use(`${apiVersion}/products`, productRoutes);
    this.app.use(`${apiVersion}/orders`, orderRoutes);
    this.app.use(`${apiVersion}/categories`, categoryRoutes);
    this.app.use(`${apiVersion}/payments`, paymentRoutes);
    this.app.use(`${apiVersion}/inventory`, inventoryRoutes);
    this.app.use(`${apiVersion}/system`, systemRoutes);

    // API documentation
    this.app.get(`${apiVersion}/docs`, (req, res) => {
      res.json({
        message: 'Nokta POS API Documentation',
        version: '1.0.0',
        endpoints: {
          auth: `${apiVersion}/auth`,
          users: `${apiVersion}/users`,
          tenants: `${apiVersion}/tenants`,
          branches: `${apiVersion}/branches`,
          products: `${apiVersion}/products`,
          orders: `${apiVersion}/orders`,
          categories: `${apiVersion}/categories`,
          payments: `${apiVersion}/payments`,
          inventory: `${apiVersion}/inventory`,
          system: `${apiVersion}/system`
        },
        documentation: 'https://docs.nokta-pos.com'
      });
    });

    // API root
    this.app.get(apiVersion, (req, res) => {
      res.json({
        message: 'Nokta POS API',
        version: '1.0.0',
        status: 'running',
        timestamp: new Date().toISOString()
      });
    });
  }

  setupErrorHandling() {
    // 404 handler
    this.app.use(notFoundHandler);

    // Error handling middleware
    this.app.use(errorLogger);
    this.app.use(errorHandler);
  }

  getApp() {
    return this.app;
  }
}

module.exports = App;
