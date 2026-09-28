import 'package:flutter/services.dart';

import '../exceptions/payment_exception.dart';
import '../models/upi_app_model.dart';

class UpiAppService {
  static const MethodChannel _channel = MethodChannel('payment_sdk/upi');

  Future<List<UpiAppModel>> getInstalledUPIApps() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'getInstalledUPIApps',
      );

      if (result == null) {
        return [];
      }

      return result
          .map((item) => UpiAppModel.fromMap(Map<dynamic, dynamic>.from(item)))
          .where((app) => app.packageName.isNotEmpty)
          .toList();
    } on PlatformException catch (e) {
      throw PaymentException(e.message ?? 'Unable to detect UPI applications');
    } catch (e) {
      throw PaymentException('Unable to detect UPI applications: $e');
    }
  }

  Future<bool> launchUPI({
    required String upiUri,
    required String packageName,
  }) async {
    if (upiUri.trim().isEmpty) {
      throw PaymentException('UPI payment URI is empty');
    }

    if (packageName.trim().isEmpty) {
      throw PaymentException('UPI application package name is empty');
    }

    try {
      final result = await _channel.invokeMethod<bool>('launchUPI', {
        'upiUri': upiUri,
        'packageName': packageName,
      });

      return result ?? false;
    } on PlatformException catch (e) {
      throw PaymentException(e.message ?? 'Unable to open UPI application');
    } catch (e) {
      throw PaymentException('Unable to open UPI application: $e');
    }
  }
}
