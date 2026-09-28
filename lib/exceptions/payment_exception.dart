class PaymentException implements Exception {
  final String message;
  final int? statusCode;

  PaymentException(this.message, {this.statusCode});

  @override
  String toString() {
    return 'PaymentException111: $message';
  }
}
