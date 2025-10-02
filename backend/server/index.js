const http = require('http');
const socketIo = require('socket.io');
const config = require('../config/config');
const databaseManager = require('../config/database');
const redisManager = require('../config/redis');
const { logger } = require('../config/logger');
const { gracefulShutdown } = require('../middleware/errorHandler');
const App = require('./app');

class Server {
  constructor() {
    this.app = new App();
    this.server = http.createServer(this.app.getApp());
    this.io = socketIo(this.server, {
      cors: {
        origin: config.server.cors.origin,
        methods: ['GET', 'POST', 'PUT', 'DELETE'],
        credentials: true
      }
    });
    
    this.setupSocketHandlers();
    this.setupGracefulShutdown();
  }

  setupSocketHandlers() {
    this.io.on('connection', (socket) => {
      logger.info('WebSocket client connected', { socketId: socket.id });

      // Join tenant room
      socket.on('join_tenant', (tenantId) => {
        socket.join(`tenant:${tenantId}`);
        logger.info('Socket joined tenant room', { socketId: socket.id, tenantId });
      });

      // Join branch room
      socket.on('join_branch', (branchId) => {
        socket.join(`branch:${branchId}`);
        logger.info('Socket joined branch room', { socketId: socket.id, branchId });
      });

      // Join order room
      socket.on('join_order', (orderId) => {
        socket.join(`order:${orderId}`);
        logger.info('Socket joined order room', { socketId: socket.id, orderId });
      });

      // Driver location update
      socket.on('driver_location', (data) => {
        this.io.to(`order:${data.orderId}`).emit('driver_location_update', data);
        logger.debug('Driver location update', { orderId: data.orderId, location: data.location });
      });

      // Order status update
      socket.on('order_status_update', (data) => {
        this.io.to(`order:${data.orderId}`).emit('order_status_changed', data);
        logger.info('Order status update', { orderId: data.orderId, status: data.status });
      });

      // Product stock update
      socket.on('product_stock_update', (data) => {
        this.io.to(`tenant:${data.tenantId}`).emit('product_stock_changed', data);
        logger.info('Product stock update', { productId: data.productId, newStock: data.newStock });
      });

      // Disconnect
      socket.on('disconnect', () => {
        logger.info('WebSocket client disconnected', { socketId: socket.id });
      });

      // Error handling
      socket.on('error', (error) => {
        logger.error('Socket error', { socketId: socket.id, error: error.message });
      });
    });

    // Socket middleware for authentication
    this.io.use(async (socket, next) => {
      try {
        const token = socket.handshake.auth.token;
        if (!token) {
          return next(new Error('Authentication token required'));
        }

        // Verify token and get user info
        const jwt = require('jsonwebtoken');
        const decoded = jwt.verify(token, config.jwt.secret, {
          issuer: config.jwt.issuer,
          audience: config.jwt.audience
        });

        socket.user = {
          id: decoded.id,
          username: decoded.username,
          role: decoded.role,
          tenantId: decoded.tenantId,
          branchId: decoded.branchId
        };

        next();
      } catch (error) {
        logger.error('Socket authentication failed', { error: error.message });
        next(new Error('Authentication failed'));
      }
    });
  }

  setupGracefulShutdown() {
    const shutdownHandler = gracefulShutdown(this.server, {
      database: databaseManager,
      redis: redisManager
    });

    process.on('SIGTERM', shutdownHandler);
    process.on('SIGINT', shutdownHandler);

    // Handle uncaught exceptions
    process.on('uncaughtException', (error) => {
      logger.error('Uncaught Exception:', error);
      shutdownHandler();
    });

    // Handle unhandled promise rejections
    process.on('unhandledRejection', (reason, promise) => {
      logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
      shutdownHandler();
    });
  }

  async start() {
    try {
      // Initialize database
      logger.info('Initializing database connection...');
      await databaseManager.initialize();

      // Initialize Redis
      logger.info('Initializing Redis connection...');
      await redisManager.initialize();

      // Start server
      this.server.listen(config.server.port, config.server.host, () => {
        logger.info(`
╔══════════════════════════════════════╗
║     Nokta POS Backend API Server     ║
╠══════════════════════════════════════╣
║  Status: Running                      ║
║  Port: ${config.server.port.toString().padEnd(28)} ║
║  Host: ${config.server.host.padEnd(28)} ║
║  Environment: ${config.server.env.padEnd(22)} ║
║  Database: Connected                  ║
║  Redis: Connected                     ║
║  WebSocket: Active                    ║
╚══════════════════════════════════════╝
        `);

        logger.info('Server started successfully', {
          port: config.server.port,
          host: config.server.host,
          environment: config.server.env,
          timestamp: new Date().toISOString()
        });
      });

      // Server error handling
      this.server.on('error', (error) => {
        logger.error('Server error:', error);
        if (error.syscall !== 'listen') {
          throw error;
        }

        switch (error.code) {
          case 'EACCES':
            logger.error(`Port ${config.server.port} requires elevated privileges`);
            process.exit(1);
            break;
          case 'EADDRINUSE':
            logger.error(`Port ${config.server.port} is already in use`);
            process.exit(1);
            break;
          default:
            throw error;
        }
      });

    } catch (error) {
      logger.error('Failed to start server:', error);
      process.exit(1);
    }
  }

  async stop() {
    try {
      logger.info('Stopping server...');
      
      // Close WebSocket connections
      this.io.close(() => {
        logger.info('WebSocket server closed');
      });

      // Close HTTP server
      this.server.close(() => {
        logger.info('HTTP server closed');
      });

      // Close database connections
      await databaseManager.close();
      
      // Close Redis connections
      await redisManager.close();

      logger.info('Server stopped successfully');
    } catch (error) {
      logger.error('Error stopping server:', error);
    }
  }

  getIO() {
    return this.io;
  }

  getServer() {
    return this.server;
  }
}

// Create and start server if this file is run directly
if (require.main === module) {
  const server = new Server();
  server.start();
}

module.exports = Server;
