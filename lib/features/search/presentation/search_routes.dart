import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../listing/domain/category.dart';
import '../domain/search_criteria.dart';
import '../domain/transaction_intent.dart';

/// The deep link of a search, for example `/search?q=laptop` or `/search?category=CAT-0001`.
String searchLocation({
  String? query,
  String? categoryCode,
  String? categoryName,
  int? categoryLevel,
  bool realEstate = false,
  bool browseAll = false,
  TransactionIntent? intent,
}) {
  final params = <String, String>{
    if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
    if (categoryCode != null) 'category': categoryCode,
    if (categoryName != null) 'categoryName': categoryName,
    if (categoryLevel != null) 'level': '$categoryLevel',
    if (realEstate) 'realEstate': 'true',
    if (browseAll) 'all': 'true',
    if (intent != null) 'intent': intent.apiValue,
  };
  return Uri(path: RouteNames.search, queryParameters: params.isEmpty ? null : params).toString();
}

/// Reads what [searchLocation] wrote.
SearchCriteria searchCriteriaFromParams(Map<String, String> params) {
  final query = (params['q'] ?? '').trim();
  return SearchCriteria(
    query: query.length > SearchCriteria.maxQueryLength
        ? query.substring(0, SearchCriteria.maxQueryLength)
        : query,
    categoryCode: params['category'],
    categoryName: params['categoryName'],
    categoryLevel: int.tryParse(params['level'] ?? ''),
    realEstate: params['realEstate'] == 'true',
    browseAll: params['all'] == 'true',
    intent: TransactionIntent.fromApi(params['intent']),
  );
}

/// The browse screen for the children of a category, or the top level without one.
String categoryBrowseLocation({
  String? parentCode,
  String? parentName,
  int? parentLevel,
  bool realEstate = false,
}) {
  final params = <String, String>{
    if (parentCode != null) 'parent': parentCode,
    if (parentName != null) 'name': parentName,
    if (parentLevel != null) 'level': '$parentLevel',
    if (realEstate) 'realEstate': 'true',
  };
  return Uri(
    path: RouteNames.searchCategories,
    queryParameters: params.isEmpty ? null : params,
  ).toString();
}

/// Real Estate is the only category group with property listings. The category list does not
/// say which one it is, so the top-level name is used; if that ever misses, the server answers
/// `ERROR_INTENT_REQUIRED` and the app asks for Buy, Rent or Lease then.
bool isRealEstateRoot(CategoryNode node) =>
    node.level == 1 && node.name.trim().toLowerCase() == 'real estate';

/// Opens a category: its sub-categories while there are some, otherwise its listings.
/// [realEstate] is true when the user already came through Real Estate.
void openCategory(BuildContext context, CategoryNode node, {bool realEstate = false}) {
  final inRealEstate = realEstate || isRealEstateRoot(node);
  if (node.hasChildren && node.level < 3) {
    context.push(
      categoryBrowseLocation(
        parentCode: node.code,
        parentName: node.name,
        parentLevel: node.level,
        realEstate: inRealEstate,
      ),
    );
    return;
  }
  openCategoryListings(context, node, realEstate: inRealEstate);
}

/// Opens every listing in a category of any level.
void openCategoryListings(BuildContext context, CategoryNode node, {bool realEstate = false}) {
  context.push(
    searchLocation(
      categoryCode: node.code,
      categoryName: node.name,
      categoryLevel: node.level,
      realEstate: realEstate || isRealEstateRoot(node),
    ),
  );
}
