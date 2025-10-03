# Architecture Decisions Baseline

_Last updated: 2025-10-03_

## 1. Layered solution structure

- **Presentation layer**: Flutter clients (POS, Driver, Customer) and the Express REST API transport. All UI components communicate via typed Riverpod providers and consume REST/real-time services.
- **Domain services layer**: Business logic grouped by capability (POS, Orders, Catalog, Call Center, Drivers, Billing, Notifications). Each service owns orchestration, validation, and integration with shared utilities.
- **Infrastructure layer**: Cross-cutting concerns (MySQL, Redis, logging, metrics, feature flags, backup tooling) exposed as singleton managers and injected into services.
- Each capability has a documented service contract and owns its persistence schema slice as captured in `DB_SCHEMA.md`.

## 2. Service boundaries & API contracts

| Service | Responsibility | Key Contracts |
| --- | --- | --- |
| **POS** | Order authoring, offline queue, printing | `/api/v1/orders`, `/api/v1/feature-flags` for runtime toggles |
| **Catalog** | Products, categories, pricing | `/api/v1/products`, `/api/v1/categories` |
| **Call Center** | Assisted ordering, Redis queueing, KPIs | `/api/v1/call-center/*` (feature gated) |
| **Driver** | Task assignment, telemetry, settlements | `/api/v1/orders`, WebSocket telemetry |
| **Billing** | Subscriptions, invoicing, payments | `/api/v1/billing/*` (feature gated) |
| **Admin Dashboard** | Analytics, reports | `/api/v1/admin/dashboard/*` |
| **System & Ops** | Health, metrics, backups | `/api/v1/system/*` |

API inputs are validated with Joi schemas in `backend/middleware/validation.js` and mapped to DTOs in their services. The Flutter apps consume the same contracts through `packages/core` service facades.

## 3. Feature flag governance

- **Central config**: Default toggles live in `backend/config/feature_flags.json` and are merged with environment overrides (`FEATURE_FLAGS` env var) and Redis-scoped overrides.
- **Evaluation service**: `backend/server/services/feature_flag_service.js` provides deterministic evaluation (percentage, role, branch strategies) with tenant- and global-scope overrides persisted in Redis.
- **Delivery**: Authenticated `/api/v1/feature-flags` endpoints supply evaluated flags to clients. Express middleware `requireFeatureFlag` gates server routes; Flutter consumers use `featureFlagEnabledProvider`.
- **Auditability**: Overrides capture actor, timestamp, rollout metadata, and feed back through the API for transparency.

## 4. Cross-cutting decisions

- **Caching**: Redis powers feature flag overrides, call center queues, and session management. TTLs prevent stale data and guard resources.
- **Observability**: Request logging, metrics middleware, and backup services remain mandatory for all services. Feature gating logs denied access with `logger.warn` to surface misconfiguration quickly.
- **Security**: All protected routes enforce JWT auth, role checks, tenant validation, and—where applicable—feature flag gating before reaching business logic.
- **Client runtime config**: `packages/core` exposes a single `FeatureFlagService` to hydrate Riverpod providers so Flutter apps react to toggles without redeploying.

## 5. Rollout & fallback principles

1. Every new capability must ship behind a named feature flag defined in `feature_flags.json`.
2. Default rollout is `all`; partial rollouts must specify strategy metadata (percentage, roles, branches).
3. Server routes must use `requireFeatureFlag` for optional capabilities to avoid exposing unfinished features.
4. Front-end experiences should guard UI paths with `featureFlagEnabledProvider` to keep UX consistent with server enforcement.
5. Overrides require admin credentials via `/api/v1/feature-flags/:flagKey` and are traceable for compliance.

Refer to `SERVICE_INTEGRATION_POINTS.md` for inter-service message flows and to `FEATURE_FLAGS_PLAYBOOK.md` for operational procedures.
