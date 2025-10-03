# Nokta POS – Functional & Offline Test Plan

## 1. Test Environment
- **Build**: Latest POS Flutter app with offline queue + localization branches merged.
- **Data seed**: Load demo tenant with 200 products, tiered pricing, coupons, and historical orders for return scenarios.
- **Hardware**: Android tablet, iPad (optional), USB/Bluetooth barcode scanner, network printer (Epson TM-m30 or similar).
- **Network profiles**: Stable Wi-Fi, throttled 3G (300 kbps), and offline (airplane mode) to validate sync retries.

## 2. Core Functional Scenarios
| ID | Scenario | Steps | Expected |
| --- | --- | --- | --- |
| POS-001 | Localized UI boot | Launch app in English and Arabic | All strings translated; layout mirrors correctly in Arabic |
| POS-002 | Catalog sync | Trigger `Menu → Sync Catalog` online | Products/prices update, success banner, queue empty |
| POS-003 | Barcode sale | Scan barcode with scanner offline | Item appears instantly; offline badge visible; order queued |
| POS-004 | Manual discount | Add % discount at cart level | Totals recalc, discount recorded in summary |
| POS-005 | Split tender | Pay one order with cash + card | Balances zero out; two payment records stored |
| POS-006 | Receipt print fallback | Disable printer mid-print | Job moves to print queue; banner shows queued count + toast |
| POS-007 | Offline order sync | Create 5 orders offline, reconnect | SyncService flushes queue; orders marked `Synced` |
| POS-008 | Conflict resolution | Force duplicate order ID via backend stub | POS surfaces conflict dialog; cashier can retry/new ID |
| POS-009 | Return flow | Process partial return for previous order | Stock adjusts, refund recorded, return receipt printed |
| POS-010 | Cash drawer close | Execute end-of-day close | Variance captured, Z-report generated, print/email succeeds |
| POS-011 | Receipt layout toggle | Switch between compact/full then print | Printer output matches selection; barcode/QR render |

## 3. Non-Functional Checks
- **Performance**: Measure screen load (<1.5s) and print dispatch (<2s) under stable network using Flutter `Timeline` traces.
- **Reliability**: Run 1-hour endurance test scanning items continuously while toggling network every 2 minutes; ensure queue never corrupts.
- **Localization regression**: Use pseudo-locale (double-length strings) to detect truncation (future automation).
- **Accessibility**: Validate large font mode on tablets and ensure contrast meets WCAG AA.

## 4. Test Data & Tools
- Automation hooks via pending widget tests (`test/pos_offline_banner_test.dart`, TODO) and service unit tests (offline queue/print).
- Manual testers should log defects in Jira with reproduction steps + queue dump (export via `Submit Log`).
- Use `scripts/generate_offline_orders.dart` (TODO) to prefill SQLite with sample orders for stress tests.

## 5. Exit Criteria
- All critical and high severity defects resolved.
- Offline queue flush success rate ≥ 99% across simulated outages.
- Localization smoke test passes for both locales with zero missing keys.
- Regression tests re-run after any sync/print service change.
