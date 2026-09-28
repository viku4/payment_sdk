library payment_sdk;

import 'package:flutter/material.dart';

import 'controllers/payment_controller.dart';
import 'exceptions/payment_exception.dart';
import 'models/payment_model.dart';
import 'models/payment_order_model.dart';
import 'models/upi_app_model.dart';
import 'pages/payment_method_screen.dart';
import 'services/payment_api_service.dart';
import 'services/upi_app_service.dart';

export 'controllers/payment_controller.dart';
export 'exceptions/payment_exception.dart';
export 'models/payment_model.dart';
export 'models/payment_order_model.dart';
export 'models/upi_app_model.dart';
export 'pages/payment_method_screen.dart';
export 'services/payment_api_service.dart';
export 'services/upi_app_service.dart';

class PaymentSDK {
  PaymentSDK._();

  static PaymentApiService? _apiService;
  static UpiAppService? _upiAppService;
  static PaymentController? _controller;

  static bool _initialized = false;

  /// SDK navigator key.
  ///
  /// Add this to the host application's MaterialApp:
  ///
  /// navigatorKey: PaymentSDK.navigatorKey
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void initialize({required String baseUrl}) {
    if (baseUrl.trim().isEmpty) {
      throw PaymentException('Payment SDK baseUrl cannot be empty');
    }

    final normalizedBaseUrl = baseUrl.trim().replaceFirst(RegExp(r'/$'), '');

    _apiService = PaymentApiService(baseUrl: normalizedBaseUrl);

    _upiAppService = UpiAppService();

    _controller = PaymentController(
      apiService: _apiService!,
      upiAppService: _upiAppService!,
    );

    _initialized = true;
  }

  static PaymentController get _paymentController {
    if (!_initialized || _controller == null) {
      throw PaymentException(
        'PaymentSDK is not initialized. '
        'Call PaymentSDK.initialize(baseUrl: "...") first.',
      );
    }

    return _controller!;
  }

  // ---------------------------------------------------------------------------
  // CREATE ORDER
  // ---------------------------------------------------------------------------

  static Future<PaymentOrderModel> createOrder({
    required double amount,
    String currency = 'INR',
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? description,
  }) {
    return _paymentController.createOrder(
      amount: amount,
      currency: currency,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      description: description,
    );
  }

  // ---------------------------------------------------------------------------
  // CREATE PAYMENT
  // ---------------------------------------------------------------------------

  static Future<PaymentModel> createPayment({required String orderId}) {
    return _paymentController.createPayment(orderId: orderId);
  }

  // ---------------------------------------------------------------------------
  // GET INSTALLED UPI APPS
  // ---------------------------------------------------------------------------

  static Future<List<UpiAppModel>> getInstalledUPIApps() {
    return _paymentController.getInstalledUPIApps();
  }

  // ---------------------------------------------------------------------------
  // PAY WITH SELECTED UPI APP
  // ---------------------------------------------------------------------------

  static Future<PaymentModel> payWithUPIApp({
    required String orderId,
    required String packageName,
  }) {
    return _paymentController.payWithUPIApp(
      orderId: orderId,
      packageName: packageName,
    );
  }

  // ---------------------------------------------------------------------------
  // FINAL PAY METHOD
  // ---------------------------------------------------------------------------

  static Future<PaymentModel> pay({
    required BuildContext context,
    required String orderId,
  }) async {
    if (orderId.trim().isEmpty) {
      throw PaymentException('Order ID is required');
    }

    // 1. Create payment on backend.
    final payment = await _paymentController.createPayment(orderId: orderId);

    // 2. Validate UPI URI.
    final upiUri = payment.upiUri;

    if (upiUri == null || upiUri.trim().isEmpty) {
      throw PaymentException('UPI payment URI was not generated');
    }

    // 3. Detect installed UPI apps.
    final apps = await _paymentController.getInstalledUPIApps();

    if (apps.isEmpty) {
      throw PaymentException('No UPI application found on this device');
    }

    final result = await Navigator.of(context).push<PaymentModel>(
      MaterialPageRoute(
        builder: (_) => PaymentMethodScreen(
          payment: payment,
          upiApps: apps,
          upiAppService: _upiAppService!,
        ),
      ),
    );

    // 6. Payment method screen returns the payment.
    if (result == null) {
      throw PaymentException('Payment was cancelled');
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // DIRECT UPI LAUNCH
  // ---------------------------------------------------------------------------

  static Future<bool> launchUPI({
    required String upiUri,
    required String packageName,
  }) {
    return _upiAppService!.launchUPI(upiUri: upiUri, packageName: packageName);
  }

  // ---------------------------------------------------------------------------
  // PAYMENT STATUS
  // ---------------------------------------------------------------------------

  static Future<PaymentModel> getPaymentStatus({required String paymentId}) {
    return _paymentController.getPaymentStatus(paymentId: paymentId);
  }
}
