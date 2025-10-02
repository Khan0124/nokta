// packages/core/lib/services/payment/local_payment_service.dart
class LocalPaymentService {
  // STC Pay Integration
  Future<PaymentResult> processSTCPay({
    required double amount,
    required String phoneNumber,
  }) async {
    try {
      // Initialize STC Pay SDK
      final stcPay = STCPaySDK(
        merchantId: ENV.stcPayMerchantId,
        secretKey: ENV.stcPaySecretKey,
      );
      
      // Create payment request
      final paymentRequest = await stcPay.createPaymentRequest(
        amount: amount,
        phoneNumber: phoneNumber,
        description: 'Nokta Order Payment',
      );
      
      // Send OTP to user
      await stcPay.sendOTP(paymentRequest.id);
      
      // Show OTP input dialog
      final otp = await showDialog<String>(
        context: NavigatorService.navigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (context) => OTPInputDialog(
          phoneNumber: phoneNumber,
        ),
      );
      
      if (otp == null) {
        return PaymentResult.failure(
          error: PaymentError(code: 'cancelled', message: 'Payment cancelled'),
        );
      }
      
      // Confirm payment with OTP
      final result = await stcPay.confirmPayment(
        paymentRequestId: paymentRequest.id,
        otp: otp,
      );
      
      return PaymentResult.success(
        transactionId: result.transactionId,
        paymentMethodId: 'stc_pay',
      );
    } catch (e) {
      return PaymentResult.failure(
        error: PaymentError(
          code: 'stc_pay_error',
          message: e.toString(),
        ),
      );
    }
  }
  
  // Mada Card Integration
  Future<PaymentResult> processMadaCard({
    required double amount,
    required CardDetails cardDetails,
  }) async {
    // Mada uses special BINs and requires 3D Secure
    final paymentGateway = PayfortSDK(
      merchantIdentifier: ENV.payfortMerchantId,
      accessCode: ENV.payfortAccessCode,
      shaRequestPhrase: ENV.payfortShaRequest,
    );
    
    final request = PayfortRequest(
      amount: (amount * 100).toInt(),
      currency: 'SAR',
      customerEmail: 'customer@example.com',
      cardNumber: cardDetails.number,
      expiryDate: cardDetails.expiry,
      cvv: cardDetails.cvv,
      cardHolderName: cardDetails.name,
    );
    
    final response = await paymentGateway.purchase(request);
    
    if (response.status == '14') { // Success
      return PaymentResult.success(
        transactionId: response.fortId,
        paymentMethodId: 'mada',
      );
    } else {
      return PaymentResult.failure(
        error: PaymentError(
          code: response.responseCode,
          message: response.responseMessage,
        ),
      );
    }
  }
}