# Service Integration Points

This baseline describes how the core services exchange data after introducing the unified feature flag gateway.

## POS ↔ Core Services

| Flow | Requester | Responder | Transport | Notes |
| --- | --- | --- | --- | --- |
| POS startup configuration | POS Flutter app | Feature Flag API (`/api/v1/feature-flags`) | HTTPS | Fetch evaluated flags (`pos.offlineQueue`, `pos.enhancedReceipts`) before rendering optional UI. |
| Order submission | POS app | Orders service (`/api/v1/orders`) | HTTPS | Feature flag `pos.offlineQueue` toggles offline persistence and sync banners. |
| Receipt printing | POS app | Print service | Local queue + HTTPS | Toggle `pos.enhancedReceipts` to enable compact/QR layouts. |
| Dynamic price evaluation | POS app | Dynamic pricing API (`/api/v1/pricing/dynamic/evaluate`) | HTTPS | Gate via `platform.dynamicPricing`; returns `{ price, applied }` summary for UI and receipts. |

## Call Center ↔ Orders

- **Preconditions**: Express router enforces `requireFeatureFlag('callCenter.routing')`, JWT auth, and tenant validation.
- **Queue snapshots**: Redis key pattern `call_center:queue:{tenantId}` stores waiting callers; TTL 1h.
- **Order creation**: Validated payload sent to `/api/v1/orders` with channel metadata `call_center`.
- **Metrics**: Dashboard endpoint `/api/v1/call-center/dashboard` aggregates Redis + MySQL statistics.

## Billing ↔ Finance

| Flow | Trigger | Endpoint | Feature Flag |
| --- | --- | --- | --- |
| Subscription CRUD | Admin portal | `/api/v1/billing/subscriptions` (POST/PATCH) | `billing.saas` |
| Invoice issue | Finance automation | `/api/v1/billing/invoices` (POST) | `billing.saas` |
| Payment capture | Webhooks | `/api/v1/billing/gateways/webhook` | Always on, but downstream actions require flag enabled. |

## Dynamic Pricing ↔ Commerce & Apps

| Flow | Requester | Responder | Notes |
| --- | --- | --- | --- |
| Adjustment CRUD | Admin portal | `/api/v1/pricing/dynamic` (POST/PUT/DELETE) | Requires `platform.dynamicPricing`; payload validated with Joi and stored in Redis overrides. |
| Adjustment listing | Admin/manager UI | `/api/v1/pricing/dynamic` (GET) | Combines seed config + tenant overrides; supports `includeExpired` filter. |
| Customer price display | Customer app | `/api/v1/pricing/dynamic/evaluate` | Optional; Flutter clients may use cached adjustments via `DynamicPricingService`. |

## Driver Logistics

- Drivers consume `/api/v1/orders` assignments and stream telemetry (unchanged).
- Feature flag `driver.dynamicTracking` can be evaluated in mobile apps once the route uses the new API to orchestrate adaptive sampling.

## Admin & Ops

- Admin dashboard remains at `/api/v1/admin/dashboard/*` and is unaffected by gating.
- System monitoring endpoints continue under `/api/v1/system/*`.
- Feature flag overrides are updated via `/api/v1/feature-flags/:flagKey` (admin-only) with Redis persistence.

## Feature Flag API Contract Summary

| Method & Path | Description | Auth | Query Parameters | Body |
| --- | --- | --- | --- | --- |
| `GET /api/v1/feature-flags` | List evaluated flags for current tenant or global scope | JWT | `scope` (`tenant`/`global`), `tenantId`, `includeMetadata`, `branchId`, `role`, `userId` | – |
| `GET /api/v1/feature-flags/:flagKey` | Fetch single flag | JWT | `scope`, `tenantId` | – |
| `PUT /api/v1/feature-flags/:flagKey` | Upsert override | Admin JWT | `scope`, `tenantId` | `{ enabled: bool, rollout: { strategy, ... }, notes? }` |
| `DELETE /api/v1/feature-flags/:flagKey` | Remove override | Admin JWT | `scope`, `tenantId` | – |

Responses wrap data as `{ data: [...], scope, tenantId, generatedAt }` for list, and include `evaluation`, `activeSource`, `rollout`, and metadata required by client runtime.

## Message security

- All service calls share tenant context through `X-Tenant-ID` headers and the tenant validation middleware.
- Feature flag middleware logs blocked access to surface misconfiguration without leaking details to clients (returns 404 by default).

For operational procedures (flag lifecycle, rollback) reference `FEATURE_FLAGS_PLAYBOOK.md`.
