import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

/// "2m ago", "1h ago", "3d ago" for the chat list; "Just now" under a minute. Older than a week
/// shows the date. [now] is passed in so the result can be tested.
String chatAgo(BuildContext context, DateTime? at, DateTime now) {
  final l10n = AppLocalizations.of(context);
  if (at == null) return '';
  final elapsed = now.difference(at);
  if (elapsed.inMinutes < 1) return l10n.chatAgoNow;
  if (elapsed.inMinutes < 60) return l10n.chatAgoMinutes(elapsed.inMinutes);
  if (elapsed.inHours < 24) return l10n.chatAgoHours(elapsed.inHours);
  if (elapsed.inDays < 7) return l10n.chatAgoDays(elapsed.inDays);
  return MaterialLocalizations.of(context).formatShortDate(at);
}

/// The clock time shown on a bubble, in the device's 12 or 24 hour style.
String chatClock(BuildContext context, DateTime at) =>
    MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(at),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context));

/// True when both times fall on the same calendar day.
bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
