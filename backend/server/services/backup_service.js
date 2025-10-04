const fs = require('fs');
const fsp = require('fs/promises');
const path = require('path');
const { spawn } = require('child_process');
const config = require('../../config/config');
const { auditLogger } = require('../../config/logger');

const ensureBackupDirectory = async () => {
  if (!config.backup.enabled) {
    return null;
  }

  await fsp.mkdir(config.backup.directory, { recursive: true });
  return config.backup.directory;
};

const listBackups = async () => {
  if (!config.backup.enabled) {
    return {
      enabled: false,
      files: [],
      message: 'Automated backups are disabled. Set BACKUP_ENABLED=true to activate.'
    };
  }

  await ensureBackupDirectory();
  const entries = await fsp.readdir(config.backup.directory, { withFileTypes: true });

  const files = await Promise.all(entries
    .filter(entry => entry.isFile())
    .map(async (entry) => {
      const filePath = path.join(config.backup.directory, entry.name);
      const stats = await fsp.stat(filePath);

      return {
        name: entry.name,
        sizeMb: Number((stats.size / (1024 * 1024)).toFixed(2)),
        createdAt: stats.birthtime.toISOString(),
        modifiedAt: stats.mtime.toISOString()
      };
    }));

  return {
    enabled: true,
    directory: config.backup.directory,
    retentionDays: config.backup.retentionDays,
    schedule: config.backup.schedule,
    verificationSchedule: config.backup.verificationSchedule,
    files: files.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
  };
};

const getBackupPlan = () => ({
  enabled: config.backup.enabled,
  directory: config.backup.directory,
  retentionDays: config.backup.retentionDays,
  schedule: config.backup.schedule,
  verificationSchedule: config.backup.verificationSchedule,
  encryptionEnabled: Boolean(config.backup.encryptionKey)
});

const buildCommandPlan = (destination) => {
  const executable = process.env.MYSQLDUMP_PATH || 'mysqldump';

  const args = [
    '-h', config.database.host,
    '-P', String(config.database.port),
    '-u', config.database.user,
    '--single-transaction',
    '--quick',
    '--routines',
    config.database.name
  ];

  return {
    executable,
    args,
    destination,
    envHints: {
      MYSQL_PWD: '<set via environment>'
    }
  };
};

const createDatabaseBackup = async ({ initiatedBy, dryRun = false } = {}) => {
  if (!config.backup.enabled) {
    return {
      executed: false,
      enabled: false,
      message: 'Automated backups are disabled. Set BACKUP_ENABLED=true to activate.'
    };
  }

  await ensureBackupDirectory();

  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const filename = `backup-${timestamp}.sql`;
  const destination = path.join(config.backup.directory, filename);
  const commandPlan = buildCommandPlan(destination);

  const shouldExecute = !dryRun && process.env.ENABLE_RUNTIME_BACKUPS === 'true';

  if (!shouldExecute) {
    return {
      executed: false,
      enabled: true,
      dryRun,
      destination,
      plan: commandPlan,
      instructions: [
        'Set MYSQL_PWD in the environment before running the backup command.',
        `Run: ${commandPlan.executable} ${commandPlan.args.join(' ')} > ${destination}`,
        'Store the generated file in secure, off-site storage.'
      ]
    };
  }

  const env = { ...process.env };
  if (config.database.password) {
    env.MYSQL_PWD = config.database.password;
  }

  await new Promise((resolve, reject) => {
    const outStream = fs.createWriteStream(destination, { flags: 'w' });
    const child = spawn(commandPlan.executable, commandPlan.args, {
      env,
      stdio: ['ignore', 'pipe', 'pipe']
    });

    child.stdout.pipe(outStream);

    let stderr = '';
    child.stderr.on('data', (chunk) => {
      stderr += chunk.toString();
    });

    child.on('close', (code) => {
      outStream.close();
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(stderr || `Backup command exited with code ${code}`));
      }
    });

    child.on('error', reject);
  });

  auditLogger.info('database_backup_created', {
    destination,
    initiatedBy,
    retentionDays: config.backup.retentionDays
  });

  return {
    executed: true,
    enabled: true,
    dryRun,
    destination,
    sizeMb: Number(((await fsp.stat(destination)).size / (1024 * 1024)).toFixed(2)),
    retentionDays: config.backup.retentionDays
  };
};

const purgeExpiredBackups = async () => {
  if (!config.backup.enabled) {
    return {
      enabled: false,
      removed: 0,
      message: 'Automated backups are disabled.'
    };
  }

  await ensureBackupDirectory();
  const files = await listBackups();
  const now = Date.now();
  const retentionMs = config.backup.retentionDays * 24 * 60 * 60 * 1000;

  let removed = 0;

  for (const file of files.files) {
    const age = now - new Date(file.createdAt).getTime();
    if (age > retentionMs) {
      await fsp.unlink(path.join(config.backup.directory, file.name));
      removed += 1;
    }
  }

  if (removed > 0) {
    auditLogger.info('database_backup_purged', {
      removed,
      retentionDays: config.backup.retentionDays
    });
  }

  return {
    enabled: true,
    removed,
    remaining: removed > 0 ? (await listBackups()).files.length : files.files.length
  };
};

module.exports = {
  ensureBackupDirectory,
  listBackups,
  getBackupPlan,
  createDatabaseBackup,
  purgeExpiredBackups
};
