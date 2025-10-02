// packages/core/lib/services/subscription_service.dart
class SubscriptionService {
  final ApiClient _apiClient;
  final PaymentService _paymentService;
  
  SubscriptionService(this._apiClient, this._paymentService);
  
  Future<Subscription> createSubscription({
    required String tenantId,
    required SubscriptionPlan plan,
    required PaymentMethod paymentMethod,
  }) async {
    // Calculate pricing
    final pricing = _calculatePricing(plan);
    
    // Process initial payment
    final paymentResult = await _paymentService.processPayment(
      amount: pricing.amount,
      currency: pricing.currency,
      method: paymentMethod,
      metadata: {
        'tenant_id': tenantId,
        'plan_id': plan.id,
        'type': 'subscription',
      },
    );
    
    if (!paymentResult.success) {
      throw PaymentException(paymentResult.error!);
    }
    
    // Create subscription in backend
    final response = await _apiClient.post('/subscriptions', {
      'tenant_id': tenantId,
      'plan_id': plan.id,
      'payment_method_id': paymentMethod.id,
      'payment_reference': paymentResult.transactionId,
      'start_date': DateTime.now().toIso8601String(),
      'billing_cycle': plan.billingCycle,
    });
    
    return Subscription.fromJson(response.data);
  }
  
  Future<void> upgradeSubscription({
    required String subscriptionId,
    required SubscriptionPlan newPlan,
  }) async {
    // Calculate prorated amount
    final subscription = await getSubscription(subscriptionId);
    final proratedAmount = _calculateProration(
      currentPlan: subscription.plan,
      newPlan: newPlan,
      daysRemaining: subscription.daysRemaining,
    );
    
    // Process upgrade payment if needed
    if (proratedAmount > 0) {
      final paymentResult = await _paymentService.processPayment(
        amount: proratedAmount,
        currency: 'SAR',
        method: subscription.paymentMethod,
        metadata: {
          'subscription_id': subscriptionId,
          'type': 'upgrade',
        },
      );
      
      if (!paymentResult.success) {
        throw PaymentException(paymentResult.error!);
      }
    }
    
    // Update subscription
    await _apiClient.put('/subscriptions/$subscriptionId/upgrade', {
      'new_plan_id': newPlan.id,
      'payment_reference': paymentResult?.transactionId,
    });
  }
  
  Future<List<Invoice>> getInvoices(String tenantId) async {
    final response = await _apiClient.get('/tenants/$tenantId/invoices');
    return (response.data as List)
        .map((json) => Invoice.fromJson(json))
        .toList();
  }
  
  Future<UsageReport> getUsageReport(String tenantId) async {
    final response = await _apiClient.get('/tenants/$tenantId/usage');
    return UsageReport.fromJson(response.data);
  }
}