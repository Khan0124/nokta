const redis = require('redis');
const config = require('./config');
const { logger } = require('./logger');

class RedisManager {
  constructor() {
    this.client = null;
    this.isConnected = false;
    this.connectionAttempts = 0;
    this.maxConnectionAttempts = 5;
    this.reconnectDelay = 1000;
  }

  async initialize() {
    try {
      this.client = redis.createClient({
        socket: {
          host: config.redis.host,
          port: config.redis.port,
          reconnectStrategy: (retries) => {
            if (retries > this.maxConnectionAttempts) {
              logger.error('Max Redis reconnection attempts reached');
              return new Error('Max reconnection attempts reached');
            }
            this.connectionAttempts = retries;
            return Math.min(retries * this.reconnectDelay, 3000);
          }
        },
        password: config.redis.password,
        database: config.redis.db,
        retryDelayOnFailover: config.redis.retryDelayOnFailover,
        maxRetriesPerRequest: config.redis.maxRetriesPerRequest
      });

      // Set up event handlers
      this.client.on('connect', () => {
        logger.info('Redis client connected');
        this.isConnected = true;
        this.connectionAttempts = 0;
      });

      this.client.on('ready', () => {
        logger.info('Redis client ready');
        this.isConnected = true;
      });

      this.client.on('error', (err) => {
        logger.error('Redis client error:', err);
        this.isConnected = false;
      });

      this.client.on('end', () => {
        logger.warn('Redis client connection ended');
        this.isConnected = false;
      });

      this.client.on('reconnecting', () => {
        logger.info('Redis client reconnecting...');
        this.isConnected = false;
      });

      // Connect to Redis
      await this.client.connect();
      
      // Test connection
      await this.testConnection();
      
      logger.info('Redis connection manager initialized successfully');
      
    } catch (error) {
      logger.error('Failed to initialize Redis connection:', error);
      this.isConnected = false;
      throw error;
    }
  }

  async testConnection() {
    try {
      await this.client.ping();
      return true;
    } catch (error) {
      logger.error('Redis connection test failed:', error);
      throw error;
    }
  }

  async get(key) {
    try {
      const value = await this.client.get(key);
      return value ? JSON.parse(value) : null;
    } catch (error) {
      logger.error('Redis GET operation failed:', { key, error: error.message });
      throw error;
    }
  }

  async set(key, value, ttl = null) {
    try {
      const serializedValue = JSON.stringify(value);
      if (ttl) {
        await this.client.setEx(key, ttl, serializedValue);
      } else {
        await this.client.set(key, serializedValue);
      }
      return true;
    } catch (error) {
      logger.error('Redis SET operation failed:', { key, error: error.message });
      throw error;
    }
  }

  async setEx(key, value, ttl) {
    try {
      const serializedValue = JSON.stringify(value);
      await this.client.setEx(key, ttl, serializedValue);
      return true;
    } catch (error) {
      logger.error('Redis SETEX operation failed:', { key, ttl, error: error.message });
      throw error;
    }
  }

  async del(key) {
    try {
      const result = await this.client.del(key);
      return result > 0;
    } catch (error) {
      logger.error('Redis DEL operation failed:', { key, error: error.message });
      throw error;
    }
  }

  async exists(key) {
    try {
      const result = await this.client.exists(key);
      return result > 0;
    } catch (error) {
      logger.error('Redis EXISTS operation failed:', { key, error: error.message });
      throw error;
    }
  }

  async expire(key, ttl) {
    try {
      const result = await this.client.expire(key, ttl);
      return result > 0;
    } catch (error) {
      logger.error('Redis EXPIRE operation failed:', { key, ttl, error: error.message });
      throw error;
    }
  }

  async ttl(key) {
    try {
      return await this.client.ttl(key);
    } catch (error) {
      logger.error('Redis TTL operation failed:', { key, error: error.message });
      throw error;
    }
  }

  async keys(pattern) {
    try {
      return await this.client.keys(pattern);
    } catch (error) {
      logger.error('Redis KEYS operation failed:', { pattern, error: error.message });
      throw error;
    }
  }

  async scan(cursor = 0, pattern = '*', count = 100) {
    try {
      return await this.client.scan(cursor, {
        MATCH: pattern,
        COUNT: count
      });
    } catch (error) {
      logger.error('Redis SCAN operation failed:', { cursor, pattern, count, error: error.message });
      throw error;
    }
  }

  async hget(key, field) {
    try {
      const value = await this.client.hGet(key, field);
      return value ? JSON.parse(value) : null;
    } catch (error) {
      logger.error('Redis HGET operation failed:', { key, field, error: error.message });
      throw error;
    }
  }

  async hset(key, field, value) {
    try {
      const serializedValue = JSON.stringify(value);
      await this.client.hSet(key, field, serializedValue);
      return true;
    } catch (error) {
      logger.error('Redis HSET operation failed:', { key, field, error: error.message });
      throw error;
    }
  }

  async hgetall(key) {
    try {
      const result = await this.client.hGetAll(key);
      const parsed = {};
      
      for (const [field, value] of Object.entries(result)) {
        try {
          parsed[field] = JSON.parse(value);
        } catch {
          parsed[field] = value;
        }
      }
      
      return parsed;
    } catch (error) {
      logger.error('Redis HGETALL operation failed:', { key, error: error.message });
      throw error;
    }
  }

  async hdel(key, ...fields) {
    try {
      const result = await this.client.hDel(key, ...fields);
      return result > 0;
    } catch (error) {
      logger.error('Redis HDEL operation failed:', { key, fields, error: error.message });
      throw error;
    }
  }

  async lpush(key, ...values) {
    try {
      const serializedValues = values.map(v => JSON.stringify(v));
      const result = await this.client.lPush(key, serializedValues);
      return result;
    } catch (error) {
      logger.error('Redis LPUSH operation failed:', { key, error: error.message });
      throw error;
    }
  }

  async rpop(key) {
    try {
      const value = await this.client.rPop(key);
      return value ? JSON.parse(value) : null;
    } catch (error) {
      logger.error('Redis RPOP operation failed:', { key, error: error.message });
      throw error;
    }
  }

  async llen(key) {
    try {
      return await this.client.lLen(key);
    } catch (error) {
      logger.error('Redis LLEN operation failed:', { key, error: error.message });
      throw error;
    }
  }

  async sadd(key, ...members) {
    try {
      const serializedMembers = members.map(m => JSON.stringify(m));
      const result = await this.client.sAdd(key, serializedMembers);
      return result;
    } catch (error) {
      logger.error('Redis SADD operation failed:', { key, error: error.message });
      throw error;
    }
  }

  async srem(key, ...members) {
    try {
      const serializedMembers = members.map(m => JSON.stringify(m));
      const result = await this.client.sRem(key, serializedMembers);
      return result;
    } catch (error) {
      logger.error('Redis SREM operation failed:', { key, error: error.message });
      throw error;
    }
  }

  async smembers(key) {
    try {
      const members = await this.client.sMembers(key);
      return members.map(m => {
        try {
          return JSON.parse(m);
        } catch {
          return m;
        }
      });
    } catch (error) {
      logger.error('Redis SMEMBERS operation failed:', { key, error: error.message });
      throw error;
    }
  }

  async sismember(key, member) {
    try {
      const serializedMember = JSON.stringify(member);
      return await this.client.sIsMember(key, serializedMember);
    } catch (error) {
      logger.error('Redis SISMEMBER operation failed:', { key, error: error.message });
      throw error;
    }
  }

  async incr(key) {
    try {
      return await this.client.incr(key);
    } catch (error) {
      logger.error('Redis INCR operation failed:', { key, error: error.message });
      throw error;
    }
  }

  async incrby(key, increment) {
    try {
      return await this.client.incrBy(key, increment);
    } catch (error) {
      logger.error('Redis INCRBY operation failed:', { key, increment, error: error.message });
      throw error;
    }
  }

  async decr(key) {
    try {
      return await this.client.decr(key);
    } catch (error) {
      logger.error('Redis DECR operation failed:', { key, error: error.message });
      throw error;
    }
  }

  async decrby(key, decrement) {
    try {
      return await this.client.decrBy(key, decrement);
    } catch (error) {
      logger.error('Redis DECRBY operation failed:', { key, decrement, error: error.message });
      throw error;
    }
  }

  async healthCheck() {
    try {
      await this.testConnection();
      const info = await this.client.info();
      
      return {
        status: 'healthy',
        timestamp: new Date().toISOString(),
        info: {
          version: info.split('\r\n').find(line => line.startsWith('redis_version'))?.split(':')[1],
          uptime: info.split('\r\n').find(line => line.startsWith('uptime_in_seconds'))?.split(':')[1],
          connected_clients: info.split('\r\n').find(line => line.startsWith('connected_clients'))?.split(':')[1],
          used_memory: info.split('\r\n').find(line => line.startsWith('used_memory_human'))?.split(':')[1]
        }
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
    if (this.client) {
      await this.client.quit();
      this.isConnected = false;
      logger.info('Redis connection closed');
    }
  }

  // Cache utility methods
  async cacheGet(key, fallback = null, ttl = 3600) {
    try {
      const cached = await this.get(key);
      if (cached !== null) {
        return cached;
      }
      
      if (fallback && typeof fallback === 'function') {
        const data = await fallback();
        await this.setEx(key, data, ttl);
        return data;
      }
      
      return null;
    } catch (error) {
      logger.error('Cache GET operation failed:', { key, error: error.message });
      return null;
    }
  }

  async cacheSet(key, value, ttl = 3600) {
    try {
      await this.setEx(key, value, ttl);
      return true;
    } catch (error) {
      logger.error('Cache SET operation failed:', { key, error: error.message });
      return false;
    }
  }

  async cacheDelete(pattern) {
    try {
      const keys = await this.keys(pattern);
      if (keys.length > 0) {
        await Promise.all(keys.map(key => this.del(key)));
      }
      return keys.length;
    } catch (error) {
      logger.error('Cache DELETE operation failed:', { pattern, error: error.message });
      return 0;
    }
  }
}

// Create singleton instance
const redisManager = new RedisManager();

module.exports = redisManager;
