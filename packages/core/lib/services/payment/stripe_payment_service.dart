// packages/core/lib/services/payment/stripe_payment_service.dart
import 'package:stripe_sdk/stripe_sdk.dart';

class StripePaymentService implements PaymentGateway {
  late final Stripe _stripe;
  
  StripePaymentService() {
    _stripe = Stripe(
      publishableKey: ENV.stripePublishableKey,
    );
  }
  
  @override
  Future<PaymentResult> processPayment({
    required double amount,
    required String currency,
    required PaymentMethod method,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Create payment intent on backend
      final paymentIntent = await _createPaymentIntent(
        amount: amount,
        currency: currency,
        metadata: metadata,
      );
      
      // Process payment based on method
      switch (method.type) {
        case PaymentMethodType.card:
          return await _processCardPayment(paymentIntent, method);
        case PaymentMethodType.applePay:
          return await _processApplePayPayment(paymentIntent);
        case PaymentMethodType.googlePay:
          return await _processGooglePayPayment(paymentIntent);
        default:
          throw UnsupportedError('Payment method not supported');
      }
    } catch (e) {
      return PaymentResult.failure(
        error: PaymentError(
          code: 'payment_failed',
          message: e.toString(),
        ),
      );
    }
  }
  
  Future<Map<String, dynamic>> _createPaymentIntent({
    required double amount,
    required String currency,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await ApiService.post('/payments/create-intent', {
      'amount': (amount * 100).toInt(), // Convert to cents
      'currency': currency.toLowerCase(),
      'metadata': metadata,
    });
    
    return response.data;
  }
  
  Future<PaymentResult> _processCardPayment(
    Map<String, dynamic> paymentIntent,
    PaymentMethod method,
  ) async {
    // Show card input form
    final cardDetails = await showModalBottomSheet<CardDetails>(
      context: NavigatorService.navigatorKey.currentContext!,
      builder: (context) => const CardInputSheet(),
    );
    
    if (cardDetails == null) {
      return PaymentResult.failure(
        error: PaymentError(code: 'cancelled', message: 'Payment cancelled'),
      );
    }
    
    // Confirm payment
    final result = await _stripe.confirmPayment(
      paymentIntent['client_secret'],
      data: PaymentMethodData(
        type: PaymentMethodType.card,
        card: cardDetails,
      ),
    );
    
    if (result['status'] == 'succeeded') {
      return PaymentResult.success(
        transactionId: result['id'],
        paymentMethodId: result['payment_method'],
      );
    } else {
      return PaymentResult.failure(
        error: PaymentError(
          code: result['error']['code'],
          message: result['error']['message'],
        ),
      );
    }
  }
}