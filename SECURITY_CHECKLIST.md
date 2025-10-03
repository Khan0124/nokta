# Security Checklist

This checklist captures the hardened baseline for the Nokta platform and the recurring tasks that keep the environment compliant.
Use it before every release and as part of the monthly security review.

## 1. Identity & Access Management
- [x] Password hashing uses bcrypt with configurable cost (`BCRYPT_ROUNDS`).
- [x] Password complexity enforced through validation (min length 8, upper/lower/numeric/symbol).
- [x] Account lockout enabled after repeated failures (`ACCOUNT_LOCK_THRESHOLD`, `ACCOUNT_LOCK_DURATION`).
- [x] Failed login attempts expire automatically (`FAILED_ATTEMPT_WINDOW`).
- [x] Session inactivity timeout enforced in middleware (`SESSION_INACTIVITY_TIMEOUT`).
- [x] Sessions tracked in Redis with token binding, IP/user-agent fingerprinting, and blacklist support.
- [x] Role-based access control and permission checks via middleware.
- [ ] Multi-factor authentication for privileged roles (planned).

## 2. API & Application Hardening
- [x] Helmet HTTP headers + strict CSP/HSTS.
- [x] Global body size limits (`MAX_FILE_SIZE`).
- [x] Input sanitisation middleware on every request.
- [x] Rate limiting for all APIs plus stricter auth limiter.
- [x] Tenant/branch access validation middleware.
- [ ] CSRF tokens for browser-based flows (track separately).

## 3. Logging, Monitoring & Alerting
- [x] Centralised structured logging with rotation (Winston + daily rotate files).
- [x] Dedicated audit log stream for compliance events (`logs/audit-*.log`).
- [x] Security logger records login, lockout, and permission anomalies.
- [x] Request metrics middleware captures latency/error indicators when `ENABLE_METRICS=true`.
- [x] Operational alerts generated for high error rates, slow routes, and memory pressure.
- [ ] Forward logs to external SIEM (Splunk/ELK) with retention ≥ 90 days.
- [ ] Configure alert webhooks to on-call (PagerDuty/Slack).

## 4. Data Protection
- [x] Database credentials sourced from environment variables (`DB_*`).
- [x] Redis secured with password and TLS-ready configuration.
- [x] Automated database backups (`BACKUP_ENABLED=true`) with retention policy (`BACKUP_RETENTION_DAYS`).
- [ ] At-rest encryption for backup artifacts (`BACKUP_ENCRYPTION_KEY`).
- [ ] Secrets rotated quarterly and stored in dedicated secrets manager.

## 5. Infrastructure & Operations
- [x] Health endpoint exposes aggregated DB/Redis status.
- [x] `/api/v1/system` routes require admin/manager roles.
- [x] Backup run/purge endpoints restricted to admins and audited.
- [x] Graceful shutdown handlers registered for SIGINT/SIGTERM.
- [ ] Implement disaster recovery failover test (bi-annually).
- [ ] Penetration test booked at least once per year.

## 6. Review Cadence
- Weekly: review security logs + open alerts.
- Monthly: execute backup restore rehearsal (see `BACKUP_RESTORE_RUNBOOK.md`).
- Quarterly: validate access reviews, rotate secrets, evaluate new OWASP guidance.
- Release: run this checklist, ensure all `[ ]` items have documented risk acceptance if unresolved.
