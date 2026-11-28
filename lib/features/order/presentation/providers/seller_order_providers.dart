import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../../listing/data/listing_repository.dart';
import '../../data/mock_seller_order_repository.dart';
import '../../data/seller_order_repository_impl.dart';
import '../../domain/entities/incoming_order.dart';
import '../../domain/repositories/seller_order_repository.dart';

/// The backend, or the Make sample orders when the app runs with `SELLER_ORDERS=mock`.
final sellerOrderRepositoryProvider = Provider<SellerOrderRepository>((ref) {
  if (ref.watch(appConfigProvider).useMockSellerOrders) return MockSellerOrderRepository();
  return SellerOrderRepositoryImpl(
      ref.watch(apiClientProvider), ref.watch(listingRepositoryProvider));
});

class SellerOrdersState {
  final OrdersSummary summary;
  final List<IncomingOrder> items;

  /// The first page is loading (also during a refresh).
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int nextPage;

  /// Why the list could not be loaded; when [items] is not empty the last loaded list stays.
  final Object? error;

  /// The order whose button is being processed; its buttons are disabled meanwhile.
  final String? busyOrderId;

  const SellerOrdersState({
    this.summary = const OrdersSummary(),
    this.items = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.nextPage = 0,
    this.error,
    this.busyOrderId,
  });

  bool get loaded => error == null && !(isLoading && items.isEmpty);

  SellerOrdersState copyWith({
    OrdersSummary? summary,
    List<IncomingOrder>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? nextPage,
    Object? error,
    bool clearError = false,
    String? busyOrderId,
    bool clearBusy = false,
  }) {
    return SellerOrdersState(
      summary: summary ?? this.summary,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      nextPage: nextPage ?? this.nextPage,
      error: clearError ? null : (error ?? this.error),
      busyOrderId: clearBusy ? null : (busyOrderId ?? this.busyOrderId),
    );
  }
}

/// US-112 Incoming Orders: the counts and the list, a page at a time, and the two actions the
/// page runs itself (Start Packing, Mark as handed over). Every other button opens another screen.
class SellerOrdersController extends Notifier<SellerOrdersState> {
  int _request = 0;

  SellerOrderRepository get _repository => ref.read(sellerOrderRepositoryProvider);

  @override
  SellerOrdersState build() => const SellerOrdersState();

  /// Loads the counts and the first page together. Keeps what is shown while refreshing, so a
  /// failed refresh leaves the last loaded list on screen with the error.
  Future<void> load() async {
    final request = ++_request;
    state = state.copyWith(isLoading: true, isLoadingMore: false, clearError: true);
    try {
      final results = await Future.wait<Object>([_repository.summary(), _repository.orders()]);
      if (!ref.mounted || request != _request) return;
      final page = results[1] as IncomingOrdersPage;
      state = state.copyWith(
        summary: results[0] as OrdersSummary,
        items: page.items,
        isLoading: false,
        hasMore: page.hasMore,
        nextPage: page.page + 1,
      );
    } on ApiError catch (error) {
      if (!ref.mounted || request != _request) return;
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  /// Adds the next page below the current ones; a failure keeps what is shown.
  Future<ApiError?> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return null;
    final request = _request;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _repository.orders(page: state.nextPage);
      if (!ref.mounted || request != _request) return null;
      state = state.copyWith(
        items: [...state.items, ...page.items],
        isLoadingMore: false,
        hasMore: page.hasMore,
        nextPage: page.page + 1,
      );
      return null;
    } on ApiError catch (error) {
      if (ref.mounted && request == _request) state = state.copyWith(isLoadingMore: false);
      return error;
    }
  }

  /// Start Packing; null when it worked. The page reloads either way, so a refused card moves on.
  Future<ApiError?> startPacking(String orderId) => _act(orderId, _repository.startPacking);

  /// Mark as handed over; null when it worked.
  Future<ApiError?> markHandedOver(String orderId) => _act(orderId, _repository.markHandedOver);

  Future<ApiError?> _act(String orderId, Future<IncomingOrder> Function(String) action) async {
    if (state.busyOrderId != null) return null;
    state = state.copyWith(busyOrderId: orderId);
    ApiError? failure;
    try {
      await action(orderId);
    } on ApiError catch (error) {
      failure = error;
    }
    if (!ref.mounted) return failure;
    state = state.copyWith(clearBusy: true);
    await load();
    return failure;
  }
}

final sellerOrdersControllerProvider =
    NotifierProvider.autoDispose<SellerOrdersController, SellerOrdersState>(
        SellerOrdersController.new);
