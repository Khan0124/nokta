#!/usr/bin/env node
/**
 * Simple migration runner for Nokta POS using raw SQL files located in database/migrations.
 * Each migration must contain `-- up` and `-- down` sections. Only the `-- up` portion is executed
 * by this runner. Applied migration filenames are tracked in the `schema_migrations` table.
 */

const fs = require('node:fs');
const path = require('node:path');
const mysql = require('mysql2/promise');
const config = require('../config/config');
const { logger } = require('../config/logger');

const MIGRATIONS_DIR = path.resolve(__dirname, '../../database/migrations');
const MIGRATIONS_TABLE = 'schema_migrations';

const resolveEnv = (value, fallback) => {
  return value !== undefined && value !== null && value !== '' ? value : fallback;
};

const databaseConfig = {
  host: resolveEnv(process.env.DB_HOST, config.database.host),
  port: Number(resolveEnv(process.env.DB_PORT, config.database.port)),
  user: resolveEnv(process.env.DB_USER, config.database.user),
  password: resolveEnv(process.env.DB_PASSWORD, config.database.password),
  database: resolveEnv(process.env.DB_NAME, config.database.name),
  multipleStatements: true,
  charset: config.database.charset,
  timezone: config.database.timezone,
};

const readMigrations = () => {
  if (!fs.existsSync(MIGRATIONS_DIR)) {
    return [];
  }

  return fs
    .readdirSync(MIGRATIONS_DIR)
    .filter((file) => file.endsWith('.sql'))
    .sort();
};

const parseMigration = (filePath) => {
  const contents = fs.readFileSync(filePath, 'utf8');
  const upMatch = contents.split(/\n--\s*down/i)[0];
  const upSection = upMatch.replace(/\n--\s*up/i, '').trim();
  return upSection;
};

(async () => {
  const migrations = readMigrations();

  if (migrations.length === 0) {
    console.log('No migration files found.');
    process.exit(0);
  }

  const connection = await mysql.createConnection(databaseConfig);

  try {
    await connection.execute(
      `CREATE TABLE IF NOT EXISTS ${MIGRATIONS_TABLE} (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        filename VARCHAR(255) NOT NULL UNIQUE,
        applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`
    );

    const [appliedRows] = await connection.execute(
      `SELECT filename FROM ${MIGRATIONS_TABLE} ORDER BY filename ASC`
    );
    const applied = new Set(appliedRows.map((row) => row.filename));

    for (const filename of migrations) {
      if (applied.has(filename)) {
        continue;
      }

      const filePath = path.join(MIGRATIONS_DIR, filename);
      const upSql = parseMigration(filePath);

      if (!upSql) {
        console.warn(`Skipping ${filename}: no -- up section found.`);
        continue;
      }

      console.log(`Applying migration ${filename}...`);
      await connection.beginTransaction();
      try {
        await connection.query(upSql);
        await connection.execute(
          `INSERT INTO ${MIGRATIONS_TABLE} (filename) VALUES (?)`,
          [filename]
        );
        await connection.commit();
        console.log(`Applied ${filename}`);
      } catch (error) {
        await connection.rollback();
        logger.error('Migration failed', { filename, error: error.message });
        throw error;
      }
    }

    console.log('Migrations complete.');
  } catch (error) {
    console.error('Migration run failed:', error.message);
    process.exitCode = 1;
  } finally {
    await connection.end();
  }
})();
