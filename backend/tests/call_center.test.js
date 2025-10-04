const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createModuleMocks } = require('./helpers/module_mocks');

const { mockModule, requireFresh, clearAll } = createModuleMocks(__dirname);

test('merges customer metadata into queue snapshot', async () => {
  const loggerMock = {
    warn: () => {},
    info: () => {},
    error: () => {},
  };

  mockModule('../config/logger', { logger: loggerMock });

  const redisMock = {
    get: async () => [
      {
        phone: '+966555123456',
        status: 'queued',
        startedAt: '2025-10-03T13:45:00.000Z',
        priority: null,
      },
      {
        phone: '+966555987654',
        status: 'active',
        startedAt: '2025-10-03T13:46:00.000Z',
        agentId: 99,
      },
    ],
    set: async () => {},
  };

  mockModule('../config/redis', redisMock);

  const queried = [];
  mockModule('../config/database', {
    query: async (sql, params) => {
      queried.push({ sql, params });
      return [
        {
          id: 12,
          fullName: 'Hassan Al Qahtani',
          phone: '+966555123456',
          preferredBranchId: 1,
          loyaltyPoints: 980,
          lastOrderAt: '2025-10-02T20:00:00Z',
        },
      ];
    },
    insert: async () => ({}),
    transaction: async (handler) => handler({
      query: async () => [],
      execute: async () => [],
    }),
  });

  const router = requireFresh('../server/routes/call_center');
  const { decorateQueueEntries } = router.__private__;
  const entries = await decorateQueueEntries(42);

  assert.equal(entries.length, 2);
  assert.equal(entries[0].displayName, 'Hassan Al Qahtani');
  assert.equal(entries[0].loyaltyPoints, 980);
  assert.equal(entries[0].callerNumber, '+966555123456');
  assert.ok(entries[0].priority >= 50);
  assert.equal(entries[1].callerNumber, '+966555987654');
  assert.equal(entries[1].status, 'active');
  assert.equal(queried.length, 1);

  clearAll();
});
