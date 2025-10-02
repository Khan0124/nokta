const fs = require('fs').promises;
const path = require('path');
const databaseManager = require('../config/database');
const { logger } = require('../config/logger');

class MigrationRunner {
  constructor() {
    this.migrationsPath = path.join(__dirname, 'migrations');
    this.migrationsTable = 'schema_migrations';
    this.currentVersion = null;
  }

  async initialize() {
    try {
      // Create migrations table if it doesn't exist
      await this.createMigrationsTable();
      
      // Get current version
      this.currentVersion = await this.getCurrentVersion();
      
      logger.info('Migration runner initialized', { currentVersion: this.currentVersion });
    } catch (error) {
      logger.error('Failed to initialize migration runner:', error);
      throw error;
    }
  }

  async createMigrationsTable() {
    const createTableSQL = `
      CREATE TABLE IF NOT EXISTS ${this.migrationsTable} (
        id INT AUTO_INCREMENT PRIMARY KEY,
        version VARCHAR(50) NOT NULL UNIQUE,
        name VARCHAR(255) NOT NULL,
        executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        execution_time_ms INT,
        status ENUM('success', 'failed') DEFAULT 'success',
        error_message TEXT
      )
    `;

    try {
      await databaseManager.execute(createTableSQL);
      logger.info('Migrations table created/verified');
    } catch (error) {
      logger.error('Failed to create migrations table:', error);
      throw error;
    }
  }

  async getCurrentVersion() {
    try {
      const result = await databaseManager.query(
        `SELECT version FROM ${this.migrationsTable} ORDER BY id DESC LIMIT 1`
      );
      return result.length > 0 ? result[0].version : '0.0.0';
    } catch (error) {
      logger.error('Failed to get current migration version:', error);
      return '0.0.0';
    }
  }

  async getMigrationFiles() {
    try {
      const files = await fs.readdir(this.migrationsPath);
      return files
        .filter(file => file.endsWith('.sql'))
        .sort((a, b) => {
          const versionA = this.extractVersion(a);
          const versionB = this.extractVersion(b);
          return this.compareVersions(versionA, versionB);
        });
    } catch (error) {
      logger.error('Failed to read migration files:', error);
      throw error;
    }
  }

  extractVersion(filename) {
    const match = filename.match(/^(\d+)_/);
    return match ? match[1] : '0';
  }

  compareVersions(a, b) {
    return parseInt(a) - parseInt(b);
  }

  async runMigrations(targetVersion = null) {
    try {
      const migrationFiles = await this.getMigrationFiles();
      const pendingMigrations = this.getPendingMigrations(migrationFiles, targetVersion);

      if (pendingMigrations.length === 0) {
        logger.info('No pending migrations');
        return;
      }

      logger.info(`Running ${pendingMigrations.length} pending migrations`);

      for (const migration of pendingMigrations) {
        await this.runMigration(migration);
      }

      logger.info('All migrations completed successfully');
    } catch (error) {
      logger.error('Migration failed:', error);
      throw error;
    }
  }

  getPendingMigrations(migrationFiles, targetVersion) {
    const pending = [];
    
    for (const file of migrationFiles) {
      const version = this.extractVersion(file);
      
      if (this.compareVersions(version, this.currentVersion) > 0) {
        if (targetVersion && this.compareVersions(version, targetVersion) > 0) {
          break;
        }
        pending.push({ file, version });
      }
    }
    
    return pending;
  }

  async runMigration(migration) {
    const { file, version } = migration;
    const filePath = path.join(this.migrationsPath, file);
    const startTime = Date.now();
    
    try {
      logger.info(`Running migration: ${file} (version ${version})`);
      
      // Read migration file
      const sql = await fs.readFile(filePath, 'utf8');
      
      // Split SQL into individual statements
      const statements = this.splitSQLStatements(sql);
      
      // Execute each statement
      for (const statement of statements) {
        if (statement.trim()) {
          await databaseManager.execute(statement);
        }
      }
      
      const executionTime = Date.now() - startTime;
      
      // Record successful migration
      await this.recordMigration(version, file, executionTime, 'success');
      
      // Update current version
      this.currentVersion = version;
      
      logger.info(`Migration ${file} completed successfully in ${executionTime}ms`);
      
    } catch (error) {
      const executionTime = Date.now() - startTime;
      
      // Record failed migration
      await this.recordMigration(version, file, executionTime, 'failed', error.message);
      
      logger.error(`Migration ${file} failed:`, error);
      throw error;
    }
  }

  splitSQLStatements(sql) {
    // Split by semicolon, but handle semicolons in strings and comments
    const statements = [];
    let currentStatement = '';
    let inString = false;
    let stringChar = null;
    let inComment = false;
    let commentType = null;
    
    for (let i = 0; i < sql.length; i++) {
      const char = sql[i];
      const nextChar = sql[i + 1];
      
      // Handle comments
      if (!inString && !inComment) {
        if (char === '-' && nextChar === '-') {
          inComment = true;
          commentType = 'single';
          i++; // Skip next dash
          continue;
        } else if (char === '/' && nextChar === '*') {
          inComment = true;
          commentType = 'multi';
          i++; // Skip next char
          continue;
        }
      }
      
      // Handle comment end
      if (inComment) {
        if (commentType === 'single' && char === '\n') {
          inComment = false;
          commentType = null;
        } else if (commentType === 'multi' && char === '*' && nextChar === '/') {
          inComment = false;
          commentType = null;
          i++; // Skip next char
          continue;
        }
        continue;
      }
      
      // Handle strings
      if (!inComment && (char === "'" || char === '"')) {
        if (!inString) {
          inString = true;
          stringChar = char;
        } else if (stringChar === char) {
          inString = false;
          stringChar = null;
        }
      }
      
      // Handle semicolon (statement separator)
      if (char === ';' && !inString && !inComment) {
        if (currentStatement.trim()) {
          statements.push(currentStatement.trim());
        }
        currentStatement = '';
      } else {
        currentStatement += char;
      }
    }
    
    // Add last statement if exists
    if (currentStatement.trim()) {
      statements.push(currentStatement.trim());
    }
    
    return statements;
  }

  async recordMigration(version, name, executionTime, status, errorMessage = null) {
    try {
      const sql = `
        INSERT INTO ${this.migrationsTable} 
        (version, name, execution_time_ms, status, error_message) 
        VALUES (?, ?, ?, ?, ?)
      `;
      
      await databaseManager.execute(sql, [version, name, executionTime, status, errorMessage]);
    } catch (error) {
      logger.error('Failed to record migration:', error);
    }
  }

  async rollback(targetVersion = null) {
    try {
      const migrations = await this.getExecutedMigrations();
      const rollbackMigrations = this.getRollbackMigrations(migrations, targetVersion);

      if (rollbackMigrations.length === 0) {
        logger.info('No migrations to rollback');
        return;
      }

      logger.info(`Rolling back ${rollbackMigrations.length} migrations`);

      for (const migration of rollbackMigrations) {
        await this.rollbackMigration(migration);
      }

      logger.info('Rollback completed successfully');
    } catch (error) {
      logger.error('Rollback failed:', error);
      throw error;
    }
  }

  async getExecutedMigrations() {
    try {
      return await databaseManager.query(
        `SELECT * FROM ${this.migrationsTable} ORDER BY id DESC`
      );
    } catch (error) {
      logger.error('Failed to get executed migrations:', error);
      return [];
    }
  }

  getRollbackMigrations(migrations, targetVersion) {
    const rollback = [];
    
    for (const migration of migrations) {
      if (targetVersion && this.compareVersions(migration.version, targetVersion) <= 0) {
        break;
      }
      rollback.push(migration);
    }
    
    return rollback;
  }

  async rollbackMigration(migration) {
    try {
      logger.info(`Rolling back migration: ${migration.name} (version ${migration.version})`);
      
      // For now, we'll just remove the migration record
      // In a real implementation, you'd want to execute rollback SQL
      await databaseManager.execute(
        `DELETE FROM ${this.migrationsTable} WHERE version = ?`,
        [migration.version]
      );
      
      logger.info(`Migration ${migration.name} rolled back successfully`);
      
    } catch (error) {
      logger.error(`Failed to rollback migration ${migration.name}:`, error);
      throw error;
    }
  }

  async getMigrationStatus() {
    try {
      const migrations = await this.getExecutedMigrations();
      const files = await this.getMigrationFiles();
      
      const status = {
        currentVersion: this.currentVersion,
        totalMigrations: files.length,
        executedMigrations: migrations.length,
        pendingMigrations: files.length - migrations.length,
        lastMigration: migrations[0] || null,
        migrations: []
      };
      
      // Map files to execution status
      for (const file of files) {
        const version = this.extractVersion(file);
        const executed = migrations.find(m => m.version === version);
        
        status.migrations.push({
          file,
          version,
          executed: !!executed,
          executedAt: executed?.executed_at,
          status: executed?.status,
          executionTime: executed?.execution_time_ms
        });
      }
      
      return status;
    } catch (error) {
      logger.error('Failed to get migration status:', error);
      throw error;
    }
  }

  async createMigration(name) {
    try {
      const timestamp = new Date().toISOString().replace(/[-:]/g, '').split('.')[0];
      const version = (await this.getMigrationFiles()).length + 1;
      const filename = `${version.toString().padStart(3, '0')}_${name}.sql`;
      const filepath = path.join(this.migrationsPath, filename);
      
      const template = `-- Migration: ${filename}
-- Description: ${name}
-- Date: ${new Date().toISOString()}
-- Version: ${version}

-- Add your SQL statements here
-- Example:
-- CREATE TABLE example (
--   id INT AUTO_INCREMENT PRIMARY KEY,
--   name VARCHAR(255) NOT NULL,
--   created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );

-- Migration completed
`;
      
      await fs.writeFile(filepath, template);
      logger.info(`Created migration file: ${filename}`);
      
      return filename;
    } catch (error) {
      logger.error('Failed to create migration:', error);
      throw error;
    }
  }
}

// CLI interface
async function main() {
  const args = process.argv.slice(2);
  const command = args[0];
  
  try {
    const runner = new MigrationRunner();
    await runner.initialize();
    
    switch (command) {
      case 'up':
        await runner.runMigrations();
        break;
      case 'down':
        const targetVersion = args[1];
        await runner.rollback(targetVersion);
        break;
      case 'status':
        const status = await runner.getMigrationStatus();
        console.log(JSON.stringify(status, null, 2));
        break;
      case 'create':
        const name = args[1];
        if (!name) {
          console.error('Migration name is required');
          process.exit(1);
        }
        await runner.createMigration(name);
        break;
      default:
        console.log(`
Usage: node migrate.js <command> [options]

Commands:
  up                    Run all pending migrations
  down [version]        Rollback to specific version
  status                Show migration status
  create <name>         Create new migration file

Examples:
  node migrate.js up
  node migrate.js down 001
  node migrate.js status
  node migrate.js create add_users_table
        `);
    }
    
    await databaseManager.close();
    process.exit(0);
    
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = MigrationRunner;
