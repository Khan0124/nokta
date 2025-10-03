# Admin Dashboard Operations Guide

## Purpose
The admin dashboard consolidates real-time business performance KPIs for franchise owners and branch managers. It surfaces live sales, open order pipelines, driver fleet efficiency, and payment health so leadership can respond in seconds, not hours.

## Real-time Widgets
| Widget | KPI Focus | Refresh Cadence | Notes |
| --- | --- | --- | --- |
| Sales Overview | Total / today sales, average order value, discounts, delivery fees | 15s polling with WebSocket push fallback | Applies tenant currency from branch settings |
| Active Orders | Preparing, ready, on-way counts plus cancellations | 10s polling; exposes drill-down link to order board | Branch filter required for multi-location tenants |
| Payments Mix | Cash vs card/mobile wallet volume and pending/failed payment counts | 30s polling | Trigger alert if pending payments > 5% of orders |
| Top Products | Quantity and revenue for top 5 items | Manual refresh & hourly scheduled snapshot | Supports seasonal campaign tagging |
| Driver Performance | Delivered vs exception tasks, average delivery time, remittance backlog | 60s polling (driver telemetry updates) | Highlight drivers with >10 pending remittance |

## Filters & Date Ranges
* **Tenant scope:** enforced by JWT + `X-Tenant-ID` header. Every response echoes applied tenant/branch filters.
* **Branch filter:** optional query parameter or header; defaults to authenticated branch.
* **Date range:** ISO timestamps; if omitted, defaults to rolling 24 hours.
* **Granularity:** `hour`, `day`, `week`, or `month` for time-series charts.

## Role-based Access
| Role | Default Widgets | Export Permissions |
| --- | --- | --- |
| Admin | All widgets | Overview, Sales, Orders, Drivers |
| Manager | Sales Overview, Active Orders, Payments Mix, Driver Performance | Overview, Sales, Orders |
| Cashier | Active Orders only | None |

Access policies are enforced through the `/api/v1/admin/dashboard/widgets/defaults` endpoint which maps roles to widget IDs and report types.

## Operational Playbook
1. **Morning Brief (Admin):** Pull overview report, confirm sales vs forecast, scan pending payments.
2. **Mid-day Service (Manager):** Monitor active orders and driver performance; escalate if average delivery minutes > 35.
3. **End of Day (Admin/Finance):** Export sales and orders previews, reconcile remittance backlog, archive PDFs to finance folder.
4. **Incident Response:** If cancellations spike >10% within an hour, switch to order drill-down and alert call center supervisor.

## Alert Thresholds
* Pending payments ratio > 5% triggers finance notification.
* Active driver exceptions > 3 per branch triggers operations Slack alert.
* Discounts exceeding 15% of total sales flags marketing lead for approval.

## Data Quality & Audit
* All responses include `generatedAt` timestamps for traceability.
* Service logs warn when schema tables are missing (useful for staging/test parity).
* Add automated integration tests to verify query plans once analytics warehouse is wired.

## Next Steps
* Wire front-end widgets to new endpoints via authenticated fetch with tenant headers.
* Schedule BI exports via cron once S3 credentials are provisioned.
* Extend driver module with heatmap view fed by `driver_route_points` aggregates.
