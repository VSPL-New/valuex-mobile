import 'package:flutter/widgets.dart';

/// [normal] unless the user asked the system to reduce motion, in which case there is no animation.
Duration motionDuration(BuildContext context, Duration normal) {
  return MediaQuery.disableAnimationsOf(context) ? Duration.zero : normal;
}
