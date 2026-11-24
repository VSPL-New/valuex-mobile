import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../l10n/app_localizations.dart';
import 'cart_error_messages.dart';
import 'providers/cart_providers.dart';

/// Add to Cart from the accepted offer (US-019): the line rests on the price the buyer already
/// agreed, which the server reads itself. Success says so with a View cart action; a refusal shows
/// its message (the price ended, the cart is full or not available yet). Used by the accepted-offer
/// card in the chat and by the negotiation screen.
Future<void> addAcceptedToCart(BuildContext context, WidgetRef ref, String listingId) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  final result = await ref.read(cartAdderProvider.notifier).add(listingId);
  if (!context.mounted) return;
  final error = result.error;
  if (error == null && result.added == null) return;
  messenger.hideCurrentSnackBar();
  if (error != null) {
    messenger.showSnackBar(SnackBar(content: Text(cartErrorMessage(l10n, error))));
    return;
  }
  messenger.showSnackBar(
    SnackBar(
      content: Text(l10n.cartAdded),
      action: SnackBarAction(
        label: l10n.cartViewCart,
        onPressed: () => unawaited(router.push(RouteNames.cart)),
      ),
    ),
  );
}
