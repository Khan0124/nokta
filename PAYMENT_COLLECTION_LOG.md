# Payment Collection Log Standard Operating Procedure

## Objective
Ensure every subscription payment—automated or manual—is captured with consistent metadata so finance can reconcile Stripe, local bank, and cash settlements.

## Required Fields
| Field | Description | Source |
| --- | --- | --- |
| `invoiceId` | Invoice receiving the payment | `/billing/.../invoices/:invoiceId` |
| `provider` | `stripe`, `local_bank`, or `cash` | Payment gateway used |
| `reference` | Gateway confirmation code or cash receipt number | Provided by gateway/finance |
| `amount` | Amount collected (decimal) | Operator input |
| `currency` | ISO 4217 (default `USD`) | Subscription currency |
| `status` | `pending`, `succeeded`, `failed`, `refunded` | Gateway response |
| `paidAt` | Timestamp of settlement | Finance timestamp |
| `metadata` | JSON map for notes (collector, branch, etc.) | Optional |

## Capture Workflow
1. Finance or support agent confirms receipt from gateway or bank statement.
2. Agent hits `POST /billing/subscriptions/:subscriptionId/invoices/:invoiceId/payments` with the table above.
3. System records entry in `subscription_payments` and updates invoice `amount_paid`.
4. If amount reaches invoice total, status flips to `paid`; otherwise remains `open`.
5. For partial payments, repeat process for remaining balance referencing same invoice.

## Local Bank Settlements
- Include `metadata.settlementBatch` with bank file reference.
- Set `status` to `pending`; webhook or manual update marks `succeeded` once bank confirms.
- Attach scanned bank slip to your document management system and note path in metadata.

## Cash Collections
- Use sequential cash receipt numbers maintained by finance.
- `metadata.collectedBy` must reference staff ID; `metadata.branchId` ties to location.
- Deposit confirmation (e.g., bank-in slip) appended as follow-up metadata once verified.

## Refunds & Adjustments
- Triggered via gateway-specific flows (`stripe` refund API, manual bank transfer, or cash disbursement).
- After issuing refund, call the payment endpoint with negative `amount` or set `status`=`refunded` and include `metadata.refundReference`.
- System will adjust `amount_paid` accordingly; verify outstanding balance recalculates.

## Audit Practices
- Export `subscription_payments` weekly and reconcile with ledger.
- Retain logs for minimum seven years; ensure timezone stored in UTC.
- Finance manager reviews random sample (5%) each month for compliance with SOP.

Following this SOP creates a traceable collection history aligned with Nokta’s billing policy and audit requirements.
