# Nokta POS SaaS – Discovery & Audit Report

## 1. Overview
- **Scope**: Backend Node.js/Express API, Flutter multi-app clients (POS, kitchen, driver, customer, admin), shared `nokta_core` package, infrastructure scripts.
- **Environment**: Monorepo with Docker orchestration, MySQL, Redis, Nginx, monitoring stack. Flutter apps rely on shared `nokta_core` for models/providers/services.
- **Audit Focus**: Code inventory, dependency mapping, database schema inspection, initial performance notes, gap assessment, and immediate recommendations.

## 2. Code & Service Inventory
| Area | Key Modules | Notes |
| --- | --- | --- |
| Backend (`backend/`) | Express routes, auth middleware, MySQL pool, Redis client, Socket.IO real-time hooks | `server.js` is monolithic; routes/middleware aggregated directly; needs modularization. |
| Database assets | `database/nokta_pos_complete.sql` (partial), `backend/database` migrations, Flutter local SQLite (`LocalDB`) | SQL dump is truncated (only tenants/branches tables). Flutter local DB more complete and used for offline caching. |
| Flutter apps (`apps/`) | POS, kitchen display, driver, customer, admin panel | POS & kitchen app were Arabic-hardcoded prior to i18n work. Riverpod for state, shared `nokta_core` exports. |
| Shared package (`packages/core`) | Models, providers (cart, categories, products, order), services (order/product/print/sync), utilities | Prior stubs replaced with functional offline queue, print, sync services. |
| DevOps (`docker-compose*`, `monitoring/`, `nginx/`) | Docker compose definitions, Nginx configs, monitoring stack manifests | Compose includes MySQL, Redis, backend, Flutter web? Additional review required for prod deployment. |

### Dependencies & Integrations
- **DB**: MySQL 8 (backend), SQLite via `sqflite` for local offline data in Flutter.
- **Cache & Realtime**: Redis, Socket.IO; Flutter uses polling placeholders (needs integration).
- **Printing**: Flutter `printing` & `pdf` packages; enhanced PrintService manages templates and network failures.
- **Payments**: Placeholder service in backend; no concrete provider yet.
- **Maps/GPS**: `geolocator`, `google_maps_flutter` in `nokta_core`, not fully wired.
- **Notifications**: Hooks exist via `RealtimeService` stub; requires completion.

## 3. Database Observations
- `database/nokta_pos_complete.sql` only defines `tenants` and `branches` with comment referencing missing remainder. Needs regeneration or retrieval of full schema.
- Flutter `LocalDB` defines comprehensive tables (products, categories, orders, order_items, offline_queue, etc.). See [`DB_SCHEMA.md`](DB_SCHEMA.md).
- No migration scripts beyond SQL dump; recommend versioned migrations (e.g., Sequelize, Knex) for backend.

## 4. Performance Notes (Initial)
| Operation | Status |
| --- | --- |
| POS screen load | Not benchmarked (UI-only audit). Suggested to instrument using Flutter `performance_overlay` / custom timers. |
| Order creation | Offline queue added; actual API latency unmeasured. Need instrumentation + backend profiling. |
| Receipt printing | New PrintService builds PDF once per job; network retry via queue. Need end-to-end test on actual printer. |
| Heavy queries | Backend lacks EXPLAIN/indices plan. Recommend analyzing orders/products endpoints, ensure pagination & indexes. |

## 5. Gap Analysis & Duplications
- **Internationalization**: Previously hard-coded Arabic UI strings; resolved for POS + kitchen but other apps still pending.
- **Offline Support**: Sync service stubbed before; now implemented with offline queue. Backend lacks endpoints for queued event reconciliation (needs design).
- **Database Consistency**: SQL dump incomplete. LocalDB and backend schema divergence risk.
- **Testing**: Minimal automated tests. No integration/unit coverage for new services.
- **Logging/Monitoring**: Backend uses `morgan`; central logging/observability not configured in codebase.
- **Security**: JWT auth present but role enforcement coarse. Need auditing of RBAC + password policies.
- **Code Structure**: Backend monolith vs desired microservices separation (POS/orders/catalog etc.).
- **Duplicated Logic**: Pricing/tax/discount calculations previously scattered; now centralized in cart provider but backend still needs parity.

## 6. Immediate Recommendations
1. **Schema Source of Truth**: Regenerate full MySQL schema & migrations; align with Flutter LocalDB structure.
2. **Service Modularization**: Break backend into feature modules or microservices per architecture baseline. Introduce controller/service layers and shared DTOs.
3. **Instrumentation**: Add metrics (timers, Prometheus exporters) for POS actions, sync throughput, printing latency.
4. **Testing Pipeline**: Introduce unit tests for cart calculations, sync/print services, and backend routes. Add CI checks.
5. **Security Hardening**: Enforce env-based secrets (already recommended) and rate-limiting per service. Review password/session policies (see SECURITY_CHECKLIST.md once created).
6. **Documentation**: Maintain updated API docs (OpenAPI), developer onboarding, and runbooks. Ensure new guides (i18n, POS operations) referenced in README.
7. **Data Consistency**: Design backend endpoints to acknowledge offline queue replay (idempotent order creation, conflict resolution).
8. **Monitoring**: Hook existing monitoring stack (Prometheus/Grafana) into newly exposed metrics and set alert thresholds.

---
_Last updated: 2025-10-02T10:58:36Z_
