import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../listing/data/listing_repository.dart';
import '../domain/chat.dart';

/// The result of opening a chat: the thread, and whether this call created it.
class OpenedChat {
  final ChatThread thread;
  final bool created;

  const OpenedChat({required this.thread, required this.created});
}

/// Chat with a seller (US-069, US-013). Failures surface as `ApiError`; the screens map the codes
/// to text. Every call is on the server's REST API: there is no realtime channel yet, so the
/// screens poll.
class ChatRepository {
  /// Messages in each page of history; the server's own default.
  static const int messagePageSize = 30;

  /// Conversations in each page of the list.
  static const int threadPageSize = 20;

  final ApiClient _client;
  final ListingRepository _uploads;

  ChatRepository(this._client, this._uploads);

  /// Starts the caller's chat about the listing, or returns the one that exists (201 or 200).
  Future<OpenedChat> open(String listingId) async {
    final (thread, status) = await _client.postWithStatus<ChatThread>(
      ApiConstants.chats,
      data: {'listingId': listingId},
      parse: (json) => ChatThread.fromJson(json as Map<String, dynamic>),
    );
    return OpenedChat(thread: thread, created: status == 201);
  }

  Future<ChatThreadPage> threads({ChatRole role = ChatRole.all, int page = 0}) => _client.get(
        ApiConstants.chats,
        queryParameters: {'role': role.apiName, 'page': page, 'size': threadPageSize},
        parse: (json) => ChatThreadPage.fromJson(json as Map<String, dynamic>),
      );

  Future<ChatThread> thread(String threadId) => _client.get(
        ApiConstants.chat(threadId),
        parse: (json) => ChatThread.fromJson(json as Map<String, dynamic>),
      );

  /// History in ascending order: the latest page, [beforeSeq] for older messages, [afterSeq] for
  /// what came after the last one the phone knows.
  Future<ChatMessagePage> messages(String threadId, {int? beforeSeq, int? afterSeq}) => _client.get(
        ApiConstants.chatMessages(threadId),
        queryParameters: {
          if (beforeSeq != null) 'beforeSeq': beforeSeq,
          if (afterSeq != null) 'afterSeq': afterSeq,
          'limit': messagePageSize,
        },
        parse: (json) => ChatMessagePage.fromJson(json as Map<String, dynamic>),
      );

  /// Sends a text message. The same [clientMessageId] sent again returns the stored message, so a
  /// retry after a lost answer never doubles it. [agreed] sends the Deliver message agreement.
  Future<ChatMessage> sendText(
    String threadId, {
    required String clientMessageId,
    required String body,
    bool agreed = false,
  }) =>
      _send(threadId, {
        'clientMessageId': clientMessageId,
        'type': 'TEXT',
        'body': body,
        if (agreed) 'policyAgreement': {'accepted': true, 'version': policyAgreementVersion},
      });

  Future<ChatMessage> sendImage(
    String threadId, {
    required String clientMessageId,
    required String mediaId,
  }) =>
      _send(threadId, {'clientMessageId': clientMessageId, 'type': 'IMAGE', 'mediaId': mediaId});

  Future<ChatMessage> _send(String threadId, Map<String, dynamic> data) => _client.post(
        ApiConstants.chatMessages(threadId),
        data: data,
        parse: (json) => ChatMessage.fromJson(json as Map<String, dynamic>),
      );

  /// Uploads a picture straight to storage and returns its media id for [sendImage].
  Future<String> uploadImage({
    required String ownerId,
    required String fileName,
    required String contentType,
    required Uint8List bytes,
    required int width,
    required int height,
  }) async {
    final ticket = await _client.post<UploadTicket>(
      ApiConstants.mediaUploads,
      data: {
        'purpose': 'CHAT_IMAGE',
        'ownerType': 'USER',
        'ownerId': ownerId,
        'fileName': fileName,
        'contentType': contentType,
        'sizeBytes': bytes.length,
      },
      parse: (json) {
        final map = json as Map<String, dynamic>;
        return UploadTicket(
            mediaId: map['mediaId'] as String, uploadUrl: map['uploadUrl'] as String);
      },
    );
    await _uploads.uploadBytes(ticket.uploadUrl, bytes, contentType);
    await _uploads.completeUpload(
      mediaId: ticket.mediaId,
      contentType: contentType,
      sizeBytes: bytes.length,
      width: width,
      height: height,
    );
    return ticket.mediaId;
  }

  Future<void> markDelivered(String threadId, int upToSeq) =>
      _client.post<void>(ApiConstants.chatDelivered(threadId), data: {'upToSeq': upToSeq});

  Future<void> markRead(String threadId, int upToSeq) =>
      _client.post<void>(ApiConstants.chatRead(threadId), data: {'upToSeq': upToSeq});

  Future<int> unreadCount() => _client.get(
        ApiConstants.chatsUnreadCount,
        parse: (json) => ((json as Map<String, dynamic>)['chatsUnread'] as num?)?.toInt() ?? 0,
      );
}

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(apiClientProvider), ref.watch(listingRepositoryProvider)),
);
