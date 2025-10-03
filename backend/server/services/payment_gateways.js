const { v4: uuidv4 } = require('uuid');
const Stripe = require('stripe');
const { logger } = require('../../config/logger');

class PaymentGateway {
  constructor(id, { name, supportedMethods = [], enabled = true } = {}) {
    this.id = id;
    this.name = name || id;
    this.supportedMethods = supportedMethods;
    this.enabled = enabled;
  }

  async charge() {
    throw new Error('charge operation not implemented for gateway');
  }

  async refund() {
    throw new Error('refund operation not implemented for gateway');
  }

  describe() {
    return {
      id: this.id,
      name: this.name,
      supportedMethods: this.supportedMethods,
      enabled: this.enabled
    };
  }
}

class StripeGateway extends PaymentGateway {
  constructor() {
    const secretKey = process.env.STRIPE_SECRET_KEY;
    super('stripe', {
      name: 'Stripe',
      supportedMethods: ['card', 'apple_pay', 'google_pay'],
      enabled: Boolean(secretKey)
    });

    this.secretKey = secretKey;
    this.client = secretKey ? new Stripe(secretKey, { apiVersion: '2023-10-16' }) : null;
  }

  async charge({ amount, currency, description, metadata }) {
    if (!this.enabled || !this.client) {
      logger.warn('Stripe gateway not fully configured, returning simulated payment');
      return {
        status: 'pending',
        reference: `stripe-sim-${uuidv4()}`,
        metadata: { ...metadata, simulated: true }
      };
    }

    try {
      const intent = await this.client.paymentIntents.create({
        amount: Math.round(Number(amount) * 100),
        currency: (currency || 'usd').toLowerCase(),
        capture_method: 'automatic',
        description: description || 'Subscription charge',
        metadata
      });

      return {
        status: intent.status,
        reference: intent.id,
        metadata: intent.metadata
      };
    } catch (error) {
      logger.error('Stripe charge failed', { error: error.message });
      return {
        status: 'failed',
        reference: null,
        metadata: { error: error.message }
      };
    }
  }

  async refund({ paymentIntentId, amount }) {
    if (!this.enabled || !this.client) {
      throw new Error('Stripe gateway not configured for refunds');
    }

    const refund = await this.client.refunds.create({
      payment_intent: paymentIntentId,
      amount: amount ? Math.round(Number(amount) * 100) : undefined
    });

    return {
      status: refund.status,
      reference: refund.id
    };
  }
}

class LocalBankGateway extends PaymentGateway {
  constructor() {
    super('local_bank', {
      name: 'Bankak Local Gateway',
      supportedMethods: ['bank_transfer'],
      enabled: Boolean(process.env.LOCAL_BANK_API_KEY)
    });

    this.endpoint = process.env.LOCAL_BANK_ENDPOINT || 'https://api.local-bank.example/payments';
  }

  async charge({ amount, currency, description, metadata }) {
    logger.info('Dispatching payment request to local bank gateway', {
      amount,
      currency,
      description,
      endpoint: this.endpoint,
      metadata
    });

    return {
      status: this.enabled ? 'pending' : 'awaiting_confirmation',
      reference: `bank-${Date.now()}`,
      metadata: { ...metadata, endpoint: this.endpoint, simulated: !this.enabled }
    };
  }
}

class CashGateway extends PaymentGateway {
  constructor() {
    super('cash', {
      name: 'Cash on Delivery',
      supportedMethods: ['cash'],
      enabled: true
    });
  }

  async charge({ amount, currency, metadata }) {
    logger.info('Recording manual cash collection for subscription', { amount, currency });

    return {
      status: 'succeeded',
      reference: `cash-${Date.now()}`,
      metadata: { ...metadata, collectedOffline: true }
    };
  }
}

const gatewayRegistry = {
  stripe: new StripeGateway(),
  local_bank: new LocalBankGateway(),
  cash: new CashGateway()
};

const getGateway = (provider) => {
  return gatewayRegistry[provider] || gatewayRegistry.cash;
};

const listGateways = () => Object.values(gatewayRegistry).map((gateway) => gateway.describe());

module.exports = {
  getGateway,
  listGateways
};
