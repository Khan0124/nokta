const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createModuleMocks } = require('./helpers/module_mocks');

const { mockModule, mockExternalModule, requireFresh, clearAll } = createModuleMocks(__dirname);

test('merges base adjustments with tenant overrides and filters by branch', async () => {
  mockModule('../config/logger', {
    logger: {
      warn: () => {},
      error: () => {},
      info: () => {},
    },
  });

  mockModule('../config/config', {
    dynamicPricing: {
      namespace: 'dynamic-pricing',
      cacheTtlSeconds: 15,
    },
  });

  mockModule('../config/dynamicPricing', {
    getBaseAdjustments: () => [
      {
        id: 'lunch-special',
        name: 'Lunch Special',
        description: '15% off mains during lunch',
        type: 'percentage',
        value: 15,
        fixedPrice: null,
        productIds: [1, 2],
        categoryIds: [],
        branchIds: [],
        channels: ['pos', 'customer'],
        tenantId: null,
        priority: 100,
        stackable: false,
        startAt: null,
        endAt: null,
        status: 'active',
        createdAt: '2025-01-01T08:00:00Z',
        createdBy: 'system',
        updatedAt: '2025-01-01T08:00:00Z',
        updatedBy: 'system',
      },
    ],
  });

  mockModule('../config/redis', {
    get: async (key) => {
      if (key.includes('tenant-7')) {
        return {
          adjustments: [
            {
              id: 'branch-exclusive',
              name: 'Branch Exclusive',
              description: 'Fixed price for branch 7',
              type: 'fixed',
              fixedPrice: 25,
              value: null,
              productIds: [3],
              categoryIds: [],
              branchIds: [7],
              channels: ['pos'],
              tenantId: 'tenant-7',
              priority: 50,
              stackable: false,
              startAt: '2025-01-01T09:00:00Z',
              endAt: '2025-12-31T21:00:00Z',
              status: 'active',
              createdAt: '2025-01-01T09:00:00Z',
              createdBy: 'ops',
              updatedAt: '2025-01-01T09:00:00Z',
              updatedBy: 'ops',
            },
          ],
        };
      }
      return {};
    },
    set: async () => {},
  });

  mockExternalModule('uuid', {
    v4: () => 'mock-uuid',
  });

  const service = requireFresh('../server/services/dynamic_pricing_service');
  const adjustments = await service.listAdjustments({ tenantId: 'tenant-7', branchId: 7 });

  assert.deepEqual(
    adjustments.map((adj) => adj.id),
    ['branch-exclusive', 'lunch-special'],
  );

  const fixedAdjustment = adjustments.find((adj) => adj.id === 'branch-exclusive');
  assert.equal(fixedAdjustment.fixedPrice, 25);
  assert.ok(fixedAdjustment.channels.includes('pos'));

  clearAll();
});
