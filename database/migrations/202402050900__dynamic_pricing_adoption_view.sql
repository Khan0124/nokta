-- up
CREATE OR REPLACE VIEW `vw_dynamic_pricing_adoption` AS
SELECT
  o.tenant_id,
  DATE(o.created_at) AS order_date,
  COUNT(*) AS order_count,
  SUM(CASE WHEN o.discount_amount > 0 THEN 1 ELSE 0 END) AS discounted_orders,
  COALESCE(SUM(o.discount_amount), 0) AS total_discounts,
  COALESCE(SUM(CASE WHEN o.discount_amount > 0 THEN o.total_amount ELSE 0 END), 0) AS influenced_revenue
FROM orders o
GROUP BY o.tenant_id, DATE(o.created_at);

-- down
DROP VIEW IF EXISTS `vw_dynamic_pricing_adoption`;
