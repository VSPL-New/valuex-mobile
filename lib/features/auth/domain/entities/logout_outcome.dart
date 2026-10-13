/// How far a logout got on the server. The device is always logged out.
enum LogoutOutcome {
  /// The server ended the session, or it had already ended.
  revoked,

  /// The server could not be reached; the logout is sent again later.
  queued,
}
