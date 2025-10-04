# Dynamic Pricing & Availability Guide

This guide explains how tenant teams configure temporary offers, availability overrides, and price adjustments using the new dynamic pricing stack.

## 1. Concepts

- **Adjustment** – A tenant-scoped rule that targets specific products or categories with either a fixed price, percentage discount, or availability toggle.
- **Channels** – Client surfaces (`pos`, `customer`, `delivery`) that the adjustment applies to. Channels are evaluated per request so the POS can run different offers than the customer app.
- **Windows** – Optional `startAt` and `endAt` timestamps enforce when an adjustment is active. Adjustments without windows remain active until disabled.
- **Priority & Stackability** – Priorities resolve conflicts (lower value wins). Non-stackable rules exit after the first match, while stackable rules apply sequentially.

## 2. Feature Flag

The entire API is wrapped with the `platform.dynamicPricing` feature flag. Finance or platform administrators must enable the flag per tenant before agents can manage offers.

## 3. API Endpoints

| Operation | Method & Path | Notes |
| --- | --- | --- |
| List adjustments | `GET /api/v1/pricing/dynamic` | Supports `includeExpired` and `branchId` filters. |
| Create adjustment | `POST /api/v1/pricing/dynamic` | Joi validation ensures pricing windows, product targeting, and numeric bounds. |
| Update adjustment | `PUT /api/v1/pricing/dynamic/:id` | Partial updates allowed; status can be set to `disabled` or `archived`. |
| Archive adjustment | `DELETE /api/v1/pricing/dynamic/:id` | Soft archive keeps historical data and audit references. |
| Evaluate price | `POST /api/v1/pricing/dynamic/evaluate` | Returns `{ price, applied, available }` for UI displays and receipt generation. |

All mutations persist in Redis overrides with audit metadata (`updatedBy`, `updatedAt`) and hydrate from the base config (`backend/config/dynamic_pricing.json`).

## 4. Workflow

1. **Design** – Merchandising team defines the offer: products, discount type, channels, and window.
2. **Create** – Admin user submits the adjustment via the dashboard or API. Validation rejects invalid ranges or overlapping IDs beyond the configured maximum.
3. **Monitor** – The POS highlights active offers via Riverpod providers and the admin dashboard's *Dynamic Pricing Adoption* widget/export confirms uptake, influenced revenue, and channel coverage.
4. **Expire** – Allow the end date to elapse or set `status=archived` via the API to remove the adjustment from evaluation.

## 5. Flutter Client Usage

- `DynamicPricingService` seeds sample adjustments for offline demos and resolves prices locally when the API is unavailable.
- `dynamicPricingAdjustmentsProvider` fetches active adjustments and exposes them to UI components.
- `productDynamicPriceProvider` returns the evaluated price for a product so cards, carts, and receipts stay in sync.
- POS surfaces chips summarising active offers once the feature flag is enabled.

## 6. Data Storage

- **MySQL**: `dynamic_price_adjustments` and `dynamic_pricing_audit_events` tables track persistent configuration and history.
- **Redis**: Caches tenant overrides for fast evaluation and stores runtime adjustments between deployments.

For enablement runbooks, reference `FEATURE_FLAGS_PLAYBOOK.md`. For schema details, consult `database/nokta_pos_complete.sql`.
