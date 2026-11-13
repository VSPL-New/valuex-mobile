import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../search/presentation/search_routes.dart';
import '../domain/entities/promo.dart';
import 'main_nav.dart';

/// Opens what a promo leads to, always inside the app. A promo for a listing waits for the buyer
/// listing details screen (US-012), and sample promos have no target, so both say "coming soon".
void openPromo(BuildContext context, Promo promo) {
  switch (promo.target) {
    case PromoTarget(type: PromoTargetType.category, :final value):
      context.push(searchLocation(categoryCode: value));
    case PromoTarget(type: PromoTargetType.search, :final value):
      context.push(searchLocation(query: value));
    case PromoTarget(type: PromoTargetType.listing) || null:
      showComingSoon(context);
  }
}
