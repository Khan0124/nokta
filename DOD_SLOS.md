# Definition of Done & Service-Level Objectives

## Cross-Cutting Definition of Done
For any feature or fix to be considered complete it must:
1. **Design Alignment:** User stories include bilingual UX copy (ar/en), accessibility notes, and affected personas.
2. **Code Quality:** Changes pass linting/formatting, include unit/integration tests, and follow architecture guidelines (layered services, providers, feature flags).
3. **Observability:** Telemetry (logs, metrics, traces) updated to expose success/failure counts and latency for the affected workflow.
4. **Documentation:** Update relevant runbooks/guides plus changelog notes in the tenant release bulletin.
5. **Operational Readiness:** Rollback steps documented; feature flags or toggles available for controlled rollout.
6. **Security & Privacy:** Secrets managed via environment variables/vault, data handling reviewed against privacy policies.

## Service-Level Objectives by Domain
| Domain | SLO | Measurement | Monitoring |
|--------|-----|-------------|------------|
| POS | Invoice creation ≤ **1.5s**; receipt print ≤ **2s** | API latency (P95) + printer job duration | POS performance dashboard with offline queue depth |
| Call Center | Call intake to order submission ≤ **30s** | Workflow timer from call start event to order persisted | Call queue metrics in admin dashboard + alert at 85% budget |
| Driver App | Location update propagation ≤ **5s** in-city | Timestamp difference between driver GPS ping and dispatch board update | Driver telemetry stream with error budget alerts |
| Customer App | Order status refresh ≤ **4s** | P95 latency of `/orders/{id}` polling + push notification lag | Customer experience observability board |
| Admin Dashboard | Widget refresh latency ≤ **3s**; exports ready ≤ **10s** | API response times + job completion metrics | BI service metrics and export job queue monitor |
| Billing | Invoice generation ≤ **5s**; payment confirmation ≤ **8s** | Billing job runtime + payment gateway webhook confirmation | Finance observability with SLA alerts |
| Notifications | Delivery success ≥ **98%** | Vendor delivery receipts vs attempts | Notification service success rate panel |

## Error Budget & Response
- Each domain maintains a 30-day rolling error budget equal to 1 - target availability (e.g., POS 99.5% ⇒ 3h 36m downtime/month).
- Breaching 50% of the monthly budget triggers a production readiness review and freezes non-critical feature releases for that domain.

## Review Cadence
- **Weekly:** SLO dashboard review in operations meeting; capture follow-up actions.
- **Monthly:** Cross-functional DoD health check; audit sample stories for compliance.
- **Quarterly:** Executive report summarizing uptime, incident trends, and improvement roadmap.

## Tooling Alignment
- Integrate SLO metrics into the centralized Prometheus + Grafana stack with bilingual alert templates.
- Automate deployment checklists via CI to ensure DoD gates before merge.
