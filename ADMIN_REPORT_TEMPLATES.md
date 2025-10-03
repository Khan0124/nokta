# Admin Report Templates

## Overview Snapshot
**Purpose:** High-level summary for executives.

| Column | Description |
| --- | --- |
| generated_at | ISO timestamp returned by `/reports/preview?type=overview` |
| total_sales | Total sales for filter range |
| sales_today | Sales for current day |
| average_order_value | Total sales divided by order count |
| active_orders | Orders currently preparing/ready/on_way |
| cancelled_orders | Orders marked cancelled in range |
| pending_payments | Count of pending/failed payments |

## Sales Detail
**Endpoint:** `/reports/preview?type=sales`

| Column | Description |
| --- | --- |
| bucket | Time bucket (hour/day/week/month) |
| orders | Number of orders in bucket |
| sales | Revenue in bucket |
| discounts | Total discount amount in bucket |

## Orders Exception Log
**Endpoint:** `/reports/preview?type=orders`

| Column | Description |
| --- | --- |
| status | Order status key |
| count | Number of orders with the status |
| percentage | Percentage of total orders |

> Percentage should be calculated client-side using `count / overview.orders.count`.

## Driver Performance
**Endpoint:** `/drivers/performance`

| Column | Description |
| --- | --- |
| driverId | Unique driver identifier |
| delivered | Completed tasks |
| exceptions | Failed or cancelled tasks |
| avgDeliveryMinutes | Average delivery duration in minutes |
| collectedAmount | Collected COD amount |
| completedShifts | Completed settlement assignments |
| cashCollected | Cash totals from settlement |
| nonCashCollected | Non-cash totals |
| pendingRemittance | Outstanding remittance amount |

## Export Guidance
* Use UTF-8 CSV or XLSX for downloads.
* Include tenant + branch names in filename (e.g., `nokta-main-branch-sales-2024-10-02.csv`).
* Append `generatedAt` timestamp from API response to exported file metadata.
* Retain exports in secure object storage with 90-day retention.
