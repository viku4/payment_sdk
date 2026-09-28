class PaymentResultModel {
  final bool launched;
  final String paymentId;
  final String orderId;
  final String status;
  final String? message;
  final String? upiResponse;

  PaymentResultModel({
    required this.launched,
    required this.paymentId,
    required this.orderId,
    required this.status,
    this.message,
    this.upiResponse,
  });

  factory PaymentResultModel.fromJson(Map<String, dynamic> json) {
    return PaymentResultModel(
      launched: json['launched'] == true,
      paymentId: json['paymentId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      message: json['message']?.toString(),
      upiResponse: json['upiResponse']?.toString(),
    );
  }
}
