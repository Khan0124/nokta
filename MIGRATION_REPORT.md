# Migration & Cutover Plan

## Objectives
- Ensure a safe transition from the legacy Nokta stack to the modularized platform without disrupting POS, call center, driver, customer, or billing operations.
- Preserve historical data fidelity and auditability while enabling shadow validation for every core workflow.
- Provide rollback and contingency procedures that keep stores and support teams productive during the cutover window.

## Environment Matrix
| Environment | Purpose | Data Source | Cutover Role |
|-------------|---------|-------------|--------------|
| Legacy Prod | Current live traffic | Legacy DB (MySQL) | Source of truth until final switch |
| New Prod    | Target production cluster | New PostgreSQL + Redis | Receives mirrored traffic during shadow phase and becomes primary at cutover |
| Staging     | Full dress rehearsals | Sanitized clone of legacy | Validates migration scripts, reconciliations, and application behavior |
| QA Sandbox  | Exploratory testing | Synthetic fixtures | Validates automated tests and training scenarios |

## Data Mapping Summary
| Legacy Table | New Structure | Notes |
|--------------|---------------|-------|
| `pos_orders` | `orders`, `order_items`, `order_payments` | Split orders into normalized tables; payment gateway reference now stored in `order_payments` |
| `customers` | `customers`, `customer_addresses`, `customer_loyalty_balances` | Addresses and loyalty balances separated for multi-address and program support |
| `drivers` | `drivers`, `driver_tasks`, `driver_routes`, `driver_settlements` | Adds task lifecycle tracking and settlement records |
| `call_logs` | `call_center_calls`, `call_queue_events` | Tracks queue transitions for SLA analytics |
| `invoices` | `billing_invoices`, `billing_payments`, `billing_plan_quotas` | Supports multi-channel payment capture and usage quotas |

See `DB_SCHEMA.md` for the complete target schema definitions.

## Migration Workstreams
1. **Schema & Scripts**
   - Maintain versioned migration scripts in `database/migrations` (new directory) with idempotent up/down steps.
   - Use `pgloader` templates for initial bulk copy; post-load SQL normalizes data (UUID generation, tenant scoping, default flags).
2. **Integration Alignment**
   - Update service configuration to read from feature flags so POS, call center, driver, and billing services can be flipped independently.
   - Verify third-party integrations (payments, SMS, maps) via sandbox credentials in staging before the parallel run.
3. **Validation Automation**
   - Build reconciliation jobs that compare record counts, hashes of financial totals, and sample spot checks per tenant.
   - Extend monitoring dashboards to overlay legacy vs new metrics (orders/minute, payment success, driver ETA drift).

## Test Strategy
- **Unit & Contract Tests:** All services must pass automated suites with coverage on new data access layers.
- **Sample Order Journeys:** Execute scripted journeys for POS, call center, customer app, and driver app using production-like data subsets.
- **Financial Reconciliation:** Compare invoice totals, tax, discounts, and settlement sums for the last 90 days.
- **Performance Benchmarks:** Confirm SLO readiness (POS invoice ≤ 1.5s, call center order ≤ 30s, driver update ≤ 5s, dashboard ≤ 3s).

## Parallel Run (Shadow / Canary)
1. **Shadow Phase (Days -7 to -3)**
   - Mirror read traffic into the new stack; compare API responses and log deltas in observability dashboards.
   - Run nightly reconciliations; any variance >0.5% triggers remediation and rerun.
2. **Canary Phase (Days -2 to -1)**
   - Route 10% of POS and call center sessions plus a pilot driver cohort to the new stack via feature flags.
   - Monitor latency, error budgets, and manual QA feedback hourly; roll back canary scope if two consecutive failures occur.

## Cutover Day Timeline
| Time (UTC) | Activity | Owner |
|------------|----------|-------|
| 02:00      | Freeze legacy writes (POS offline-first queue enabled) | Operations Lead |
| 02:10      | Final delta sync and reconciliation sign-off | Data Engineering |
| 02:30      | Update DNS / load balancer to new stack | DevOps |
| 02:45      | Enable feature flags for all tenants | Release Manager |
| 03:00      | Lift freeze, monitor SLO dashboards | Incident Commander |
| 06:00      | Executive checkpoint + publish status report | Program Manager |

## Rollback Plan
- Keep legacy infrastructure hot for 48 hours with write paths ready.
- Maintain export of new system changes (orders, payments, driver events) to replay into legacy if rollback triggered.
- Rollback triggers: SLO breach exceeding 30 minutes, reconciliation variance >1%, or critical security flaw discovered.
- Rollback execution: re-point DNS/load balancers, disable new feature flags, replay queued offline POS orders to legacy, notify stakeholders.

## Communication & Training
- Daily standups during migration week with cross-functional leads.
- Publish migration playbook and real-time status in Slack `#cutover-warroom` channel.
- Provide store managers and call center supervisors with quick reference cards covering offline mode, escalation paths, and language support.

## Post-Cutover Checklist
- Run full data reconciliation at T+4 hours, T+24 hours, and T+72 hours.
- Conduct post-incident review within 5 business days capturing lessons learned.
- Transition to steady-state operations after two weeks of stable metrics and stakeholder sign-off.
