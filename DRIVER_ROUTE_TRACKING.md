# Driver Route Tracking Blueprint

The driver application now records high-fidelity GPS breadcrumbs for every active assignment. This document summarizes the data model, sync workflow, and operational dashboards.

## Data Pipeline
1. **Assignment Sync** – When a driver logs in, pending `driver_tasks` are hydrated from the API and cached locally via `DriverTaskService`.
2. **Dynamic GPS Sampling** – `DriverLocationTracker` adjusts the `Geolocator` interval based on current speed (45s while idle, 20s in city traffic, 5s on highways) to balance accuracy with battery usage.
3. **Local Persistence** – Each reading is stored in SQLite (`driver_route_points`) with speed, heading, accuracy, and sampling interval metadata. The same point is broadcast to UI widgets for live telemetry.
4. **Sync & Backfill** – When connectivity is available, batches of unsynced route points are published to the backend API (one payload per task). Server-side ingestion populates MySQL tables with identical schemas for reporting.

## Key Tables
| Store | Table | Purpose |
| --- | --- | --- |
| SQLite | `driver_tasks` | Offline cache of assignments and collection requirements |
| SQLite | `driver_route_points` | Breadcrumb trail captured offline |
| MySQL | `driver_tasks` | System-of-record for dispatch and finance |
| MySQL | `driver_route_points` | Long-term telemetry archive for SLA audits |

## KPIs Tracked
- Average update interval per assignment.
- Distance covered per task vs. SLA path.
- Driver idle time (no movement for ≥5 minutes).
- GPS accuracy anomalies (accuracy > 75m).

## Operational Notes
- Route resets occur automatically when an order is marked *delivered* or *failed* (future points are stored under new task IDs).
- If permissions are denied, the tracker falls back to simulated coordinates and flags telemetry as `status = simulated` so supervisors can intervene.
- Clearing a task deletes local breadcrumbs (`DriverTaskService.clearRoutePoints`) but preserves server history after sync.
