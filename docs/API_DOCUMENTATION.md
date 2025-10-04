# Nokta Platform API Reference

The API surface for Nokta's POS, call center, billing, feature flag, and onboarding services is defined in [`openapi.yaml`](openapi.yaml). This document summarises the most frequently used endpoints and explains how to work with the generated specification.

## Getting Started

1. **Authenticate** by exchanging credentials for a JWT:
   ```http
   POST /api/v1/auth/login
   Content-Type: application/json

   {
     "username": "admin",
     "password": "admin123"
   }
   ```
2. **Attach headers** to every subsequent request:
   - `Authorization: Bearer <jwt>`
   - `X-Tenant-ID: <tenant_id>`
3. **Explore the spec**:
   ```bash
   cd backend
   npm install
   npm run docs:openapi
   ```
   The command validates `../docs/openapi.yaml` using `swagger-cli`. Import the file into Swagger UI, Stoplight, or Redoc for interactive exploration.

## Service Overview

| Domain | Base Path | Key Endpoints |
| --- | --- | --- |
| Authentication | `/api/v1/auth` | `POST /login`, `POST /refresh` |
| Call Center | `/api/v1/call-center` | `GET /queue`, `GET /dashboard`, `POST /orders` |
| Billing | `/api/v1/billing` | `GET /plans`, `POST /subscriptions`, `POST /payments` |
| Feature Flags | `/api/v1/feature-flags` | `GET /`, `PATCH /{key}`, `DELETE /{key}` |
| Dynamic Pricing | `/api/v1/pricing/dynamic` | `GET /adjustments`, `POST /adjustments`, `PATCH /adjustments/{id}` |
| Admin Dashboard | `/api/v1/admin/dashboard` | `GET /overview`, `GET /pricing/adoption`, `GET /orders/trends` |
| Tenant Onboarding | `/api/v1/tenants/onboarding` | `POST /`, `PATCH /{token}`, `POST /{token}/complete` |

## Example Payloads

### Feature Flag Override
```json
{
  "enabled": true,
  "rollout": {
    "strategy": "percentage",
    "percentage": 50
  },
  "notes": "Gradual rollout for call_center_console"
}
```

### Dynamic Pricing Adjustment
```json
{
  "name": "Lunch Special",
  "type": "percentage",
  "value": 15,
  "channels": ["pos", "customer"],
  "branchIds": [1, 4],
  "startAt": "2025-01-05T10:00:00Z",
  "endAt": "2025-01-05T15:00:00Z"
}
```

### Tenant Onboarding Step Update
```json
{
  "step": "billing",
  "payload": {
    "planId": "pro",
    "billingCycle": "monthly",
    "paymentMethodId": "pm_123"
  }
}
```

### Call Queue Response
```json
{
  "tenantId": 42,
  "count": 2,
  "results": [
    {
      "id": "+966555123456-0",
      "callerNumber": "+966555123456",
      "displayName": "Hassan Al Qahtani",
      "status": "waiting",
      "priority": 92,
      "waitingSince": "2025-10-03T13:47:12.000Z",
      "customerId": 12,
      "lastOrderId": 894,
      "preferredBranchId": 1,
      "loyaltyPoints": 980
    }
  ]
}
```

### Dynamic Pricing Adoption Snapshot
```json
{
  "summary": {
    "totalOrders": 420,
    "discountedOrders": 118,
    "adoptionRate": 28.1,
    "totalDiscountValue": 936.5,
    "averageDiscount": 7.93,
    "influencedRevenue": 5820.75
  },
  "adjustments": {
    "total": 12,
    "byStatus": {
      "active": 8,
      "scheduled": 3,
      "disabled": 1
    },
    "channelCoverage": {
      "pos": 9,
      "customer": 6,
      "delivery": 4
    }
  },
  "trends": [
    { "date": "2024-02-01", "orders": 45, "discountedOrders": 12, "discounts": 95.4, "influencedRevenue": 310.2 }
  ],
  "range": {
    "start": "2024-02-01",
    "end": "2024-02-29"
  }
}
```

## Error Model

Errors follow a consistent structure:

```json
{
  "success": false,
  "code": "CALL_CENTER_QUEUE_NOT_FOUND",
  "message": "No queue snapshot available for tenant",
  "details": {
    "tenantId": 42
  }
}
```

Refer to the individual path definitions in `openapi.yaml` for exhaustive status codes and schema references.
