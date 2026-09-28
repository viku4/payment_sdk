import 'package:flutter/material.dart';

import '../exceptions/payment_exception.dart';
import '../models/payment_model.dart';
import '../models/upi_app_model.dart';
import '../services/upi_app_service.dart';

class PaymentMethodScreen extends StatefulWidget {
  final PaymentModel payment;
  final List<UpiAppModel> upiApps;
  final UpiAppService upiAppService;

  const PaymentMethodScreen({
    super.key,
    required this.payment,
    required this.upiApps,
    required this.upiAppService,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  bool _isLoading = false;
  String? _selectedPackage;

  Future<void> _selectUPIApp(UpiAppModel app) async {
    if (_isLoading) {
      return;
    }

    final upiUri = widget.payment.upiUri;

    if (upiUri == null || upiUri.trim().isEmpty) {
      _showError('UPI payment URI was not generated');
      return;
    }

    setState(() {
      _isLoading = true;
      _selectedPackage = app.packageName;
    });

    try {
      final launched = await widget.upiAppService.launchUPI(
        upiUri: upiUri,
        packageName: app.packageName,
      );

      if (!mounted) {
        return;
      }

      if (!launched) {
        throw PaymentException('Unable to open ${app.appName}');
      }

      /*
       * Important:
       *
       * launchUPI() only confirms that the UPI application
       * was successfully opened.
       *
       * It does NOT mean that payment was successful.
       *
       * Payment verification must happen through your backend.
       */

      Navigator.of(context).pop(widget.payment);
    } on PaymentException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _selectedPackage = null;
      });

      _showError(e.message);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _selectedPackage = null;
      });

      _showError('Unable to open payment application');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Select Payment Method')),
      body: SafeArea(
        child: Column(
          children: [
            _buildAmountCard(theme),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pay using',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: widget.upiApps.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final app = widget.upiApps[index];

                  return _UPIAppCard(
                    app: app,
                    isLoading:
                        _selectedPackage == app.packageName && _isLoading,
                    disabled: _isLoading,
                    onTap: () => _selectUPIApp(app),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard(ThemeData theme) {
    final amount = widget.payment.amount;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Text('Amount to Pay', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _UPIAppCard extends StatelessWidget {
  final UpiAppModel app;
  final bool isLoading;
  final bool disabled;
  final VoidCallback onTap;

  const _UPIAppCard({
    required this.app,
    required this.isLoading,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              _buildIcon(theme),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.appName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pay securely using ${app.appName}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              if (isLoading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          _getInitial(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  String _getInitial() {
    final name = app.appName.trim();

    if (name.isEmpty) {
      return 'U';
    }

    return name.substring(0, 1).toUpperCase();
  }
}
