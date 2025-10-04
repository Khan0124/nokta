# Call Center Operations Guide

This guide describes the day-to-day workflow for the Nokta call center team, the tooling available in the Call Center MVP, and the metrics leadership should monitor.

## Console Deployment

The Flutter-based console lives at `apps/call_center_app` and can be launched in development with:

```bash
cd apps/call_center_app
flutter pub get
flutter run -d chrome
```

Enable the `call_center_console` feature flag before distributing a build. The UI consumes the feature flag service and hides functionality when the toggle is disabled for the tenant.

## 1. Agent Workflow Overview

1. **Incoming call pops** inside the call center console with the caller ID and auto-checks the Redis queue for existing entries.
2. **Search** using the global search field (phone, alternate phone, or customer name) to view profile matches and recent orders.
3. **Verify the customer profile**:
   - Confirm contact details and preferred language.
   - Pin or update the default delivery address when necessary.
4. **Review recent orders** to understand preferences, loyalty points, or open issues.
5. **Create the order** using the guided order form:
   - Add or update cart line items.
   - Capture delivery instructions and scheduled time windows.
   - Choose payment method (cash, card, mobile money, bank transfer).
6. **Assign branch automatically** (nearest active branch or forced override for VIP/overflow scenarios).
7. **Confirm totals** and log any upsell/discount campaigns.
8. **Close the call** by updating the call disposition (completed, callback, abandoned, voicemail, spam) and recording quick notes.
9. **Queue clean-up** automatically removes the caller from the active queue once the order is captured or the call is dispositioned.

## 2. Screen Breakdown

| Area | Purpose |
| --- | --- |
| Call Queue Banner | Shows active/queued calls pulled from Redis with agent assignment. |
| Customer Profile Drawer | Consolidated customer identity, loyalty metrics, and preferred addresses. |
| Order Composer | Item list, modifiers, fees, discounts, and payment capture. |
| Timeline & Notes | Chronological call notes, callbacks, and past tickets. |
| KPI Sidebar | Real-time handle time, wait time, and SLA attainment for the current shift. |

## 3. Logging Calls

Use the `POST /api/v1/call-center/calls` endpoint to capture the full life cycle of a call. Always populate:

- `status` (`queued`, `active`, `completed`, `abandoned`, `scheduled`).
- `disposition` for post-call analysis.
- `waitTimeSeconds` and `handleTimeSeconds` to power SLA reporting.
- `tags` for campaign tracking (e.g., `vip`, `late_delivery`, `complaint`).

If the database is temporarily unavailable, call records are cached in Redis for 24 hours so that no call is lost. A background job should replay these fallback entries once the database is restored.

## 4. Creating Orders from Calls

- Submit the payload to `POST /api/v1/call-center/orders` with customer, item, delivery, payment, and metadata blocks.
- Orders default to the closest active branch using branch coordinates. Agents can override with an explicit `branchId` when needed.
- The service generates call-center specific order numbers (`CC-<branch>-<timestamp>`) to separate them from POS traffic.
- When the call record identifier is passed in `callId`, the call is automatically closed and linked to the new order.
- If MySQL is unreachable, the order request is serialized to Redis with SLA-compliant metadata so supervisors can reconcile once connectivity returns.

## 5. Real-time Metrics

| KPI | Definition | Target |
| --- | --- | --- |
| Average Handle Time (AHT) | Mean of `handle_time_seconds` for completed calls in the selected window. | ≤ 300 seconds |
| Average Wait Time | Mean of `wait_time_seconds` while customers wait in queue. | ≤ 45 seconds |
| Service Level | % of calls answered within 30 seconds (`wait_time_seconds ≤ 30`). | ≥ 85% |
| Queue Length | Active + queued calls awaiting assignment. | ≤ 5 concurrent calls |
| Callbacks Scheduled | Count of calls tagged `callback` in the range. | Monitor trend |
| Orders Created | Number of `call_center` sourced orders in the range. | Track conversion |

All KPIs are returned by the `GET /api/v1/call-center/dashboard` endpoint. The dashboard accepts filters for `range` (`today`, `7d`, `30d`) and `branchId` so supervisors can drill down.

## 6. Performance Benchmarks

- Call center UI should create an order in **≤ 30 seconds** from customer verification to confirmation.
- Agents should disposition a call within **10 seconds** after hang up.
- Callback records must be scheduled with a time window before the call ends.

## 7. Escalation & Quality Assurance

1. Tag calls needing escalation with `vip` or `complaint` and notify the shift supervisor.
2. Supervisors should audit at least **5 calls per agent per week** by reviewing call notes and the associated orders.
3. Export call center metrics weekly for BI review and SLA compliance.

---

For API payload examples and integration hooks, reference the backend route documentation in `backend/server/routes/call_center.js`.
