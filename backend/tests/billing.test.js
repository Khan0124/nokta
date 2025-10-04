const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createModuleMocks } = require('./helpers/module_mocks');

const { mockModule, mockExternalModule, requireFresh, clearAll } = createModuleMocks(__dirname);

test('returns database backed plans when present', async () => {
  mockModule('../config/logger', {
    logger: {
      error: () => {},
      warn: () => {},
      info: () => {},
    },
  });

  mockExternalModule('pdfkit', function MockPdfDocument() {
    return {
      pipe: () => {},
      fontSize: () => ({ text: () => {} }),
      text: () => {},
      moveDown: () => {},
      end: () => {},
    };
  });

  mockExternalModule('uuid', {
    v4: () => 'mock-uuid',
  });

  const callLog = [];
  mockModule('../config/database', {
    query: async (...args) => {
      callLog.push(args);
      return [
        {
          id: 'enterprise',
          name: 'Enterprise',
          tier: 'enterprise',
          currency: 'USD',
          monthly_price: 149,
          yearly_price: 1490,
          monthly_grace_days: 10,
          yearly_grace_days: 20,
          trial_days: 21,
          features: JSON.stringify(['Unlimited seats']),
          limits: JSON.stringify({ callCenterSeats: 25 }),
        },
      ];
    },
  });

  const service = requireFresh('../server/services/billing_service');
  const plans = await service.listPlans();

  assert.equal(callLog.length, 1);
  assert.equal(plans.length, 1);
  assert.equal(plans[0].id, 'enterprise');
  assert.equal(plans[0].billingCycles.monthly.amount, 149);
  assert.ok(plans[0].features.includes('Unlimited seats'));

  clearAll();
});
