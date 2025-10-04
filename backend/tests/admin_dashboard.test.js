const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createModuleMocks } = require('./helpers/module_mocks');

const { mockModule, requireFresh, clearAll } = createModuleMocks(__dirname);

const noopLogger = {
  info: () => {},
  warn: () => {},
  error: () => {},
  debug: () => {}
};

const buildQueryMock = () => {
  return async (sql) => {
    if (sql.includes('FROM orders o')) {
      return [
        {
          total_orders: 20,
          discounted_orders: 5,
          total_discounts: 50,
          influenced_revenue: 450
        }
      ];
    }

    if (sql.includes('FROM dynamic_price_adjustments')) {
      return [
        { status: 'active', channels: JSON.stringify(['pos', 'customer']) },
        { status: 'scheduled', channels: JSON.stringify(['customer']) },
        { status: 'active', channels: JSON.stringify(['pos']) }
      ];
    }

    if (sql.includes('FROM vw_dynamic_pricing_adoption')) {
      return [
        {
          order_date: '2024-02-01',
          order_count: 10,
          discounted_orders: 3,
          total_discounts: 30,
          influenced_revenue: 200
        },
        {
          order_date: '2024-02-02',
          order_count: 10,
          discounted_orders: 2,
          total_discounts: 20,
          influenced_revenue: 150
        }
      ];
    }

    return [];
  };
};

test('loadDynamicPricingAdoption summarises adoption metrics', async () => {
  mockModule('../config/logger', { logger: noopLogger });
  mockModule('../config/database', {
    query: buildQueryMock()
  });

  const service = requireFresh('../server/services/admin_dashboard_service');
  const adoption = await service.loadDynamicPricingAdoption({ tenantId: 7 });

  assert.equal(adoption.summary.totalOrders, 20);
  assert.equal(adoption.summary.discountedOrders, 5);
  assert.equal(adoption.summary.adoptionRate, 25);
  assert.equal(adoption.summary.averageDiscount, 10);
  assert.equal(adoption.summary.influencedRevenue, 450);
  assert.equal(adoption.adjustments.total, 3);
  assert.equal(adoption.adjustments.byStatus.active, 2);
  assert.equal(adoption.adjustments.byStatus.scheduled, 1);
  assert.equal(adoption.adjustments.channelCoverage.pos, 2);
  assert.equal(adoption.adjustments.channelCoverage.customer, 2);
  assert.equal(adoption.trends.length, 2);
  assert.equal(adoption.trends[0].discountedOrders, 3);
  assert.ok(adoption.range.start);
  assert.ok(adoption.range.end);

  clearAll();
});
