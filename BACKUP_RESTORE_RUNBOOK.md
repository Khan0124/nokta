# Backup & Restore Runbook

This runbook documents how Nokta captures, stores, verifies, and restores production data. Review monthly and after any major infrastructure change.

## 1. Configuration Summary
- **Automatic schedule**: `BACKUP_SCHEDULE` (default `0 3 * * *`, 03:00 UTC daily).
- **Verification schedule**: `BACKUP_VERIFICATION_SCHEDULE` (default `0 6 1 * *`, first day of month).
- **Retention**: `BACKUP_RETENTION_DAYS` (default 30 days).
- **Storage path**: `BACKUP_DIRECTORY` (default `backend/backups`).
- **Execution toggle**: set `BACKUP_ENABLED=true` and `ENABLE_RUNTIME_BACKUPS=true` in production.
- **Secrets**: database credentials pulled from environment; never hard-code passwords.

## 2. Automated Flow
1. Scheduler (cron/k8s job) calls `POST /api/v1/system/backups/run` with admin token.
2. API writes `backup-<timestamp>.sql` to the configured directory and logs to `logs/audit-*.log`.
3. Nightly job replicates the artifact to off-site storage (S3/Blob) with server-side encryption.
4. Separate cron invokes `POST /api/v1/system/backups/purge` weekly to enforce retention.
5. Monitoring job polls `GET /api/v1/system/alerts` for backup-related warnings.

## 3. Manual Backup Procedure
1. Authenticate as an admin and obtain a JWT.
2. (Optional dry run) `POST /api/v1/system/backups/run?dryRun=true` to preview the command.
3. Execute `POST /api/v1/system/backups/run` to trigger an on-demand backup.
4. Verify the response includes `executed: true` and file size.
5. Run `GET /api/v1/system/backups` to confirm the new artifact is listed.
6. Upload the file to secure storage and annotate ticket with audit log ID.

## 4. Monthly Restore Rehearsal
1. Select the most recent backup from `GET /api/v1/system/backups`.
2. Provision an isolated staging database (never restore into production directly).
3. Export credentials to environment variables:
   ```bash
   export MYSQL_PWD=<staging_password>
   ```
4. Restore:
   ```bash
   mysql -h <host> -P <port> -u <user> <database> < backup-YYYY-MM-DDTHH-MM-SS.sql
   ```
5. Run smoke tests:
   - `SELECT COUNT(*) FROM orders;`
   - `SELECT COUNT(*) FROM users WHERE role='admin';`
   - Execute API smoke suite against staging.
6. Document results and attach to monthly operations report.

## 5. Disaster Recovery Checklist
- [ ] Confirm latest automated backup succeeded (audit log + artifact).
- [ ] Validate off-site replica is present and decryptable.
- [ ] Ensure application secrets vault is accessible.
- [ ] Verify infrastructure-as-code (Terraform/Kubernetes) plan is up to date.
- [ ] Run `GET /api/v1/system/health` to ensure database/redis healthy post-restore.

## 6. Incident Response
1. Declare incident, assign commander and scribe.
2. Identify last known good backup (review audit log + metrics).
3. Restore into clean environment following Section 4.
4. Re-point application traffic only after verification checklist passes.
5. Capture root cause, timeline, and remediation actions within 48 hours.

## 7. Reporting & KPIs
- **Recovery Point Objective (RPO)**: ≤ 24 hours (daily backups).
- **Recovery Time Objective (RTO)**: ≤ 2 hours for database restore.
- Track success metrics in admin dashboard or ops sheet:
  - Last backup timestamp.
  - Last verified restore timestamp.
  - Number of retained backups vs. policy.
  - Size trend to anticipate storage growth.

Maintain this runbook in version control and update whenever schedules, tooling, or infrastructure change.
