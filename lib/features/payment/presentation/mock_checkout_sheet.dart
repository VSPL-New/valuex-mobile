import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// What the tester chose in the test checkout.
enum MockCheckoutChoice { pay, fail, cancel }

/// The dummy gateway's checkout: Pay, Fail or Cancel, and nothing is charged. It is shown only when the app
/// is configured for the dummy gateway (`PAYMENT_PROVIDER=mock`, dev configs only).
class MockCheckoutSheet extends StatelessWidget {
  final double amount;
  final String currency;

  const MockCheckoutSheet({super.key, required this.amount, required this.currency});

  static const double _tapTarget = 48;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final symbol = currency == 'INR' ? '₹' : '$currency ';
    const buttonSize = Size(double.infinity, _tapTarget);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(l10n.paymentTestTitle, style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: 8),
            Text(l10n.paymentTestNote, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              l10n.paymentTestAmount('$symbol${amount.toStringAsFixed(2)}'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('mockCheckoutPay'),
              style: FilledButton.styleFrom(minimumSize: buttonSize),
              onPressed: () => Navigator.of(context).pop(MockCheckoutChoice.pay),
              child: Text(l10n.paymentTestPay),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('mockCheckoutFail'),
              style: OutlinedButton.styleFrom(minimumSize: buttonSize),
              onPressed: () => Navigator.of(context).pop(MockCheckoutChoice.fail),
              child: Text(l10n.paymentTestFail),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('mockCheckoutCancel'),
              style: TextButton.styleFrom(minimumSize: buttonSize),
              onPressed: () => Navigator.of(context).pop(MockCheckoutChoice.cancel),
              child: Text(l10n.paymentTestCancel),
            ),
          ],
        ),
      ),
    );
  }
}
