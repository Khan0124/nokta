# Driver Location Privacy & Telemetry Policy

This policy outlines how the Nokta driver experience collects, stores, and uses location information for delivery operations.

## 1. Data Collected
- **Real-time GPS coordinates** while an assignment is active.
- **Speed, heading, accuracy, and sampling interval** for quality analytics.
- **Shift settlement totals** (cash collected, pending remittance).
- No background location is collected when a driver is off-shift or has no active tasks.

## 2. Purpose of Processing
- Route optimization and live customer ETA updates.
- Proof-of-delivery audits and SLA compliance monitoring.
- Calculating driver payouts and reconciling cash-on-delivery collection.

## 3. Storage & Retention
- Mobile devices cache route points locally and sync them to the Nokta cloud once connectivity resumes.
- Synced telemetry is stored in the `driver_route_points` table with tenant isolation.
- Raw GPS points are retained for 90 days; aggregated reports persist for 12 months.

## 4. Access Controls
- Only authenticated operations staff and tenant admins with the *Driver Operations* role can view live tracking dashboards.
- API responses redact customer PII unless the viewer has explicit permissions.
- Device-level permissions are requested at runtime; the app degrades gracefully when denied (no hidden tracking).

## 5. Driver Rights
- Drivers can pause tracking by ending their shift within the app.
- Support can export or delete the past 90 days of telemetry upon driver request.
- Any policy change triggers an in-app notice requiring explicit acknowledgement before the next shift.

## 6. Compliance Checklist
- [x] Location services disabled state handled with user messaging.
- [x] Permission denial fallback implemented (no background collection).
- [x] TLS enforced for all telemetry uploads.
- [ ] Data Protection Impact Assessment to be completed before production launch.
