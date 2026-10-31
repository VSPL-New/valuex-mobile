import '../../payment/domain/payment_checkout.dart';
import 'seller_plan.dart';

/// What the server answers to choosing a plan (US-008). The amount is the server's; the checkout is null
/// when the plan costs nothing.
class PlanSelection {
  final String planCode;
  final bool paymentRequired;
  final String listingStatus;
  final double amount;
  final CheckoutRequest? checkout;

  const PlanSelection({
    required this.planCode,
    required this.paymentRequired,
    required this.listingStatus,
    required this.amount,
    this.checkout,
  });

  factory PlanSelection.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'];
    return PlanSelection(
      planCode: json['planCode'] as String,
      paymentRequired: json['paymentRequired'] as bool,
      listingStatus: json['listingStatus'] as String,
      amount: (json['amount'] as num).toDouble(),
      checkout: payment is Map<String, dynamic> ? CheckoutRequest.fromJson(payment) : null,
    );
  }
}

/// The few details of the listing the plan and review pages repeat back to the seller.
class ListingSummary {
  final String title;
  final String categoryPath;
  final String price;
  final String description;

  const ListingSummary({
    required this.title,
    required this.categoryPath,
    required this.price,
    required this.description,
  });
}

/// What the plan page is opened with.
class PlanArgs {
  final String listingId;
  final ListingSummary summary;

  const PlanArgs({required this.listingId, required this.summary});
}

/// What the review page is opened with: the plan the seller chose and the server's answer.
class ReviewArgs {
  final String listingId;
  final ListingSummary summary;
  final SellerPlan plan;
  final PlanSelection selection;

  const ReviewArgs({
    required this.listingId,
    required this.summary,
    required this.plan,
    required this.selection,
  });
}
