# Tenant Self-Service Onboarding Playbook

The self-service onboarding funnel allows new restaurant tenants to configure a production-ready workspace in under five minutes. This guide explains the milestones, API workflow, and operational checkpoints for support and success teams.

## Experience Overview

1. **Kick-off (≈45 seconds)** – Prospects provide their brand details, contact information, and preferred subscription tier. The API issues a short-lived onboarding token that expires after 30 minutes.
2. **Company profile (≈60 seconds)** – Legal and storefront details are captured, including timezone, industry, and go-live expectations.
3. **Branch bootstrapping (≈60 seconds)** – The primary branch is registered with address, contact channels, and default opening hours.
4. **Owner account (≈75 seconds)** – The primary administrator selects their username, password, and notification preferences. Passwords are hashed immediately and never persisted in plaintext.
5. **Billing preferences (≈30 seconds)** – Optional step to define billing cadence, tax ID, and finance contacts.
6. **Completion (≈30 seconds)** – After accepting the terms, the workflow provisions a tenant, main branch, administrative user, and a starter subscription with a 7-day trial.

> **Goal:** A motivated operator with data on hand can finish the entire sequence in approximately 4 minutes.

## API Workflow

| Step | Endpoint | Method | Payload Highlights |
|------|----------|--------|---------------------|
| Start session | `/api/v1/tenants/onboarding/start` | `POST` | `companyName`, `contactName`, `contactEmail`, `contactPhone`, `subscriptionPlan` |
| Fetch status | `/api/v1/tenants/onboarding/{token}` | `GET` | Path parameter `token` |
| Submit step | `/api/v1/tenants/onboarding/{token}/steps` | `POST` | `stepKey` (`company_profile`, `branch_setup`, `owner_account`, `billing_preferences`), arbitrary `payload`, optional `status` |
| Complete | `/api/v1/tenants/onboarding/{token}/complete` | `POST` | `acceptTerms` (must be `true`), optional `billingCycle` override |

### Token lifetime

Onboarding tokens expire after **30 minutes** of inactivity. Expired sessions respond with HTTP `410` so the UI can prompt operators to restart without losing previously submitted data (persisted steps remain accessible through the summary endpoint).

## Step Payload Templates

### Company profile
```json
{
  "legalName": "Al Nokta Bistro",
  "tradeName": "Nokta Bistro",
  "domain": "noktabistro.example",
  "industry": "Restaurant",
  "country": "SD",
  "city": "Khartoum",
  "address": "Street 12, Block 5",
  "timezone": "Africa/Khartoum",
  "currency": "SDG",
  "employeesCount": 24,
  "posDevices": 4,
  "goLiveDate": "2025-02-01"
}
```

### Branch setup
```json
{
  "branchName": "Main Branch",
  "branchAddress": "Street 12, Block 5",
  "branchPhone": "+249912345678",
  "openingTime": "09:00",
  "closingTime": "23:30",
  "allowPickup": true,
  "deliveryRadiusKm": 8
}
```

### Owner account
```json
{
  "fullName": "Samar Hassan",
  "email": "samar@example.com",
  "phone": "+249911112233",
  "username": "samar",
  "password": "N0kta!POS2025",
  "preferredLanguage": "ar"
}
```

### Billing preferences (optional)
```json
{
  "billingCycle": "monthly",
  "paymentMethod": "invoice",
  "taxId": "TAX-5566",
  "needInvoice": true,
  "financeContactName": "Mahmoud Idris",
  "financeContactEmail": "finance@example.com"
}
```

## Completion Output

Upon successful completion the API response includes:

- Final onboarding session payload with all step statuses and progress metrics.
- Provisioned `tenantId`, `branchId`, and `userId` references.
- Confirmation that an admin user, main branch, and a `tenant_subscriptions` record were generated. The subscription defaults to the plan selected in the kickoff and a monthly billing cycle unless overridden.

### Failure Scenarios

| Scenario | Response |
|----------|----------|
| Token not found | `404 NOT_FOUND_ERROR` |
| Token expired | `410 ONBOARDING_EXPIRED` |
| Required step missing | `409` with descriptive message |
| Terms not accepted | `400 ONBOARDING_TERMS_REQUIRED` |
| Owner password missing | `400 ONBOARDING_OWNER_PASSWORD_MISSING` |

## Operational Checklist

- Monitor the **`tenant_onboarding_events`** table for `session_completed` rows to trigger welcome emails and data-import offers.
- Track conversion funnels with weekly exports: start > step progression > completion.
- Expired sessions remain in the database for auditing; agents can revive them by cloning payloads into a new token via admin tooling (future enhancement).
- When billing creation fails (e.g., payment gateway offline), the session still finalizes; finance receives an alert via the warning log entry so they can follow up manually.

## Support Playbook

1. If a tenant reports an expired link, call the start endpoint again and pre-fill previously submitted details from the latest session payload.
2. For owner password resets before first login, delete the admin row created during onboarding and re-run the owner step via API to hash a new password.
3. Use the onboarding summary endpoint during demos to show live progress across branches or markets.

## Change Log

- **2025-10-03** – Initial rollout with automated tenant, branch, user, and subscription provisioning plus 30-minute auto-expiry.

