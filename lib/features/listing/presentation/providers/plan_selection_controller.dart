import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../data/listing_repository.dart';
import '../../domain/plan_selection.dart';

enum PlanSelectionOutcome { selected, aadhaarRequired, failed }

class PlanSelectionResult {
  final PlanSelectionOutcome outcome;
  final PlanSelection? selection;
  final Object? error;

  const PlanSelectionResult(this.outcome, {this.selection, this.error});
}

/// Asks the server to start the plan for a draft. The state is true while the request is running.
class PlanSelectionController extends Notifier<bool> {
  static const String aadhaarRequiredCode = 'AADHAAR_VERIFICATION_REQUIRED';

  @override
  bool build() => false;

  Future<PlanSelectionResult> select(String listingId, String planCode) async {
    state = true;
    try {
      final selection = await ref.read(listingRepositoryProvider).selectPlan(listingId, planCode);
      return PlanSelectionResult(PlanSelectionOutcome.selected, selection: selection);
    } on ApiError catch (error) {
      if (error.code == aadhaarRequiredCode) {
        return const PlanSelectionResult(PlanSelectionOutcome.aadhaarRequired);
      }
      return PlanSelectionResult(PlanSelectionOutcome.failed, error: error);
    } finally {
      state = false;
    }
  }
}

final planSelectionControllerProvider =
    NotifierProvider.autoDispose<PlanSelectionController, bool>(PlanSelectionController.new);
