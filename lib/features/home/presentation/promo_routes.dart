import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../search/presentation/search_routes.dart';
import '../domain/entities/promo.dart';
import 'main_nav.dart';

/// Opens what a promo leads to, always inside the app. A sample promo has no target, so it says
/// "coming soon".
void openPromo(BuildContext context, Promo promo) {
  switch (promo.target) {
    case PromoTarget(type: PromoTargetType.category, :final value):
      context.push(searchLocation(categoryCode: value));
    case PromoTarget(type: PromoTargetType.search, :final value):
      context.push(searchLocation(query: value));
    case PromoTarget(type: PromoTargetType.listing, :final value):
      context.push(RouteNames.listingView(value));
    case null:
      showComingSoon(context);
  }
}
