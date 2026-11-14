import '../../../core/routing/route_names.dart';

/// Screens the backend's notification deep links open in the app.
class NotificationTarget {
  final String route;

  /// Main tabs are switched to; every other screen is pushed on top.
  final bool isTab;

  /// Set for the listing pages (Item Details, plan selection): they need the listing's data, which
  /// is loaded when the notification is tapped.
  final String? listingId;

  const NotificationTarget(this.route, {this.isTab = false, this.listingId});

  bool get needsListing => listingId != null;
}

const Map<String, NotificationTarget> _targets = {
  '/profile': NotificationTarget(RouteNames.profile, isTab: true),
  '/profile/account-security': NotificationTarget(RouteNames.accountSecurity),
  '/saved-items': NotificationTarget(RouteNames.savedItems),
};

/// Deep link paths that open a listing page, with the route they open.
const Map<String, String> _listingRoutes = {
  '/sell/details': RouteNames.sellDetails,
  '/sell/plan': RouteNames.sellPlan,
};

/// Null while the destination is not built yet (for example `/support`).
NotificationTarget? notificationTargetFor(String? deepLink) {
  if (deepLink == null) return null;
  final uri = Uri.tryParse(deepLink);
  if (uri == null) return null;
  final path = uri.path.length > 1 && uri.path.endsWith('/')
      ? uri.path.substring(0, uri.path.length - 1)
      : uri.path;
  if (path == RouteNames.savedSearches) {
    // The daily saved-search alert (US-066): opens that search's results.
    final id = uri.queryParameters['id'];
    return id == null || id.isEmpty ? null : NotificationTarget(RouteNames.savedSearch(id));
  }
  final listingRoute = _listingRoutes[path];
  if (listingRoute != null) {
    final listingId = uri.queryParameters['listingId'];
    return listingId == null || listingId.isEmpty
        ? null
        : NotificationTarget(listingRoute, listingId: listingId);
  }
  return _targets[path];
}
