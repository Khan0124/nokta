const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createModuleMocks } = require('./helpers/module_mocks');

const { mockModule, requireFresh, clearAll } = createModuleMocks(__dirname);

test('evaluates tenant overrides using cached base flags', async () => {
  mockModule('../config/logger', {
    logger: {
      error: () => {},
      warn: () => {},
      info: () => {},
    },
  });

  mockModule('../config/config', {
    featureFlags: {
      namespace: 'feature-flags',
      cacheTtlSeconds: 5,
    },
  });

  mockModule('../config/featureFlags', {
    getBaseFlags: () => ({
      call_center_console: {
        key: 'call_center_console',
        description: 'Enable call center console',
        enabled: false,
        defaultEnabled: false,
        rollout: { strategy: 'all', percentage: 100 },
        tags: ['call-center'],
        owner: 'operations',
        since: '2025-01-01',
        environments: [],
        notes: null,
        sources: { default: { enabled: false } },
      },
    }),
    getEnvironmentOverrides: () => ({}),
  });

  mockModule('../config/redis', {
    get: async (key) => {
      if (key.includes('tenant-42')) {
        return {
          call_center_console: {
            enabled: true,
            updatedAt: '2025-01-03T10:00:00Z',
          },
        };
      }
      return {};
    },
    set: async () => {},
    del: async () => {},
  });

  const service = requireFresh('../server/services/feature_flag_service');
  const flags = await service.listFlags({ tenantId: 'tenant-42' });

  assert.equal(flags.length, 1);
  assert.equal(flags[0].key, 'call_center_console');
  assert.equal(flags[0].evaluation, true);
  assert.equal(flags[0].activeSource, 'tenant');

  clearAll();
});
