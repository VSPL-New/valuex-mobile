import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_error.dart';
import '../../../core/routing/route_names.dart';
import '../../../l10n/app_localizations.dart';
import '../../listing/data/listing_repository.dart';
import '../../listing/domain/existing_listing.dart';
import '../../listing/domain/plan_selection.dart';
import '../../listing/presentation/item_details_screen.dart';
import '../../listing/presentation/listing_error_messages.dart';
import '../../listing/presentation/providers/item_details_controller.dart';
import '../domain/notification_deep_links.dart';

/// Statuses in which the seller can still change the details (needs changes) or choose a plan.
const Set<String> _detailsStatuses = {'REVISION_REQUIRED'};
const Set<String> _planStatuses = {'PLAN_SELECTION_PENDING', 'PLAN_PAYMENT_FAILED'};

/// Opens Item Details or plan selection for the listing of a notification (US-115): loads the
/// listing first, because both pages need its data. A listing that is gone, or is no longer in a
/// state where the page applies, shows a message instead.
Future<void> openListingNotificationTarget(
  BuildContext context,
  WidgetRef ref,
  NotificationTarget target,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  final repository = ref.read(listingRepositoryProvider);

  void say(String message) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  try {
    final listing = await repository.getListing(target.listingId!);
    final isPlan = target.route == RouteNames.sellPlan;
    if (!(isPlan ? _planStatuses : _detailsStatuses).contains(listing.status)) {
      say(l10n.notifListingNotActionable);
      return;
    }
    unawaited(router.push<void>(
      target.route,
      extra: isPlan
          ? planArgsFor(listing, l10n)
          : ItemDetailsArgs(listingId: listing.listingId, existing: listing),
    ));
  } on ApiError catch (error) {
    say(error.statusCode == 404 ? l10n.notifListingNotFound : listingErrorMessage(l10n, error));
  }
}

/// What the plan page repeats back to the seller, from the stored listing.
PlanArgs planArgsFor(ExistingListing listing, AppLocalizations l10n) {
  final draft = listing.draft;
  return PlanArgs(
    listingId: listing.listingId,
    summary: ListingSummary(
      title: draft.title,
      categoryPath: listing.category?.path.map((item) => item.name).join(' > ') ?? '',
      price: draft.price,
      description: draft.description,
      conditionLabel: draft.condition == null ? '' : listingConditionLabel(l10n, draft.condition!),
      city: listing.city,
    ),
  );
}
