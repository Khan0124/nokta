# Driver Performance & Settlement Report Template

Use this template to produce daily/weekly driver summaries combining delivery SLAs, collection results, and routing analytics.

## Header
- **Driver:** {{driver_name}} (ID {{driver_id}})
- **Shift Window:** {{shift_start}} → {{shift_end}}
- **Total Assignments:** {{assignment_count}}
- **Completed Deliveries:** {{completed_count}}
- **Failed / Cancelled:** {{failed_count}}

## SLA Metrics
| Metric | Target | Actual | Status |
| --- | --- | --- | --- |
| Average order cycle time | ≤ 30 min | {{avg_cycle_time}} | {{status}} |
| Pickup confirmation latency | ≤ 5 min | {{pickup_latency}} | {{status}} |
| Navigation telemetry coverage | ≥ 95% | {{telemetry_coverage}} | {{status}} |
| Customer-rated score | ≥ 4.5 | {{customer_rating}} | {{status}} |

## Cash Reconciliation
| Item | Amount |
| --- | --- |
| Cash collected | {{cash_collected}} |
| Digital payments | {{digital_collected}} |
| Pending remittance | {{pending_remittance}} |
| Variance (system vs. reported) | {{variance}} |

## Route Insights
- Longest leg: {{longest_leg_distance}} km ({{longest_leg_order}})
- Idle pockets (>5 minutes stationary): {{idle_events}}
- Average speed vs. posted limits: {{avg_speed_vs_limit}}

## Follow-up Actions
- [ ] Schedule coaching session for SLA deviations
- [ ] Flag for incentive payout
- [ ] Investigate cash variance
- Notes: {{notes}}

## Data Sources
- Mobile SQLite (`driver_tasks`, `driver_route_points`, `driver_settlements`)
- Backend analytics warehouse (`driver_route_points`, `orders`, `driver_settlements`)

> Export as PDF/CSV and attach to the `DRIVER_SETTLEMENTS` entity for finance approval.
