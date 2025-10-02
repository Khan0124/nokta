const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const mysql = require('mysql2/promise');
const redis = require('redis');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const socketIo = require('socket.io');
const http = require('http');
const path = require('path');
require('dotenv').config();

// Initialize Express App
const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: process.env.CORS_ORIGIN || '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE']
  }
});

// Port Configuration
const PORT = process.env.PORT || 3001;

// Database Configuration
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'nokta_user',
  password: process.env.DB_PASSWORD || 'nokta_pass_2024',
  database: process.env.DB_NAME || 'nokta_pos',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
};

// Create MySQL Connection Pool
const pool = mysql.createPool(dbConfig);

// Redis Configuration
const redisClient = redis.createClient({
  socket: {
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379
  },
  password: process.env.REDIS_PASSWORD || 'nokta_redis_2024'
});

// Connect to Redis
redisClient.connect().catch(console.error);

// Middleware
app.use(helmet());
app.use(cors());
app.use(compression());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));
app.use(morgan('combined'));

// Static Files
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Rate Limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: 'Too many authentication attempts, please try again later.'
});

app.use('/api/', limiter);
app.use('/api/auth/', authLimiter);

// JWT Middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, process.env.JWT_SECRET || 'nokta_jwt_secret', (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  });
};

// Multi-tenant Middleware
const validateTenant = async (req, res, next) => {
  const tenantId = req.headers['x-tenant-id'] || req.user?.tenantId;
  
  if (!tenantId) {
    return res.status(400).json({ error: 'Tenant ID required' });
  }

  try {
    const [tenant] = await pool.execute(
      'SELECT * FROM tenants WHERE id = ? AND status = "active"',
      [tenantId]
    );

    if (tenant.length === 0) {
      return res.status(404).json({ error: 'Tenant not found or inactive' });
    }

    req.tenant = tenant[0];
    next();
  } catch (error) {
    console.error('Tenant validation error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// ====================================
// Authentication Routes
// ====================================

// Login
app.post('/api/auth/login', async (req, res) => {
  const { username, password } = req.body;

  try {
    const [users] = await pool.execute(
      'SELECT * FROM users WHERE (username = ? OR email = ?) AND is_active = 1',
      [username, username]
    );

    if (users.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = users[0];
    const validPassword = await bcrypt.compare(password, user.password_hash);

    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign(
      {
        id: user.id,
        username: user.username,
        email: user.email,
        role: user.role,
        tenantId: user.tenant_id,
        branchId: user.branch_id
      },
      process.env.JWT_SECRET || 'nokta_jwt_secret',
      { expiresIn: process.env.JWT_EXPIRE || '7d' }
    );

    // Update last login
    await pool.execute(
      'UPDATE users SET last_login = NOW() WHERE id = ?',
      [user.id]
    );

    // Cache user session in Redis
    await redisClient.setEx(`session:${user.id}`, 86400, JSON.stringify({
      token,
      role: user.role,
      tenantId: user.tenant_id
    }));

    res.json({
      success: true,
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        fullName: user.full_name,
        role: user.role,
        avatar: user.avatar
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Register
app.post('/api/auth/register', async (req, res) => {
  const { username, email, password, fullName, phone, role = 'customer' } = req.body;

  try {
    // Check if user exists
    const [existingUsers] = await pool.execute(
      'SELECT id FROM users WHERE username = ? OR email = ?',
      [username, email]
    );

    if (existingUsers.length > 0) {
      return res.status(400).json({ error: 'Username or email already exists' });
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, 10);

    // Insert new user
    const [result] = await pool.execute(
      'INSERT INTO users (tenant_id, username, email, password_hash, full_name, phone, role) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [1, username, email, passwordHash, fullName, phone, role] // Default tenant_id = 1
    );

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      userId: result.insertId
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Logout
app.post('/api/auth/logout', authenticateToken, async (req, res) => {
  try {
    // Remove session from Redis
    await redisClient.del(`session:${req.user.id}`);
    res.json({ success: true, message: 'Logged out successfully' });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ====================================
// Product Routes
// ====================================

// Get Products
app.get('/api/products', authenticateToken, validateTenant, async (req, res) => {
  const { category_id, search, is_available, sort_by = 'name', limit = 50, offset = 0 } = req.query;

  try {
    let query = 'SELECT * FROM products WHERE tenant_id = ?';
    const params = [req.tenant.id];

    if (category_id) {
      query += ' AND category_id = ?';
      params.push(category_id);
    }

    if (search) {
      query += ' AND (name LIKE ? OR description LIKE ?)';
      params.push(`%${search}%`, `%${search}%`);
    }

    if (is_available !== undefined) {
      query += ' AND is_available = ?';
      params.push(is_available === 'true' ? 1 : 0);
    }

    query += ` ORDER BY ${sort_by} LIMIT ? OFFSET ?`;
    params.push(parseInt(limit), parseInt(offset));

    const [products] = await pool.execute(query, params);

    res.json({
      success: true,
      data: products,
      pagination: {
        limit: parseInt(limit),
        offset: parseInt(offset),
        total: products.length
      }
    });
  } catch (error) {
    console.error('Get products error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get Single Product
app.get('/api/products/:id', authenticateToken, validateTenant, async (req, res) => {
  try {
    const [products] = await pool.execute(
      'SELECT * FROM products WHERE id = ? AND tenant_id = ?',
      [req.params.id, req.tenant.id]
    );

    if (products.length === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }

    res.json(products[0]);
  } catch (error) {
    console.error('Get product error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create Product
app.post('/api/products', authenticateToken, validateTenant, async (req, res) => {
  const {
    category_id, name, name_ar, description, price, cost, image_url,
    barcode, sku, is_available = true
  } = req.body;

  try {
    const [result] = await pool.execute(
      `INSERT INTO products (tenant_id, category_id, name, name_ar, description, price, cost, image_url, barcode, sku, is_available)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [req.tenant.id, category_id, name, name_ar, description, price, cost, image_url, barcode, sku, is_available]
    );

    res.status(201).json({
      success: true,
      id: result.insertId,
      message: 'Product created successfully'
    });
  } catch (error) {
    console.error('Create product error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update Product
app.put('/api/products/:id', authenticateToken, validateTenant, async (req, res) => {
  const updates = req.body;
  delete updates.id;
  delete updates.tenant_id;

  try {
    const setClause = Object.keys(updates).map(key => `${key} = ?`).join(', ');
    const values = [...Object.values(updates), req.params.id, req.tenant.id];

    await pool.execute(
      `UPDATE products SET ${setClause} WHERE id = ? AND tenant_id = ?`,
      values
    );

    res.json({ success: true, message: 'Product updated successfully' });
  } catch (error) {
    console.error('Update product error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Delete Product
app.delete('/api/products/:id', authenticateToken, validateTenant, async (req, res) => {
  try {
    await pool.execute(
      'DELETE FROM products WHERE id = ? AND tenant_id = ?',
      [req.params.id, req.tenant.id]
    );

    res.json({ success: true, message: 'Product deleted successfully' });
  } catch (error) {
    console.error('Delete product error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ====================================
// Order Routes
// ====================================

// Get Orders
app.get('/api/orders', authenticateToken, validateTenant, async (req, res) => {
  const { status, from_date, to_date, limit = 50, offset = 0 } = req.query;

  try {
    let query = 'SELECT o.*, c.name as customer_name FROM orders o LEFT JOIN customers c ON o.customer_id = c.id WHERE o.tenant_id = ?';
    const params = [req.tenant.id];

    if (status) {
      query += ' AND o.status = ?';
      params.push(status);
    }

    if (from_date) {
      query += ' AND o.created_at >= ?';
      params.push(from_date);
    }

    if (to_date) {
      query += ' AND o.created_at <= ?';
      params.push(to_date);
    }

    query += ' ORDER BY o.created_at DESC LIMIT ? OFFSET ?';
    params.push(parseInt(limit), parseInt(offset));

    const [orders] = await pool.execute(query, params);

    // Get order items for each order
    for (let order of orders) {
      const [items] = await pool.execute(
        'SELECT * FROM order_items WHERE order_id = ?',
        [order.id]
      );
      order.items = items;
    }

    res.json({
      success: true,
      data: orders,
      pagination: {
        limit: parseInt(limit),
        offset: parseInt(offset)
      }
    });
  } catch (error) {
    console.error('Get orders error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create Order
app.post('/api/orders', authenticateToken, validateTenant, async (req, res) => {
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const {
      branch_id, customer_id, order_type, items, subtotal, tax, discount,
      delivery_fee, total, payment_method, customer_name, customer_phone,
      customer_email, customer_address, table_number, special_instructions
    } = req.body;

    // Generate order number
    const orderNumber = `ORD${Date.now()}`;

    // Insert order
    const [orderResult] = await connection.execute(
      `INSERT INTO orders (
        tenant_id, branch_id, order_number, customer_id, order_type, status,
        subtotal, tax, discount, delivery_fee, total, payment_method,
        customer_name, customer_phone, customer_email, customer_address,
        table_number, special_instructions
      ) VALUES (?, ?, ?, ?, ?, 'pending', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        req.tenant.id, branch_id, orderNumber, customer_id, order_type,
        subtotal, tax, discount, delivery_fee, total, payment_method,
        customer_name, customer_phone, customer_email, customer_address,
        table_number, special_instructions
      ]
    );

    const orderId = orderResult.insertId;

    // Insert order items
    for (const item of items) {
      await connection.execute(
        `INSERT INTO order_items (order_id, product_id, product_name, quantity, unit_price, total_price, notes, modifiers)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          orderId, item.product_id, item.product_name, item.quantity,
          item.unit_price, item.total_price, item.notes, JSON.stringify(item.modifiers)
        ]
      );

      // Update inventory if enabled
      if (req.tenant.settings?.enable_inventory_tracking) {
        await connection.execute(
          'UPDATE inventory SET quantity = quantity - ? WHERE product_id = ? AND branch_id = ?',
          [item.quantity, item.product_id, branch_id]
        );
      }
    }

    await connection.commit();

    // Emit new order event via WebSocket
    io.to(`tenant:${req.tenant.id}`).emit('new_order', {
      id: orderId,
      order_number: orderNumber,
      status: 'pending',
      total,
      created_at: new Date()
    });

    res.status(201).json({
      success: true,
      order_id: orderId,
      order_number: orderNumber,
      message: 'Order created successfully'
    });
  } catch (error) {
    await connection.rollback();
    console.error('Create order error:', error);
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    connection.release();
  }
});

// Update Order Status
app.put('/api/orders/:id/status', authenticateToken, validateTenant, async (req, res) => {
  const { status } = req.body;
  const validStatuses = ['pending', 'confirmed', 'preparing', 'ready', 'out_for_delivery', 'delivered', 'cancelled', 'refunded'];

  if (!validStatuses.includes(status)) {
    return res.status(400).json({ error: 'Invalid status' });
  }

  try {
    const timestamp = status === 'confirmed' ? ', confirmed_at = NOW()' :
                     status === 'ready' ? ', ready_at = NOW()' :
                     status === 'delivered' ? ', delivered_at = NOW()' :
                     status === 'cancelled' ? ', cancelled_at = NOW()' : '';

    await pool.execute(
      `UPDATE orders SET status = ?${timestamp} WHERE id = ? AND tenant_id = ?`,
      [status, req.params.id, req.tenant.id]
    );

    // Emit status update via WebSocket
    io.to(`tenant:${req.tenant.id}`).emit('order_status_update', {
      order_id: req.params.id,
      status,
      updated_at: new Date()
    });

    res.json({ success: true, message: 'Order status updated successfully' });
  } catch (error) {
    console.error('Update order status error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ====================================
// Category Routes
// ====================================

// Get Categories
app.get('/api/categories', authenticateToken, validateTenant, async (req, res) => {
  try {
    const [categories] = await pool.execute(
      'SELECT * FROM categories WHERE tenant_id = ? AND is_active = 1 ORDER BY display_order, name',
      [req.tenant.id]
    );

    res.json({ success: true, data: categories });
  } catch (error) {
    console.error('Get categories error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ====================================
// Customer Routes
// ====================================

// Get Customers
app.get('/api/customers', authenticateToken, validateTenant, async (req, res) => {
  const { search, limit = 50, offset = 0 } = req.query;

  try {
    let query = 'SELECT * FROM customers WHERE tenant_id = ?';
    const params = [req.tenant.id];

    if (search) {
      query += ' AND (name LIKE ? OR phone LIKE ? OR email LIKE ?)';
      params.push(`%${search}%`, `%${search}%`, `%${search}%`);
    }

    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(parseInt(limit), parseInt(offset));

    const [customers] = await pool.execute(query, params);

    res.json({
      success: true,
      data: customers,
      pagination: {
        limit: parseInt(limit),
        offset: parseInt(offset)
      }
    });
  } catch (error) {
    console.error('Get customers error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ====================================
// Dashboard & Analytics Routes
// ====================================

// Dashboard Stats
app.get('/api/dashboard/stats', authenticateToken, validateTenant, async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];

    // Today's revenue
    const [revenueResult] = await pool.execute(
      'SELECT COALESCE(SUM(total), 0) as revenue, COUNT(*) as orders FROM orders WHERE tenant_id = ? AND DATE(created_at) = ?',
      [req.tenant.id, today]
    );

    // Pending orders
    const [pendingResult] = await pool.execute(
      'SELECT COUNT(*) as pending FROM orders WHERE tenant_id = ? AND status IN ("pending", "confirmed", "preparing")',
      [req.tenant.id]
    );

    // New customers today
    const [customersResult] = await pool.execute(
      'SELECT COUNT(*) as new_customers FROM customers WHERE tenant_id = ? AND DATE(created_at) = ?',
      [req.tenant.id, today]
    );

    // Top products
    const [topProducts] = await pool.execute(
      `SELECT p.name, SUM(oi.quantity) as total_sold, SUM(oi.total_price) as revenue
       FROM order_items oi
       JOIN orders o ON oi.order_id = o.id
       JOIN products p ON oi.product_id = p.id
       WHERE o.tenant_id = ? AND DATE(o.created_at) = ?
       GROUP BY p.id
       ORDER BY total_sold DESC
       LIMIT 5`,
      [req.tenant.id, today]
    );

    res.json({
      success: true,
      data: {
        todayRevenue: revenueResult[0].revenue,
        todayOrders: revenueResult[0].orders,
        pendingOrders: pendingResult[0].pending,
        newCustomers: customersResult[0].new_customers,
        topProducts
      }
    });
  } catch (error) {
    console.error('Dashboard stats error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ====================================
// WebSocket Events
// ====================================

io.on('connection', (socket) => {
  console.log('New WebSocket connection:', socket.id);

  // Join tenant room
  socket.on('join_tenant', (tenantId) => {
    socket.join(`tenant:${tenantId}`);
    console.log(`Socket ${socket.id} joined tenant:${tenantId}`);
  });

  // Join branch room
  socket.on('join_branch', (branchId) => {
    socket.join(`branch:${branchId}`);
    console.log(`Socket ${socket.id} joined branch:${branchId}`);
  });

  // Driver location update
  socket.on('driver_location', (data) => {
    io.to(`order:${data.orderId}`).emit('driver_location_update', data);
  });

  // Disconnect
  socket.on('disconnect', () => {
    console.log('WebSocket disconnected:', socket.id);
  });
});

// ====================================
// Health Check
// ====================================

app.get('/health', async (req, res) => {
  try {
    // Check database connection
    await pool.execute('SELECT 1');
    
    // Check Redis connection
    await redisClient.ping();

    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: {
        database: 'connected',
        redis: 'connected'
      }
    });
  } catch (error) {
    res.status(500).json({
      status: 'unhealthy',
      error: error.message
    });
  }
});

// ====================================
// Error Handling
// ====================================

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Something went wrong!',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// 404 Handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// ====================================
// Start Server
// ====================================

server.listen(PORT, () => {
  console.log(`
╔══════════════════════════════════════╗
║     Nokta POS Backend API Server     ║
╠══════════════════════════════════════╣
║  Status: Running                      ║
║  Port: ${PORT}                          ║
║  Environment: ${process.env.NODE_ENV || 'development'}          ║
║  Database: Connected                  ║
║  Redis: Connected                     ║
╚══════════════════════════════════════╝
  `);
});

// Graceful Shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
  });

  await pool.end();
  await redisClient.quit();
  process.exit(0);
});

module.exports = app;
