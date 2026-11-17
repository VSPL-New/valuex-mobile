import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

/// One open connection to the gateway. The client talks to this instead of a socket package, so
/// its logic can be tested with a fake.
abstract interface class RealtimeSocket {
  /// The text frames from the server; the stream ends when the connection closes.
  Stream<String> get messages;

  /// The code the server closed with, known once [messages] has ended; null for an abnormal close.
  int? get closeCode;

  void send(String text);

  Future<void> close([int? code, String? reason]);
}

/// Opens a connection to [uri]; completes when the handshake is done and throws when it is refused.
typedef RealtimeSocketFactory = Future<RealtimeSocket> Function(Uri uri);

/// The socket of the app: `web_socket_channel`.
Future<RealtimeSocket> connectWebSocket(Uri uri) async {
  final channel = WebSocketChannel.connect(uri);
  await channel.ready;
  return _ChannelSocket(channel);
}

class _ChannelSocket implements RealtimeSocket {
  final WebSocketChannel _channel;

  _ChannelSocket(this._channel);

  @override
  Stream<String> get messages => _channel.stream.where((frame) => frame is String).cast<String>();

  @override
  int? get closeCode => _channel.closeCode;

  @override
  void send(String text) => _channel.sink.add(text);

  @override
  Future<void> close([int? code, String? reason]) => _channel.sink.close(code, reason);
}
