import 'package:dio/dio.dart';

import '../exceptions/payment_exception.dart';
import '../models/payment_model.dart';
import '../models/payment_order_model.dart';
import '../utils/payment_constants.dart';

class PaymentApiService {
  final Dio dio;

  PaymentApiService({required String baseUrl, Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          );

  Future<PaymentOrderModel> createOrder({
    required double amount,
    String currency = 'INR',
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? description,
  }) async {
    try {
      final response = await dio.post(
        PaymentConstants.createOrder,
        data: {
          'amount': amount,
          'currency': currency,
          'customerName': customerName,
          'customerEmail': customerEmail,
          'customerPhone': customerPhone,
          'description': description,
        },
      );

      final data = response.data;

      if (data is! Map) {
        throw PaymentException('Invalid server response');
      }

      if (data['data'] == null) {
        throw PaymentException(
          data['message']?.toString() ?? 'Unable to create order',
        );
      }

      return PaymentOrderModel.fromJson(
        Map<String, dynamic>.from(data['data']),
      );
    } on DioException catch (e) {
      throw PaymentException(
        _getDioErrorMessage(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<PaymentModel> createPayment({required String orderId}) async {
    try {
      final response = await dio.post(
        PaymentConstants.createPayment,
        data: {'orderId': orderId},
      );

      final data = response.data;

      if (data is! Map) {
        throw PaymentException('Invalid server response');
      }

      if (data['data'] == null) {
        throw PaymentException(
          data['message']?.toString() ?? 'Unable to create payment',
        );
      }

      return PaymentModel.fromJson(Map<String, dynamic>.from(data['data']));
    } on DioException catch (e) {
      throw PaymentException(
        _getDioErrorMessage(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<PaymentModel> getPaymentStatus({required String paymentId}) async {
    try {
      final response = await dio.get(
        '${PaymentConstants.paymentStatus}/$paymentId',
      );

      final data = response.data;

      if (data is! Map) {
        throw PaymentException('Invalid server response');
      }

      if (data['data'] == null) {
        throw PaymentException(
          data['message']?.toString() ?? 'Unable to get payment status',
        );
      }

      return PaymentModel.fromJson(Map<String, dynamic>.from(data['data']));
    } on DioException catch (e) {
      throw PaymentException(
        _getDioErrorMessage(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  String _getDioErrorMessage(DioException e) {
    final response = e.response?.data;

    if (response is Map && response['message'] != null) {
      return response['message'].toString();
    }

    if (e.message != null) {
      return e.message!;
    }

    return 'Network error occurred';
  }
}
