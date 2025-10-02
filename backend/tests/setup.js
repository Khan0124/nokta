const { MongoMemoryServer } = require('mongodb-memory-server');
const config = require('../config/config');

// Set test environment
process.env.NODE_ENV = 'test';

// Mock external services
jest.mock('../config/logger', () => ({
  logger: {
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
    debug: jest.fn()
  },
  requestLogger: jest.fn(),
  errorLogger: jest.fn(),
  securityLogger: {
    loginAttempt: jest.fn(),
    failedLogin: jest.fn(),
    suspiciousActivity: jest.fn(),
    permissionDenied: jest.fn()
  },
  performanceLogger: {
    slowQuery: jest.fn(),
    apiResponseTime: jest.fn()
  }
}));

// Global test setup
beforeAll(async () => {
  // Setup test database if needed
  // For now, we'll use the main database with test prefix
});

// Global test teardown
afterAll(async () => {
  // Cleanup test data
});

// Test utilities
global.testUtils = {
  // Generate test data
  generateTestUser: (overrides = {}) => ({
    username: 'testuser',
    email: 'test@example.com',
    password: 'TestPass123!',
    fullName: 'Test User',
    role: 'staff',
    tenantId: 1,
    branchId: 1,
    ...overrides
  }),

  generateTestProduct: (overrides = {}) => ({
    name: 'Test Product',
    description: 'Test product description',
    price: 9.99,
    stockQuantity: 100,
    categoryId: 1,
    tenantId: 1,
    branchId: 1,
    ...overrides
  }),

  generateTestOrder: (overrides = {}) => ({
    orderNumber: 'TEST-001',
    customerName: 'Test Customer',
    totalAmount: 19.98,
    paymentMethod: 'cash',
    tenantId: 1,
    branchId: 1,
    ...overrides
  }),

  // Mock request object
  mockRequest: (overrides = {}) => ({
    body: {},
    query: {},
    params: {},
    headers: {},
    ip: '127.0.0.1',
    method: 'GET',
    originalUrl: '/test',
    user: null,
    ...overrides
  }),

  // Mock response object
  mockResponse: () => {
    const res = {};
    res.status = jest.fn().mockReturnValue(res);
    res.json = jest.fn().mockReturnValue(res);
    res.send = jest.fn().mockReturnValue(res);
    res.set = jest.fn().mockReturnValue(res);
    res.get = jest.fn().mockReturnValue(res);
    return res;
  },

  // Mock next function
  mockNext: jest.fn(),

  // Clear all mocks
  clearMocks: () => {
    jest.clearAllMocks();
  }
};
