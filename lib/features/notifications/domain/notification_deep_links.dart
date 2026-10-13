import '../../../core/routing/route_names.dart';

/// Screens the backend's notification deep links open in the app.
class NotificationTarget {
  final String route;

  /// Main tabs are switched to; every other screen is pushed on top.
  final bool isTab;

  const NotificationTarget(this.route, {this.isTab = false});
}

const Map<String, NotificationTarget> _targets = {
  '/profile': NotificationTarget(RouteNames.profile, isTab: true),
  '/profile/account-security': NotificationTarget(RouteNames.accountSecurity),
};

/// Null while the destination is not built yet (for example `/support`).
NotificationTarget? notificationTargetFor(String? deepLink) {
  if (deepLink == null) return null;
  final path = deepLink.split('?').first;
  return _targets[
      path.length > 1 && path.endsWith('/') ? path.substring(0, path.length - 1) : path];
}
