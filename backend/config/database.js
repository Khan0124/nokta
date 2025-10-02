const mysql = require('mysql2/promise');
const config = require('./config');
const logger = require('./logger');

class DatabaseManager {
  constructor() {
    this.pool = null;
    this.isConnected = false;
    this.connectionAttempts = 0;
    this.maxConnectionAttempts = 5;
  }

  async initialize() {
    try {
      this.pool = mysql.createPool({
        host: config.database.host,
        port: config.database.port,
        user: config.database.user,
        password: config.database.password,
        database: config.database.name,
        charset: config.database.charset,
        timezone: config.database.timezone,
        waitForConnections: true,
        connectionLimit: config.database.connectionLimit,
        queueLimit: 0,
        acquireTimeout: config.database.acquireTimeout,
        timeout: config.database.timeout,
        reconnect: true,
        multipleStatements: false,
        dateStrings: false,
        supportBigNumbers: true,
        bigNumberStrings: true
      });

      // Test connection
      await this.testConnection();
      this.isConnected = true;
      this.connectionAttempts = 0;
      
      logger.info('Database connection pool initialized successfully');
      
      // Set up connection event handlers
      this.pool.on('connection', (connection) => {
        logger.debug('New database connection established');
        
        connection.on('error', (err) => {
          logger.error('Database connection error:', err);
          this.isConnected = false;
        });
      });

      this.pool.on('acquire', (connection) => {
        logger.debug('Database connection acquired from pool');
      });

      this.pool.on('release', (connection) => {
        logger.debug('Database connection released back to pool');
      });

      this.pool.on('enqueue', () => {
        logger.warn('Database connection request queued - pool may be exhausted');
      });

    } catch (error) {
      logger.error('Failed to initialize database connection pool:', error);
      this.isConnected = false;
      throw error;
    }
  }

  async testConnection() {
    try {
      const connection = await this.pool.getConnection();
      await connection.ping();
      connection.release();
      return true;
    } catch (error) {
      logger.error('Database connection test failed:', error);
      throw error;
    }
  }

  async getConnection() {
    if (!this.pool || !this.isConnected) {
      throw new Error('Database not initialized or disconnected');
    }

    try {
      const connection = await this.pool.getConnection();
      return connection;
    } catch (error) {
      logger.error('Failed to get database connection:', error);
      throw error;
    }
  }

  async execute(sql, params = []) {
    try {
      const [rows, fields] = await this.pool.execute(sql, params);
      return { rows, fields };
    } catch (error) {
      logger.error('Database query execution failed:', {
        sql: sql.substring(0, 100) + '...',
        params: params,
        error: error.message
      });
      throw error;
    }
  }

  async query(sql, params = []) {
    try {
      const [rows] = await this.pool.query(sql, params);
      return rows;
    } catch (error) {
      logger.error('Database query failed:', {
        sql: sql.substring(0, 100) + '...',
        params: params,
        error: error.message
      });
      throw error;
    }
  }

  async transaction(callback) {
    const connection = await this.getConnection();
    
    try {
      await connection.beginTransaction();
      const result = await callback(connection);
      await connection.commit();
      return result;
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  async healthCheck() {
    try {
      await this.testConnection();
      return {
        status: 'healthy',
        timestamp: new Date().toISOString(),
        poolSize: this.pool.pool.config.connectionLimit,
        activeConnections: this.pool.pool._allConnections.length,
        idleConnections: this.pool.pool._freeConnections.length
      };
    } catch (error) {
      return {
        status: 'unhealthy',
        timestamp: new Date().toISOString(),
        error: error.message
      };
    }
  }

  async close() {
    if (this.pool) {
      await this.pool.end();
      this.isConnected = false;
      logger.info('Database connection pool closed');
    }
  }

  // Utility methods for common operations
  async findOne(table, conditions = {}, fields = '*') {
    const whereClause = Object.keys(conditions)
      .map(key => `${key} = ?`)
      .join(' AND ');
    
    const sql = `SELECT ${fields} FROM ${table} WHERE ${whereClause} LIMIT 1`;
    const params = Object.values(conditions);
    
    const result = await this.query(sql, params);
    return result.length > 0 ? result[0] : null;
  }

  async findMany(table, conditions = {}, fields = '*', options = {}) {
    let sql = `SELECT ${fields} FROM ${table}`;
    const params = [];
    
    if (Object.keys(conditions).length > 0) {
      const whereClause = Object.keys(conditions)
        .map(key => `${key} = ?`)
        .join(' AND ');
      sql += ` WHERE ${whereClause}`;
      params.push(...Object.values(conditions));
    }
    
    if (options.orderBy) {
      sql += ` ORDER BY ${options.orderBy}`;
    }
    
    if (options.limit) {
      sql += ` LIMIT ?`;
      params.push(options.limit);
    }
    
    if (options.offset) {
      sql += ` OFFSET ?`;
      params.push(options.offset);
    }
    
    return await this.query(sql, params);
  }

  async insert(table, data) {
    const fields = Object.keys(data);
    const placeholders = fields.map(() => '?').join(', ');
    const sql = `INSERT INTO ${table} (${fields.join(', ')}) VALUES (${placeholders})`;
    const params = Object.values(data);
    
    const result = await this.execute(sql, params);
    return result.rows.insertId;
  }

  async update(table, data, conditions) {
    const setClause = Object.keys(data)
      .map(key => `${key} = ?`)
      .join(', ');
    
    const whereClause = Object.keys(conditions)
      .map(key => `${key} = ?`)
      .join(' AND ');
    
    const sql = `UPDATE ${table} SET ${setClause} WHERE ${whereClause}`;
    const params = [...Object.values(data), ...Object.values(conditions)];
    
    const result = await this.execute(sql, params);
    return result.rows.affectedRows;
  }

  async delete(table, conditions) {
    const whereClause = Object.keys(conditions)
      .map(key => `${key} = ?`)
      .join(' AND ');
    
    const sql = `DELETE FROM ${table} WHERE ${whereClause}`;
    const params = Object.values(conditions);
    
    const result = await this.execute(sql, params);
    return result.rows.affectedRows;
  }
}

// Create singleton instance
const databaseManager = new DatabaseManager();

module.exports = databaseManager;
