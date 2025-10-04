# Subscription Invoice PDF Template

The billing service generates PDFs under `storage/invoices/` using the structure below. Finance teams can customize branding by updating the PDF generation helper without altering this contract.

## Layout Overview
1. **Header**
   - Nokta logo (injected downstream), document title "Subscription Invoice".
   - Invoice number, tenant name, plan & billing cycle, issue date, due date.
2. **Billing Period Summary**
   - Start and end dates for the covered cycle.
   - Current grace window end (computed in UI using plan metadata).
3. **Line Items Table**
   - Columns: Description, Qty, Unit Price, Tax %, Line Total.
   - Default row: `<Plan Name> plan (<period range>)` with quantity 1.
   - Additional rows permitted for add-ons (SMS packs, extra devices, onboarding fees).
4. **Totals Footer**
   - Subtotal, Tax, Grand Total (currency derived from subscription).
   - Optional notes block for finance messages (e.g., banking instructions).
5. **Payment Instructions**
   - Supported gateways (Stripe card URL, bank transfer reference, cash settlement steps).
   - Contact email/phone for billing support.

## Data Mapping
| PDF Field | Source |
| --- | --- |
| Invoice Number | `subscription_invoices.invoice_number` |
| Tenant Name | `tenants.name` (fallback to `Tenant <id>`) |
| Plan Name | Billing plan metadata (`billing_service.fetchPlanById`) |
| Billing Cycle | `tenant_subscriptions.billing_cycle` |
| Period Dates | `subscription_invoices.period_start` / `period_end` |
| Amounts | Calculated totals from line items payload |
| Notes | `subscription_invoices.notes` |
| QR/Barcode (optional) | Add via downstream integrator (e.g., payment link) |

## Branding Guidelines
- Margin: 40 pt, fonts default to system sans-serif.
- Insert tenant logo (if available) in header right corner; fallback to Nokta logotype.
- Use bilingual labels when Arabic locale requested (left-to-right switching supported by UI layer).
- Keep file naming `INV-YYYYMMDD-#####.pdf` to align with audit and reconciliation scripts.

## Automation Hooks
- After generation, PDF path saved in `subscription_invoices.pdf_path` for download via the billing API.
- Webhooks may include secure download URL referencing the stored file.
- Finance automation can append digital signature page as part of downstream processing.

## QA Checklist
- Verify totals match sums from line items (unit price * qty + tax).
- Confirm localized currency symbol and thousand separators per tenant preference.
- Ensure invoice regenerates correctly when rerun with same number (idempotent).
- Confirm PDF stored once; repeated runs overwrite the same file to prevent duplicates.
