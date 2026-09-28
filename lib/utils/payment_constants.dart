class PaymentConstants {
  PaymentConstants._();

  static const String apiPrefix = '/api/payment';

  static const String createOrder = '$apiPrefix/order';

  static const String createPayment = '$apiPrefix/create';

  static const String paymentStatus = '$apiPrefix/status';
}
