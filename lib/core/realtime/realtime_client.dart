import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import '../network/api_error.dart';
import 'realtime_event.dart';
import 'realtime_socket.dart';
import 'realtime_ticket.dart';

/// Gets a ticket for the next connection.
typedef RealtimeTicketSource = Future<RealtimeTicket> Function();

/// The live connection to the server (US-130). One client serves the signed-in session; the
/// features read typed providers built on [events] and never the socket itself. Realtime is a
/// hint: after every gap the screens re-read over REST, which [resyncs] tells them to do.
abstract interface class RealtimeClient {
  /// The events of the server, each id once, in arrival order. Pongs are not events.
  Stream<RealtimeEvent> get events;

  Stream<RealtimeStatus> get statuses;

  RealtimeStatus get status;

  /// Fires after every (re)connect and when the app comes back to the foreground: the moment to
  /// re-read what may have been missed.
  Stream<void> get resyncs;

  /// Starts keeping a connection open (idempotent). Also the user action that lets a session
  /// replaced by another device connect again.
  void connect();

  /// Stops keeping a connection open and closes the current one.
  Future<void> disconnect();

  /// Tells the server whether the app is on screen; a long stay in the background closes the socket.
  void setForeground(bool foreground);

  /// Sends a frame; false when the socket is not open (the caller falls back to REST).
  bool send(String type, [Map<String, dynamic>? data]);

  void dispose();
}

/// [RealtimeClient] over a WebSocket: ticket, connect, ping, backoff and the close codes of the
/// server (LLD A.7).
class WebSocketRealtimeClient implements RealtimeClient {
  static const _backoffSeconds = [1, 2, 4, 8, 16, 30];

  final RealtimeTicketSource _issueTicket;
  final RealtimeSocketFactory _openSocket;
  final Future<void> Function()? _onAccountInactive;
  final math.Random _random;
  final Duration _degradedAfter;
  final Duration _backgroundGrace;
  final Duration _stableAfter;
  final Duration _rateBackoff;

  final _events = StreamController<RealtimeEvent>.broadcast();
  final _statuses = StreamController<RealtimeStatus>.broadcast();
  final _resyncs = StreamController<void>.broadcast();
  final _deduper = EventDeduper();

  RealtimeStatus _status = RealtimeStatus.idle;
  bool _wanted = false;
  bool _blocked = false;
  bool _foreground = true;
  bool _hadConnection = false;
  bool _disposed = false;
  int _attempt = 0;
  int _generation = 0;
  RealtimeSocket? _socket;
  StreamSubscription<String>? _subscription;
  Timer? _pingTimer;
  Timer? _retryTimer;
  Timer? _degradeTimer;
  Timer? _stableTimer;
  Timer? _backgroundTimer;

  /// [onAccountInactive] runs when the server says the account is not active (the app then reads
  /// the account state and shows its screen). [random] spreads the retries; the timings are
  /// parameters so tests do not wait.
  WebSocketRealtimeClient({
    required RealtimeTicketSource issueTicket,
    required RealtimeSocketFactory openSocket,
    Future<void> Function()? onAccountInactive,
    math.Random? random,
    Duration degradedAfter = const Duration(seconds: 60),
    Duration backgroundGrace = const Duration(seconds: 30),
    Duration stableAfter = const Duration(seconds: 60),
    Duration rateBackoff = const Duration(seconds: 30),
  })  : _issueTicket = issueTicket,
        _openSocket = openSocket,
        _onAccountInactive = onAccountInactive,
        _random = random ?? math.Random(),
        _degradedAfter = degradedAfter,
        _backgroundGrace = backgroundGrace,
        _stableAfter = stableAfter,
        _rateBackoff = rateBackoff;

  @override
  Stream<RealtimeEvent> get events => _events.stream;

  @override
  Stream<RealtimeStatus> get statuses => _statuses.stream;

  @override
  Stream<void> get resyncs => _resyncs.stream;

  @override
  RealtimeStatus get status => _status;

  @override
  void connect() {
    if (_disposed) return;
    final open = _status == RealtimeStatus.connected || _status == RealtimeStatus.connecting;
    _blocked = false;
    if (_wanted && open) return;
    _wanted = true;
    _attempt = 0;
    _startAttempt();
  }

  @override
  Future<void> disconnect() async {
    _wanted = false;
    _blocked = false;
    _hadConnection = false;
    _generation++;
    _cancelTimers();
    _closeSocket();
    _setStatus(RealtimeStatus.idle);
  }

  @override
  void setForeground(bool foreground) {
    if (_disposed) return;
    _foreground = foreground;
    _backgroundTimer?.cancel();
    if (!foreground) {
      if (_status == RealtimeStatus.connected) send(RealtimeTypes.appState, {'foreground': false});
      _backgroundTimer = Timer(_backgroundGrace, _suspend);
      return;
    }
    if (_status == RealtimeStatus.connected) {
      send(RealtimeTypes.appState, {'foreground': true});
      _resyncs.add(null);
    } else if (_wanted && !_blocked && _status != RealtimeStatus.connecting) {
      _attempt = 0;
      _startAttempt();
    }
  }

  @override
  bool send(String type, [Map<String, dynamic>? data]) {
    final socket = _socket;
    if (_status != RealtimeStatus.connected || socket == null) return false;
    try {
      socket.send(jsonEncode({'type': type, if (data != null) 'data': data}));
      return true;
    } on Object {
      return false;
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    unawaited(disconnect());
    _disposed = true;
    unawaited(_events.close());
    unawaited(_statuses.close());
    unawaited(_resyncs.close());
  }

  void _startAttempt() {
    _retryTimer?.cancel();
    unawaited(_open(++_generation));
  }

  Future<void> _open(int generation) async {
    if (_status != RealtimeStatus.degraded) {
      _setStatus(_hadConnection ? RealtimeStatus.reconnecting : RealtimeStatus.connecting);
    }
    _degradeTimer ??= Timer(_degradedAfter, _degrade);
    RealtimeTicket ticket;
    try {
      ticket = await _issueTicket();
    } on ApiError catch (error) {
      if (generation == _generation) _onTicketFailed(error);
      return;
    } on Object {
      if (generation == _generation) _scheduleRetry();
      return;
    }
    if (generation != _generation) return;
    RealtimeSocket socket;
    try {
      socket = await _openSocket(ticket.socketUri);
    } on Object {
      if (generation == _generation) _scheduleRetry();
      return;
    }
    if (generation != _generation || !_wanted) {
      unawaited(_close(socket));
      return;
    }
    _attach(socket, generation, ticket.pingIntervalSeconds);
  }

  void _onTicketFailed(ApiError error) {
    if (error.code == 'ERROR_REALTIME_UNAVAILABLE') {
      _degrade();
      _scheduleRetry();
    } else if (error.code == 'ERROR_ACCOUNT_NOT_ACTIVE') {
      _stop(blocked: true);
    } else if (error.type == ApiErrorType.unauthorized ||
        error.type == ApiErrorType.sessionExpired) {
      // The session ended; the session controller takes the user to Sign In.
      _wanted = false;
      _cancelTimers();
      _setStatus(RealtimeStatus.idle);
    } else {
      _scheduleRetry();
    }
  }

  void _attach(RealtimeSocket socket, int generation, int pingSeconds) {
    _socket = socket;
    _hadConnection = true;
    _degradeTimer?.cancel();
    _degradeTimer = null;
    _setStatus(RealtimeStatus.connected);
    _subscription = socket.messages.listen(
      _onFrame,
      onDone: () => _onClosed(generation, socket.closeCode),
      onError: (Object _) => _onClosed(generation, null),
      cancelOnError: true,
    );
    _pingTimer = Timer.periodic(Duration(seconds: pingSeconds), (_) => send(RealtimeTypes.ping));
    _stableTimer = Timer(_stableAfter, () => _attempt = 0);
    send(RealtimeTypes.appState, {'foreground': _foreground});
    _resyncs.add(null);
  }

  void _onFrame(String frame) {
    final event = RealtimeEvent.tryParse(frame);
    if (event == null || event.type == RealtimeTypes.pong) return;
    if (_deduper.firstTime(event.id)) _events.add(event);
  }

  void _onClosed(int generation, int? code) {
    if (generation != _generation) return;
    _closeSocket();
    _pingTimer?.cancel();
    _stableTimer?.cancel();
    if (!_wanted) {
      _setStatus(RealtimeStatus.idle);
      return;
    }
    switch (code) {
      case RealtimeCloseCodes.accountNotActive:
        _stop(blocked: true);
      case RealtimeCloseCodes.sessionReplaced:
        _stop(blocked: false);
      case RealtimeCloseCodes.tokenExpired:
        // The ticket call refreshes the access token when it has expired.
        _attempt = 0;
        _startAttempt();
      case RealtimeCloseCodes.rateExceeded:
        _scheduleRetry(delay: _rateBackoff);
      default:
        _scheduleRetry();
    }
  }

  void _stop({required bool blocked}) {
    _blocked = blocked;
    _cancelTimers();
    _setStatus(RealtimeStatus.stopped);
    if (blocked) unawaited(_notifyInactive());
  }

  Future<void> _notifyInactive() async {
    try {
      await _onAccountInactive?.call();
    } on Object {
      // The next start of the app reads the account state again.
    }
  }

  void _scheduleRetry({Duration? delay}) {
    if (!_wanted) return;
    final base =
        delay ?? Duration(seconds: _backoffSeconds[math.min(_attempt, _backoffSeconds.length - 1)]);
    _attempt++;
    final spread = 0.8 + _random.nextDouble() * 0.4;
    if (_status != RealtimeStatus.degraded) _setStatus(RealtimeStatus.reconnecting);
    _degradeTimer ??= Timer(_degradedAfter, _degrade);
    _retryTimer?.cancel();
    _retryTimer =
        Timer(Duration(milliseconds: (base.inMilliseconds * spread).round()), _startAttempt);
  }

  void _degrade() {
    final settled = _status == RealtimeStatus.connected || _status == RealtimeStatus.stopped;
    if (!_wanted || settled) return;
    _setStatus(RealtimeStatus.degraded);
  }

  /// A long stay in the background: the socket closes and comes back when the app does.
  void _suspend() {
    if (!_wanted) return;
    _generation++;
    _cancelTimers();
    _closeSocket();
    _setStatus(RealtimeStatus.idle);
  }

  void _cancelTimers() {
    for (final timer in [_pingTimer, _retryTimer, _degradeTimer, _stableTimer, _backgroundTimer]) {
      timer?.cancel();
    }
    _pingTimer = _retryTimer = _degradeTimer = _stableTimer = _backgroundTimer = null;
  }

  void _closeSocket() {
    final socket = _socket;
    _socket = null;
    final subscription = _subscription;
    _subscription = null;
    unawaited(subscription?.cancel());
    if (socket != null) {
      unawaited(_close(socket));
    }
  }

  Future<void> _close(RealtimeSocket socket) async {
    try {
      await socket.close(1000);
    } on Object {
      // Already closed.
    }
  }

  void _setStatus(RealtimeStatus status) {
    if (_status == status || _statuses.isClosed) return;
    _status = status;
    _statuses.add(status);
  }
}
