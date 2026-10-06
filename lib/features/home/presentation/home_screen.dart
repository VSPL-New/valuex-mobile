import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Temporary landing placeholder until the Home feature is implemented.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(AppLocalizations.of(context).homeComingSoon)),
    );
  }
}
