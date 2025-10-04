# Database Schema Summary

## 1. MySQL (Backend)
| Table | Purpose | Key Fields |
| --- | --- | --- |
| `tenants` | Tenant metadata, subscription, contact info | `status`, `subscription_plan`, `settings` |
| `branches` | Physical branches per tenant with geo coordinates | `tenant_id`, `latitude`, `longitude`, `opening_time` |
| `users` | Tenant administrators and staff accounts | `tenant_id`, `role`, `permissions`, `is_active` |
| `customers` | Unified customer profile | `tenant_id`, `phone`, `preferred_branch_id`, `loyalty_points` |
| `customer_addresses` | Saved delivery locations | `customer_id`, `label`, `latitude`, `longitude`, `is_default` |
| `orders` | Order header for POS/app/call center | `tenant_id`, `order_number`, `status`, `payment_status`, geo delivery fields |
| `order_items` | Order line items | `order_id`, `product_id`, `quantity`, `unit_price`, `modifiers` |
| `call_center_calls` | Call logging for agents | `tenant_id`, `phone`, `status`, `disposition`, `wait_time_seconds` |
| `call_center_queue_events` | Queue timeline for calls | `call_id`, `event_type`, `agent_id`, timestamps |
| `driver_tasks` | Driver assignments with settlement metadata | `driver_id`, `order_id`, `status`, `requires_collection`, payment fields |
| `driver_route_points` | High-frequency GPS breadcrumb trail | `task_id`, `latitude`, `longitude`, `speed_kph`, `interval_seconds` |
| `driver_settlements` | End-of-shift settlement snapshots | `driver_id`, `shift_start`, `total_due`, `collected_cash`, `pending_remittance` |
| `tenant_onboarding_sessions` | Self-service onboarding lifecycle | `token`, `status`, `current_step`, `expires_at` |
| `tenant_onboarding_steps` | Per-step payloads & completion status | `session_id`, `step_key`, `status`, `completed_at` |
| `tenant_onboarding_events` | Audit log of onboarding progress | `session_id`, `event_type`, `actor_type`, timestamps |

### Indices & Constraints
- Foreign keys tie `driver_tasks` to `orders`, `branches`, and `tenants` for multi-tenant isolation.
- `driver_route_points` indexed on `task_id` and `recorded_at` to feed live navigation & reporting.
- `driver_settlements` indexed on (`shift_start`, `shift_end`) for efficient payout queries.

## 2. Flutter Local SQLite (`LocalDB`)
| Table | Purpose | Key Fields |
| --- | --- | --- |
| `products` | Cached product catalog | `tenant_id`, `category_id`, availability flags |
| `categories` | Hierarchical product categories | `tenant_id`, `parent_id`, `sort_order` |
| `orders` | Offline order header cache | `tenant_id`, `status`, totals |
| `order_items` | Offline order detail lines | `order_id`, `product_id`, pricing |
| `order_item_modifiers` | Customizations per item | `order_item_id`, name, price |
| `users` | Staff cache | `tenant_id`, `role`, contact details |
| `tenants` | Tenant configuration snapshot | limits, enabled features |
| `cart_items` | Offline cart buffer | `product_id`, `quantity`, notes |
| `cart_item_modifiers` | Modifiers in cart | `cart_item_id`, `type`, `price` |
| `offline_queue` | Durable event queue for POS | `type`, payload JSON, retry counters |
| `driver_tasks` | Offline driver assignments | `driver_id`, `order_id`, `status`, collection fields |
| `driver_route_points` | Offline breadcrumb store | `task_id`, `latitude`, `longitude`, `recorded_at` |
| `driver_settlements` | Local settlement cache | `driver_id`, `total_due`, `pending_remittance` |

### Sync & Offline
- `driver_tasks`/`driver_route_points` tables are hydrated via REST and enriched with local GPS telemetry for offline-first navigation.
- Settlements are generated locally via `DriverTaskService.closeShift()` and synced once connectivity returns.
- Existing `offline_queue` still brokers POS actions; driver updates use dedicated tables to avoid flooding the general queue.

## 3. Alignment Tasks
1. Generate migrations for the new driver tables (`driver_tasks`, `driver_route_points`, `driver_settlements`) across MySQL and SQLite, ensuring idempotent creation.
2. Expose `driver_settlements` in analytics exports (admin dashboards & finance reconciliation).
3. Document API payload contracts for driver assignment sync to keep mobile/web clients aligned.
