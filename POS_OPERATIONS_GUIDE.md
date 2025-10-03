# Nokta POS – In-Store Operations Guide

## 1. Audience & Scope
This guide targets cashiers, store managers, and support agents operating the Flutter-based POS client in online or offline modes.

## 2. Daily Opening Checklist
1. **Connect peripherals**: Ensure barcode scanner, cash drawer, and receipt printer are powered and paired (Bluetooth/WiFi).
2. **Launch POS app**: Verify splash screen shows green "Online" badge; if offline, allow sync to finish before starting sales.
3. **Fetch updates**: Tap `Menu → Sync Catalog` to pull overnight product/price changes. Confirm success banner.
4. **Count float**: Use `Menu → Cash Drawer → Open Shift` to register starting cash; record in closing sheet.

## 3. Selling Workflow
1. **Scan or search products**:
   - Use barcode scanner (or shortcut `F1`) to add items instantly.
   - For manual search, tap the search bar and enter SKU/name; localized results appear in current language.
2. **Adjust quantities & modifiers**:
   - Tap item row to open the detail dialog; change quantity, add notes, or apply per-item discount.
3. **Apply cart-level discounts**:
   - Tap `Discounts` button → choose coupon (auto-validates offline via cached rules) or manual percentage/amount.
4. **Accept payment**:
   - Select tender type (cash, card, deferred). Offline payments queue until connection restores.
   - For split tenders, add each payment leg; POS enforces total balance = 0 before closing order.
5. **Print receipt**:
   - Choose `Compact receipt` or `Full receipt` from the toggle above the `Pay` button before closing the sale.
   - When the printer is reachable the receipt dispatches immediately; otherwise the job is stored in the offline print queue and marked in the status banner.
6. **Issue invoice/Tax copy**:
   - Use `Share` to email/SMS digital invoice when online; offline attempts are retried by SyncService.

## 4. Handling Returns & Exchanges
1. Navigate to `Orders → History` and locate the target order (filters support barcode scan of receipt number).
2. Tap `Return Items`, select quantity to return, and choose refund method (cash, store credit).
3. POS automatically adjusts stock offline and flags refund transaction for sync reconciliation.
4. Print return receipt; confirm customer signature if required by policy.

## 5. Managing Offline Mode
- **Detection**: An amber offline banner appears when connectivity drops, showing how many orders are waiting to sync. All new orders/payments/prints are queued locally and timestamped.
- **Queue monitor**: The banner updates in real time; tap it to open the pending jobs list, retry, or cancel (if policy allows).
- **Conflict resolution**: If sync reports conflicts (e.g., duplicate order), cashier receives actionable dialog with retry/void options.
- **Data retention**: Offline data stored in encrypted SQLite; device retains last 30 days of transactions by default and automatically purges synced jobs older than 7 days.

## 6. Cash Drawer & Shift Close
1. At end of shift, navigate to `Menu → Cash Drawer → Close Shift`.
2. Enter counted cash total; system compares expected vs actual, logging discrepancies for manager review.
3. Generate Z-report (summary) and print/store digitally for auditing.

## 7. Inventory Movements
- `Menu → Inventory Transfers`: Initiate branch transfers, capture quantities, and sync to backend once online.
- `Cycle Counts`: Use barcode scanning to record actual counts; discrepancies flagged for approval.

## 8. Support & Escalation
- For hardware failures, switch to backup printer (configure under `Settings → Devices`).
- Use `Menu → Submit Log` to send recent offline queue + error logs to support team when network returns.
- Critical incidents (data corruption, loss of orders) must be escalated to central support via hotline within 15 minutes.
