class PaymentModel {
  final String paymentId;
  final String orderId;
  final double amount;
  final String currency;
  final String status;
  final String method;

  final String? upiUri;
  final String? providerTransactionId;
  final DateTime? paidAt;

  PaymentModel({
    required this.paymentId,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.method,
    this.upiUri,
    this.providerTransactionId,
    this.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      paymentId: json['paymentId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
      status: json['status']?.toString() ?? 'created',
      method: json['method']?.toString() ?? 'UPI_INTENT',
      upiUri: json['upiUri']?.toString(),
      providerTransactionId: json['providerTransactionId']?.toString(),
      paidAt: json['paidAt'] != null
          ? DateTime.tryParse(json['paidAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'orderId': orderId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'method': method,
      'upiUri': upiUri,
      'providerTransactionId': providerTransactionId,
      'paidAt': paidAt?.toIso8601String(),
    };
  }
}
