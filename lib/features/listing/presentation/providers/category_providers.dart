import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/provider_retry.dart';
import '../../data/listing_repository.dart';
import '../../domain/category.dart';

/// Which children to list: the top level when [parentCode] is null.
typedef CategoryQuery = ({String? parentCode, CategoryScope scope});

/// Child categories for the picker. A failure shows Retry instead of retrying by itself.
final categoryChildrenProvider =
    FutureProvider.autoDispose.family<List<CategoryNode>, CategoryQuery>(
  (ref, query) => ref
      .watch(listingRepositoryProvider)
      .categoryChildren(parentCode: query.parentCode, scope: query.scope),
  retry: noAutoRetry,
);

/// Leaf categories matching the text typed in the picker.
final categorySearchProvider = FutureProvider.autoDispose.family<List<CategoryRef>, String>(
  (ref, query) => ref.watch(listingRepositoryProvider).searchCategories(query),
  retry: noAutoRetry,
);
