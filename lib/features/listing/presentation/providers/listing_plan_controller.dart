import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/provider_retry.dart';
import '../../data/listing_repository.dart';
import '../../domain/seller_plan.dart';

/// The plans from the server; read again each time the page opens. A failure shows Retry
/// instead of retrying by itself.
final sellerPlansProvider = FutureProvider.autoDispose<List<SellerPlan>>(
  (ref) => ref.watch(listingRepositoryProvider).sellerPlans(),
  retry: noAutoRetry,
);

/// The plan code the seller tapped; null until they choose (see [effectivePlan]).
class SelectedPlanCode extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String code) => state = code;
}

final selectedPlanCodeProvider =
    NotifierProvider.autoDispose<SelectedPlanCode, String?>(SelectedPlanCode.new);
