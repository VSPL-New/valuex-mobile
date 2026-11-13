import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/square_back_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/presentation/widgets/listing_card.dart';
import '../../search/domain/search_listing.dart';
import '../../search/presentation/search_labels.dart';
import '../data/listing_view_repository.dart';
import 'listing_view_messages.dart';
import 'providers/listing_view_providers.dart';

/// A seller's other live listings and reviews (US-012). Reviews stay "coming soon" until Sprint 8.
class SellerProfileScreen extends StatefulWidget {
  final String sellerId;

  const SellerProfileScreen({super.key, required this.sellerId});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  SquareBackButton(
                    onPressed: () => context.canPop() ? context.pop() : context.go(RouteNames.home),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(l10n.sellerProfileTitle, style: AppTextStyles.sectionTitle),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _Tab(
                  label: l10n.sellerProfileListings,
                  selected: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
              ),
              Expanded(
                child: _Tab(
                  label: l10n.sellerProfileReviews,
                  selected: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
              ),
            ],
          ),
          Expanded(
            child: _tab == 0
                ? _SellerListings(sellerId: widget.sellerId)
                : _SellerReviews(sellerId: widget.sellerId),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? AppColors.brandPrimary : AppColors.brandDivider,
                  width: selected ? 2 : 1,
                ),
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: selected ? AppColors.brandLink : AppColors.brandMutedText,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SellerListings extends ConsumerStatefulWidget {
  final String sellerId;

  const _SellerListings({required this.sellerId});

  @override
  ConsumerState<_SellerListings> createState() => _SellerListingsState();
}

class _SellerListingsState extends ConsumerState<_SellerListings> {
  final List<SearchListing> _items = [];
  Object? _error;
  bool _loading = true;
  bool _hasNext = false;
  int _nextPage = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref
          .read(listingViewRepositoryProvider)
          .sellerListings(widget.sellerId, page: _nextPage);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _hasNext = page.hasNext;
        _nextPage = page.page + 1;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = _error;
    if (_items.isEmpty) {
      if (_loading) return const LoadingIndicator();
      if (error != null) {
        return ErrorView(
          message: listingViewErrorMessage(l10n, error),
          onRetry: listingViewErrorFinal(error) ? null : _load,
        );
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Semantics(
            liveRegion: true,
            child: Text(
              l10n.sellerProfileNoListings,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final rows = (_items.length + 1) ~/ 2;
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: rows + 1,
      itemBuilder: (context, row) {
        if (row == rows) return _footer(l10n);
        final first = _items[row * 2];
        final second = row * 2 + 1 < _items.length ? _items[row * 2 + 1] : null;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md - 4),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _card(first)),
                const SizedBox(width: AppSpacing.md - 4),
                Expanded(child: second == null ? const SizedBox.shrink() : _card(second)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _card(SearchListing listing) => ListingCard(
        listing: listing.toCardListing(),
        onTap: () => context.push(RouteNames.listingView(listing.id)),
      );

  Widget _footer(AppLocalizations l10n) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _hasNext) {
      return Center(
        child: TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
          ),
          onPressed: _load,
          child: Text(
            _error != null ? l10n.searchLoadMoreFailed : l10n.sellerProfileLoadMore,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _SellerReviews extends ConsumerWidget {
  final String sellerId;

  const _SellerReviews({required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reviews = ref.watch(sellerReviewsProvider(sellerId));
    return reviews.when(
      loading: () => const LoadingIndicator(),
      error: (error, stack) => ErrorView(
        message: listingViewErrorMessage(l10n, error),
        onRetry: listingViewErrorFinal(error)
            ? null
            : () => ref.invalidate(sellerReviewsProvider(sellerId)),
      ),
      data: (data) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Semantics(
            liveRegion: true,
            child: Text(
              data.available ? l10n.sellerProfileNoReviews : l10n.sellerProfileReviewsSoon,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
