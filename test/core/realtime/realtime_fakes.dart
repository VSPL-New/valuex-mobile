import 'dart:async';
import 'dart:convert';

import 'package:valuex_mobile/core/realtime/realtime_client.dart';
import 'package:valuex_mobile/core/realtime/realtime_event.dart';
import 'package:valuex_mobile/core/realtime/realtime_socket.dart';

/// A client the tests drive by hand: they emit events, move the status and read what the app sent.
class FakeRealtimeClient implements RealtimeClient {
  final _events = StreamController<RealtimeEvent>.broadcast();
  final _statuses = StreamController<RealtimeStatus>.broadcast();
  final _resyncs = StreamController<void>.broadcast();

  /// The frames the app sent while [open] was true.
  final List<({String type, Map<String, dynamic>? data})> sent = [];

  /// Whether [send] reports success, like a socket that is open.
  bool open = false;

  RealtimeStatus _status = RealtimeStatus.idle;
  int connects = 0;
  int disconnects = 0;
  bool? foreground;
  int _ids = 0;

  @override
  Stream<RealtimeEvent> get events => _events.stream;

  @override
  Stream<RealtimeStatus> get statuses => _statuses.stream;

  @override
  Stream<void> get resyncs => _resyncs.stream;

  @override
  RealtimeStatus get status => _status;

  void emit(String type, Map<String, dynamic> data, {String? id}) {
    _events.add(RealtimeEvent(id: id ?? 'e${_ids++}', type: type, data: data));
  }

  void setStatus(RealtimeStatus status) {
    _status = status;
    _statuses.add(status);
  }

  void resync() => _resyncs.add(null);

  @override
  void connect() => connects++;

  @override
  Future<void> disconnect() async => disconnects++;

  @override
  void setForeground(bool foreground) => this.foreground = foreground;

  @override
  bool send(String type, [Map<String, dynamic>? data]) {
    if (!open) return false;
    sent.add((type: type, data: data));
    return true;
  }

  @override
  void dispose() {
    _events.close();
    _statuses.close();
    _resyncs.close();
  }
}

/// A socket the tests drive by hand: they push frames, close it with a code and read what was sent.
class FakeSocket implements RealtimeSocket {
  final _frames = StreamController<String>();
  final List<String> sent = [];
  int? _closeCode;
  bool closed = false;

  @override
  Stream<String> get messages => _frames.stream;

  @override
  int? get closeCode => _closeCode;

  void push(Map<String, dynamic> frame) => _frames.add(jsonEncode(frame));

  void pushRaw(String frame) => _frames.add(frame);

  /// The server closes the connection with [code].
  void serverClose(int? code) {
    _closeCode = code;
    unawaited(_frames.close());
  }

  /// The connection breaks.
  void fail() => _frames.addError(StateError('broken'));

  List<Map<String, dynamic>> get sentFrames =>
      [for (final text in sent) jsonDecode(text) as Map<String, dynamic>];

  @override
  void send(String text) => sent.add(text);

  @override
  Future<void> close([int? code, String? reason]) async {
    closed = true;
    if (!_frames.isClosed) await _frames.close();
  }
}
