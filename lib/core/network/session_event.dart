/// Why the stored session ended.
enum SessionEndReason { expired, suspended, recoveryRequired }

/// Changes to the stored session that the rest of the app needs to react to.
sealed class SessionEvent {
  const SessionEvent();
}

/// A refresh succeeded; carries the account state the server read at refresh time.
class SessionRefreshed extends SessionEvent {
  final String? status;
  final bool? aadhaarVerified;

  const SessionRefreshed({this.status, this.aadhaarVerified});
}

/// The session can no longer be renewed and its tokens were cleared.
class SessionEnded extends SessionEvent {
  final SessionEndReason reason;

  const SessionEnded(this.reason);
}
