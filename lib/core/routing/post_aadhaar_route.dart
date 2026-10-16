import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where to go once Aadhaar verification ends, when it was started from the middle of
/// another journey (the seller who submits a listing before verifying). Null when the user
/// opened Aadhaar on its own; they then land on Home.
class PostAadhaarRoute extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String route) => state = route;

  void clear() => state = null;
}

final postAadhaarRouteProvider = NotifierProvider<PostAadhaarRoute, String?>(PostAadhaarRoute.new);
