# Feature Flags Playbook

## 1. Definitions

- **Default configuration**: `backend/config/feature_flags.json` declares long-lived toggles with owner, rollout strategy, and environments.
- **Environment overrides**: `FEATURE_FLAGS` env var (JSON) allows quick overrides per deployment without code changes.
- **Runtime overrides**: Redis-backed updates applied through `/api/v1/feature-flags/:flagKey`.
- **Evaluation context**: Tenant, branch, role, user, and session feed the deterministic SHA-1 bucketing algorithm for percentage rollouts.
- **Commerce toggles**: `platform.dynamicPricing` wraps the new pricing API and prevents runtime evaluation until finance approves the rollout per tenant.

## 2. Roles & permissions

| Action | Role | API |
| --- | --- | --- |
| View evaluated flags | Any authenticated user | `GET /api/v1/feature-flags` |
| Toggle tenant-level flag | Admin | `PUT /api/v1/feature-flags/:flagKey?scope=tenant` |
| Toggle global flag | Admin | `PUT /api/v1/feature-flags/:flagKey?scope=global` |
| Remove override | Admin | `DELETE /api/v1/feature-flags/:flagKey` |

All updates are audited with actor ID, timestamp, notes, and stored rollout metadata.

## 3. Change workflow

1. **Plan**: Document intent (flag name, target cohort, rollback) in JIRA/Notion.
2. **Prepare**: Ensure flag exists in `feature_flags.json` with description, owner, strategy.
3. **Validate**: Use staging tenant to exercise `GET /api/v1/feature-flags` and confirm evaluated results.
4. **Rollout**: Apply override via API, optionally targeting percentage or specific roles/branches.
5. **Monitor**: Check application logs (`Feature gate blocked request`) and metrics dashboards for errors.
6. **Finalize**: When feature is stable, backfill default config and remove runtime override.

## 4. API usage examples

```bash
# List flags for current tenant
curl -H "Authorization: Bearer <token>" \
  -H "X-Tenant-ID: 42" \
  https://api.nokta-pos.com/api/v1/feature-flags

# Enable loyalty program for tenant 42
curl -X PUT \
  -H "Authorization: Bearer <admin-token>" \
  -H "Content-Type: application/json" \
  "https://api.nokta-pos.com/api/v1/feature-flags/customer.loyalty?tenantId=42" \
  -d '{"enabled": true, "rollout": {"strategy": "percentage", "percentage": 50}, "notes": "A/B wave 1"}'

# Remove override
curl -X DELETE \
  -H "Authorization: Bearer <admin-token>" \
  "https://api.nokta-pos.com/api/v1/feature-flags/customer.loyalty?tenantId=42"
```

## 5. Client considerations

- Flutter apps should call `featureFlagsProvider` during bootstrap and use `featureFlagEnabledProvider(flagKey)` to guard UI.
- Riverpod refresh helper (`featureFlagRefreshProvider`) can be invoked on pull-to-refresh or logout to clear cached flags.
- Offline-first modules must assume flags may change between sessions; avoid caching beyond the service TTL (5 minutes by default).
- POS screens should hide dynamic pricing chips and evaluation calls unless `featureFlagEnabledProvider('platform.dynamicPricing')` resolves to `true`.

## 6. Incident response

- If a misconfigured flag blocks critical flows, use the DELETE endpoint to fall back to defaults.
- For widespread incidents, use the environment variable override (`FEATURE_FLAGS='{"flag.key":{"enabled":false}}'`) and restart the pod.
- Always document the incident in the operations channel and update the flag notes for traceability.

## 7. Auditing

- Redis stores overrides with `updatedBy`, `updatedByName`, `updatedAt`, and optional notes.
- API responses include `sources` metadata so clients and dashboards can expose the current authority (default/environment/global/tenant).
- Regularly export the evaluated list via `/api/v1/feature-flags?includeMetadata=true` for compliance snapshots.
