# Database Migration Scripts

This directory stores the ordered PostgreSQL migration scripts that support the cutover described in `MIGRATION_REPORT.md`.

## Conventions
- Name files using the pattern `YYYYMMDDHHMM__description.sql`.
- Each script must be idempotent and include both `-- up` and `-- down` sections.
- Use `SET search_path` for tenant-aware schemas when needed.
- Record data fixes in separate scripts suffixed with `_data_fix` to differentiate from structural changes.

## Tooling
- Primary execution uses the built-in Node.js runner (`npm run migrate`) inside the deployment pipeline.
- Local testing can call `make migrate` which shells out to the same runner against the developer Docker Compose stack.

## Checklist
1. Lint SQL with `sqlfluff` prior to committing.
2. Update `DB_SCHEMA.md` when structural changes modify public contracts.
3. Attach migration IDs to release notes and cutover runbooks.
4. Ensure every file contains `-- up` and `-- down` sections so the runner can parse it.
