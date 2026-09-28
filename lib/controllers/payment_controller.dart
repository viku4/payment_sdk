import '../exceptions/payment_exception.dart';
import '../models/payment_model.dart';
import '../models/payment_order_model.dart';
import '../models/upi_app_model.dart';
import '../services/payment_api_service.dart';
import '../services/upi_app_service.dart';

class PaymentController {
  final PaymentApiService apiService;
  final UpiAppService upiAppService;

  PaymentController({required this.apiService, UpiAppService? upiAppService})
    : upiAppService = upiAppService ?? UpiAppService();

  // ============================================================
  // CREATE ORDER
  // ============================================================

  Future<PaymentOrderModel> createOrder({
    required double amount,
    String currency = 'INR',
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? description,
  }) {
    if (amount <= 0) {
      throw PaymentException('Amount must be greater than 0');
    }

    return apiService.createOrder(
      amount: amount,
      currency: currency,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      description: description,
    );
  }

  // ============================================================
  // CREATE PAYMENT
  // ============================================================

  Future<PaymentModel> createPayment({required String orderId}) async {
    if (orderId.trim().isEmpty) {
      throw PaymentException('Order ID is required');
    }

    return apiService.createPayment(orderId: orderId);
  }

  // ============================================================
  // GET INSTALLED UPI APPS
  // ============================================================

  Future<List<UpiAppModel>> getInstalledUPIApps() async {
    return upiAppService.getInstalledUPIApps();
  }

  // ============================================================
  // PAY WITH SELECTED UPI APP
  // ============================================================

  Future<PaymentModel> payWithUPIApp({
    required String orderId,
    required String packageName,
  }) async {
    if (orderId.trim().isEmpty) {
      throw PaymentException('Order ID is required');
    }

    if (packageName.trim().isEmpty) {
      throw PaymentException('UPI application package name is required');
    }

    // 1. Create payment on backend.
    final payment = await createPayment(orderId: orderId);

    // 2. Backend must return UPI URI.
    final upiUri = payment.upiUri;

    if (upiUri == null || upiUri.trim().isEmpty) {
      throw PaymentException('UPI payment URI was not generated');
    }

    // 3. Open selected UPI application.
    final launched = await upiAppService.launchUPI(
      upiUri: upiUri,
      packageName: packageName,
    );

    if (!launched) {
      throw PaymentException('Unable to open selected UPI application');
    }

    return payment;
  }

  // ============================================================
  // OLD GENERIC UPI PAYMENT
  // ============================================================

  Future<bool> launchUPI({required String upiUri}) async {
    if (upiUri.trim().isEmpty) {
      throw PaymentException('UPI payment URI is empty');
    }

    final apps = await getInstalledUPIApps();

    if (apps.isEmpty) {
      throw PaymentException('No UPI application found on this device');
    }

    final firstApp = apps.first;

    return upiAppService.launchUPI(
      upiUri: upiUri,
      packageName: firstApp.packageName,
    );
  }

  // ============================================================
  // PAYMENT STATUS
  // ============================================================

  Future<PaymentModel> getPaymentStatus({required String paymentId}) {
    if (paymentId.trim().isEmpty) {
      throw PaymentException('Payment ID is required');
    }

    return apiService.getPaymentStatus(paymentId: paymentId);
  }

  // ============================================================
  // OLD PAY METHOD
  // ============================================================

  Future<PaymentModel> pay({required String orderId}) async {
    final payment = await createPayment(orderId: orderId);

    if (payment.upiUri == null || payment.upiUri!.trim().isEmpty) {
      throw PaymentException('UPI payment URI was not generated');
    }

    final apps = await getInstalledUPIApps();

    if (apps.isEmpty) {
      throw PaymentException('No UPI application found on this device');
    }

    await upiAppService.launchUPI(
      upiUri: payment.upiUri!,
      packageName: apps.first.packageName,
    );

    return payment;
  }
}
