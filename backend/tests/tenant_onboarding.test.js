const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createModuleMocks } = require('./helpers/module_mocks');

const { mockModule, mockExternalModule, requireFresh, clearAll } = createModuleMocks(__dirname);

test('creates a session token and default steps', async () => {
  mockModule('../config/logger', {
    logger: {
      warn: () => {},
      error: () => {},
      info: () => {},
    },
    auditLogger: {
      info: () => {},
    },
  });

  mockExternalModule('uuid', {
    v4: () => 'mock-uuid',
  });

  mockExternalModule('bcryptjs', {
    genSaltSync: () => 'salt',
    hashSync: () => 'hashed',
  });

  const nowIso = new Date().toISOString();
  mockModule('../config/database', {
    transaction: async (handler) => {
      const connection = {
        execute: async (sql) => {
          if (sql.includes('tenant_onboarding_sessions')) {
            return [{ insertId: 99 }];
          }
          return [{}];
        },
        query: async (sql, params) => {
          if (sql.includes('tenant_onboarding_sessions')) {
            return [[{
              id: 99,
              token: params[0],
              company_name: 'ACME Co',
              contact_email: 'ops@acme.test',
              contact_name: 'Rania',
              contact_phone: '+966555000111',
              preferred_language: 'ar',
              subscription_plan: 'basic',
              status: 'in_progress',
              current_step: 'company_profile',
              expires_at: new Date(Date.now() + 20 * 60 * 1000),
              metadata: JSON.stringify({ source: 'self_service' }),
              created_at: nowIso,
              updated_at: nowIso,
            }]];
          }
          if (sql.includes('tenant_onboarding_steps')) {
            return [[{
              id: 1,
              session_id: 99,
              step_key: 'company_profile',
              status: 'pending',
              display_order: 1,
              payload: null,
              completed_at: null,
              last_error: null,
              created_at: nowIso,
              updated_at: nowIso,
            }]];
          }
          return [[]];
        },
      };
      return handler(connection);
    },
  });

  const service = requireFresh('../server/services/tenant_onboarding_service');
  const session = await service.startOnboarding({
    companyName: 'ACME Co',
    contactName: 'Rania',
    contactEmail: 'ops@acme.test',
    contactPhone: '+966555000111',
  });

  assert.ok(session.token);
  assert.equal(session.status, 'in_progress');
  assert.equal(session.steps.length, 1);
  assert.equal(session.steps[0].key, 'company_profile');

  clearAll();
});
