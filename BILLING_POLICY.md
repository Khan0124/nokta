# Billing Suspension & Reactivation Policy

## Purpose
This policy defines how Nokta POS manages subscription lifecycles, including grace periods, suspension triggers, reactivation rules, and communication requirements for tenants on the Basic, Pro, and Premium plans.

## Key Terms
- **Billing Cycle** – Monthly or yearly term selected per tenant subscription.
- **Grace Window** – Additional days after an unpaid invoice where service remains accessible with reminders.
- **Suspension** – Read-only mode where mission-critical services stay online, but updates and premium features are restricted.
- **Reactivation** – Restoring full service after payment confirmation or manual override.

## Grace Periods
| Plan | Monthly Grace | Yearly Grace | Default Trial |
| --- | --- | --- | --- |
| Basic | 5 days | 10 days | 7 days |
| Pro | 7 days | 14 days | 14 days |
| Premium | 10 days | 21 days | 21 days |

- Grace timers begin at invoice due date.
- During grace, system raises in-app banners, emails billing contacts, and escalates to WhatsApp/SMS on the final day.

## Suspension Rules
1. **Automatic Suspension**
   - Triggered when grace window lapses without a confirmed payment.
   - POS remains operational in offline-first mode, but sync and reporting pause.
   - Driver and customer apps restrict new orders; existing deliveries finish normally.
2. **Manual Suspension**
   - Admins may suspend tenants for compliance reasons via the billing console.
   - Manual suspensions bypass the grace window and require a reason code logged in the audit trail.

## Reactivation Workflow
1. Payment posts via supported gateways (Stripe, local bank, or cash) or finance approves manual override.
2. Billing team uses `/billing/subscriptions/:id` PATCH endpoint to set status back to `active`; resume date recalculates the current period.
3. System triggers resync of cached data (inventory, loyalty, analytics) and clears suspension banners.
4. A confirmation email and in-app notification acknowledge restored access.

## Communication Cadence
- **T-5 days (pre-due):** Reminder email with outstanding amount and invoice link.
- **Due date:** POS banner + email.
- **Grace mid-point:** Finance receives Slack alert; call center script updated for billing inquiries.
- **Final day of grace:** WhatsApp/SMS + auto-generated task for billing specialist.
- **Suspension:** Customer success phone call + support ticket for follow-up within 4 hours.

## Data & Audit Requirements
- All suspension events recorded in `tenant_subscriptions.meta` with actor, timestamp, and reason.
- Invoice PDFs stored under `storage/invoices/` with immutable filenames for audit.
- Payment logs maintained via `/billing/.../payments` API and mirrored in the `subscription_payments` table.

## Exceptions & Overrides
- Executive approval required to extend grace periods beyond defaults (documented in the payment log).
- Seasonal closures can request a pause: set status to `suspended` with future `resumeAt` date; billing cycle is prorated on reactivation.
- Delinquent accounts older than 45 days escalate to finance for potential offboarding.

## Responsibilities
- **Finance Ops:** Monitor dunning dashboard, reconcile bank settlements, trigger manual reactivations.
- **Support:** Communicate status changes to tenants, ensure POS teams understand read-only limitations.
- **Engineering:** Maintain billing services uptime, secure webhook processing, and accurate reporting.

Adhering to this policy ensures consistent tenant experience while protecting recurring revenue streams.
