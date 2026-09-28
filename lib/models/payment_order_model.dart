class PaymentOrderModel {
  final String orderId;
  final double amount;
  final String currency;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? description;
  final String status;

  PaymentOrderModel({
    required this.orderId,
    required this.amount,
    required this.currency,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.description,
    required this.status,
  });

  factory PaymentOrderModel.fromJson(Map<String, dynamic> json) {
    return PaymentOrderModel(
      orderId: json['orderId']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
      customerName: json['customerName']?.toString(),
      customerEmail: json['customerEmail']?.toString(),
      customerPhone: json['customerPhone']?.toString(),
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'created',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'amount': amount,
      'currency': currency,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'description': description,
      'status': status,
    };
  }
}
