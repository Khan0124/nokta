# Monitoring Stack Setup

This guide explains how to run the Prometheus + Grafana stack that ships with Nokta and how to expose backend metrics.

## 1. Prerequisites

- Docker & Docker Compose installed.
- The backend must run with `ENABLE_METRICS=true` so the `/api/v1/system/metrics/prometheus` endpoint is available.
- Redis and the Node backend should be reachable from the monitoring network (the default compose files handle this automatically).

## 2. Start the Monitoring Services (Development)

```bash
# from the repository root
ENABLE_METRICS=true docker compose --profile monitoring up prometheus grafana redis-exporter -d
```

This command starts:
- **Prometheus** reading configuration from `monitoring/prometheus.yml`.
- **Grafana** with the bundled dashboards and an admin password of `admin` (change after first login).
- **Redis Exporter** forwarding cache metrics.
- **Node Exporter** runs outside of Compose with host networking when the `monitoring` profile is selected (Linux/macOS only).

Access Grafana at http://localhost:3000 (user: `admin`, password: `admin`). The default Prometheus datasource is pre-provisioned.

## 3. Production Deployment

The production compose file already includes Prometheus and Grafana services. Enable them by supplying the monitoring profile and secure credentials:

```bash
ENABLE_METRICS=true GRAFANA_PASSWORD=<strong-password> docker compose -f docker-compose.prod.yml \
  --profile monitoring up -d prometheus grafana redis-exporter
```

Prometheus stores data under the `prometheus_data` volume while Grafana persists dashboards in `grafana_data`.

## 4. Exposed Dashboards

Two dashboards are provisioned automatically:

| Dashboard | Purpose |
| --- | --- |
| `Platform Overview` | HTTP request totals, error rate, and route latency aggregates. |
| `Call Center Operations` | Latency and volume for call-center API endpoints plus trending request counts. |

The JSON definitions live in `monitoring/grafana/dashboards/` and are version controlled. Modify them locally and reload Grafana to roll out changes.

## 5. Alerting Hooks

Prometheus exposes its configuration at `monitoring/prometheus.yml`. Add alerting rules or remote write targets by extending that file. After editing run:

```bash
docker compose restart prometheus
```

Grafana alerting can be configured from the UI using the provisioned Prometheus datasource.

## 6. Troubleshooting

- Verify the backend exposes Prometheus metrics by running `curl http://localhost:3001/api/v1/system/metrics/prometheus` with valid authentication headers.
- Ensure `ENABLE_METRICS=true` is present in the backend environment; otherwise the endpoint returns `404`.
- The redis exporter requires the Redis password; adjust `REDIS_PASSWORD` in Compose if you changed it.
- On macOS the Node exporter needs additional permissions. Use `sudo` when starting the stack if you see permission errors.
