import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/theme/app_theme.dart';
import 'package:valuex_mobile/features/chat/domain/chat.dart';
import 'package:valuex_mobile/features/chat/presentation/chat_error_messages.dart';
import 'package:valuex_mobile/features/chat/presentation/contact_error_messages.dart';
import 'package:valuex_mobile/features/chat/presentation/widgets/blocked_message_sheet.dart';
import 'package:valuex_mobile/features/chat/presentation/widgets/chat_time.dart';
import 'package:valuex_mobile/features/chat/presentation/widgets/composer.dart';
import 'package:valuex_mobile/features/chat/presentation/widgets/message_bubble.dart';
import 'package:valuex_mobile/features/chat/presentation/widgets/system_card.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../helpers/fonts.dart';
import 'chat_fixtures.dart';

Future<void> pumpWidgetApp(WidgetTester tester, Widget child,
        {Locale locale = const Locale('en')}) =>
    tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ));

ApiError _error(String code, {int status = 422, ApiErrorType type = ApiErrorType.business}) =>
    ApiError(type: type, message: 'Image exceeds 7 MB', code: code, statusCode: status);

void main() {
  setUpAll(loadBrandFonts);

  group('composer', () {
    testWidgets('Send is dimmed and silent while empty, and sends the trimmed text',
        (tester) async {
      final controller = TextEditingController();
      final sent = <String>[];
      await pumpWidgetApp(
          tester, ChatComposer(controller: controller, onSend: sent.add, onAttach: () {}));

      await tester.tap(find.byIcon(Icons.send_rounded));
      expect(sent, isEmpty);

      await tester.enterText(find.byType(TextField), '  Hello  ');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));

      expect(sent, ['Hello']);
    });

    testWidgets('the counter appears near the limit and turns red at it', (tester) async {
      final controller = TextEditingController();
      await pumpWidgetApp(tester,
          ChatComposer(controller: controller, onSend: (_) {}, onAttach: () {}, maxChars: 10));
      expect(find.textContaining('/10'), findsNothing);

      await tester.enterText(find.byType(TextField), '12345678');
      await tester.pump();
      expect(find.text('8/10'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '1234567890');
      await tester.pump();
      expect(find.text('10/10'), findsOneWidget);
    });

    testWidgets(
        'the field stops at the limit counted in code points, so Hindi and emoji are not penalised',
        (tester) async {
      final controller = TextEditingController();
      await pumpWidgetApp(tester,
          ChatComposer(controller: controller, onSend: (_) {}, onAttach: () {}, maxChars: 4));

      await tester.enterText(find.byType(TextField), 'नमस्ते');
      await tester.pump();
      expect(controller.text.runes.length, lessThanOrEqualTo(4));

      await tester.enterText(find.byType(TextField), '😀😀😀😀😀');
      await tester.pump();
      expect(controller.text.runes.length, lessThanOrEqualTo(4));
    });

    test('CodePointLimit keeps the old value when the new one is too long', () {
      const limit = CodePointLimit(3);
      const old = TextEditingValue(text: 'abc');

      expect(limit.formatEditUpdate(old, const TextEditingValue(text: 'abcd')), old);
      expect(limit.formatEditUpdate(old, const TextEditingValue(text: 'ab')).text, 'ab');
    });

    testWidgets('the attach icon calls back', (tester) async {
      var attached = 0;
      await pumpWidgetApp(
          tester,
          ChatComposer(
              controller: TextEditingController(), onSend: (_) {}, onAttach: () => attached++));

      await tester.tap(find.byTooltip('Attach a photo'));

      expect(attached, 1);
    });
  });

  group('message bubble', () {
    testWidgets('shows the time and the status under my message and no status under theirs',
        (tester) async {
      await pumpWidgetApp(
        tester,
        Column(children: [
          MessageBubble(
              message: message(seq: 2, body: 'Mine', fromMe: true, status: 'READ'),
              counterpartName: 'Rajesh'),
          MessageBubble(message: message(seq: 3, body: 'Theirs'), counterpartName: 'Rajesh'),
        ]),
      );

      expect(find.textContaining('Read'), findsOneWidget);
      expect(find.text('Mine'), findsOneWidget);
      expect(find.text('Theirs'), findsOneWidget);
    });

    testWidgets('a pending message says Sending', (tester) async {
      await pumpWidgetApp(
        tester,
        MessageBubble(
            message:
                message(seq: 0, body: 'Wait', fromMe: true).copyWith(status: MessageStatus.sending),
            counterpartName: 'Rajesh'),
      );

      expect(find.textContaining('Sending'), findsOneWidget);
    });

    testWidgets('a failed message offers Retry and Delete', (tester) async {
      var retried = 0;
      var deleted = 0;
      await pumpWidgetApp(
        tester,
        MessageBubble(
          message:
              message(seq: 0, body: 'Oops', fromMe: true).copyWith(status: MessageStatus.failed),
          counterpartName: 'Rajesh',
          onRetry: () => retried++,
          onDiscard: () => deleted++,
        ),
      );

      await tester.tap(find.text('Retry'));
      await tester.tap(find.text('Delete'));

      expect(retried, 1);
      expect(deleted, 1);
      expect(find.text('Not sent. Tap to retry'), findsOneWidget);
    });

    testWidgets('a flagged message from the other person carries the safety tip', (tester) async {
      await pumpWidgetApp(
        tester,
        MessageBubble(
          message:
              ChatMessage.fromJson(messageJson(seq: 2, body: 'call me', flags: ['CONTACT_INFO'])),
          counterpartName: 'Rajesh',
        ),
      );

      expect(find.text('For your safety, keep chats and payments on JustQlic.'), findsOneWidget);
    });

    testWidgets('a picture shows the pending bytes, a link, or a placeholder', (tester) async {
      final png = Uint8List.fromList(const [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 13, 0x49, 0x48, 0x44, 0x52, 0, 0,
        0, 1, 0, 0, 0, 1, //
        8, 6, 0, 0, 0, 0x1F, 0x15, 0xC4, 0x89, 0, 0, 0, 13, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C,
        0x63, 0, 1, 0, 0, //
        5, 0, 1, 0x0D, 0x0A, 0x2D, 0xB4, 0, 0, 0, 0, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);
      final pending = ChatMessage(
        seq: 0,
        clientMessageId: 'c1',
        type: ChatMessageType.image,
        fromMe: true,
        createdAt: DateTime(2026, 11, 17, 10),
        pendingImage: png,
        status: MessageStatus.sending,
      );
      await pumpWidgetApp(
        tester,
        Column(children: [
          MessageBubble(message: pending, counterpartName: 'R'),
          MessageBubble(message: message(seq: 5, type: 'IMAGE', body: null), counterpartName: 'R'),
        ]),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Photo unavailable'), findsOneWidget);
    });
  });

  group('system card', () {
    testWidgets('the listing card shows the title and price and opens the listing', (tester) async {
      var opened = 0;
      await pumpWidgetApp(
          tester, SystemCard(message: listingCard(), onOpenListing: () => opened++));

      expect(find.text('iPhone 15 Pro Max'), findsOneWidget);
      expect(find.textContaining('52,000'), findsOneWidget);
      await tester.tap(find.text('iPhone 15 Pro Max'));
      expect(opened, 1);
    });

    testWidgets('an offer card of an unknown kind shows a neutral line', (tester) async {
      await pumpWidgetApp(
        tester,
        SystemCard(message: ChatMessage.fromJson(messageJson(seq: 3, type: 'OFFER_EVENT'))),
      );

      expect(find.text('Conversation update'), findsOneWidget);
    });

    testWidgets('a call card says how the call went, from the side of the viewer', (tester) async {
      Future<void> show(Map<String, dynamic> payload, {bool buyer = true}) => pumpWidgetApp(
            tester,
            SystemCard(
              viewerIsBuyer: buyer,
              message: ChatMessage.fromJson(
                messageJson(seq: 4, type: 'CALL_SUMMARY', payload: payload),
              ),
            ),
          );

      await show({'type': 'VOICE', 'outcome': 'COMPLETED', 'durationSeconds': 125});
      expect(find.text('voice call · 2:05'), findsOneWidget);
      await show({'type': 'VIDEO', 'outcome': 'COMPLETED', 'durationSeconds': 3700});
      expect(find.text('video call · 1:01:40'), findsOneWidget);
      await show({'type': 'VOICE', 'outcome': 'MISSED'});
      expect(find.text('voice call · No answer'), findsOneWidget);
      await show({'type': 'VOICE', 'outcome': 'MISSED'}, buyer: false);
      expect(find.text('Missed voice call'), findsOneWidget);
      await show({'type': 'VIDEO', 'outcome': 'DECLINED'});
      expect(find.text('video call · Declined'), findsOneWidget);
      await show({'type': 'VOICE', 'outcome': 'FAILED'});
      expect(find.text('voice call · Not connected'), findsOneWidget);
      await show({'type': 'VOICE'});
      expect(find.text('voice call · In progress'), findsOneWidget);
    });
  });

  group('blocked message sheet', () {
    testWidgets('marks each restricted range and keeps the rest of the text', (tester) async {
      await pumpWidgetApp(
        tester,
        const BlockedMessageSheet(
            text: 'you shit and fuck', terms: [RestrictedTerm(4, 8), RestrictedTerm(13, 17)]),
      );

      final rich = tester.widget<RichText>(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText(includeSemanticsLabels: false).contains('you shit and fuck'),
        ),
      );
      expect(rich.text.toPlainText(includeSemanticsLabels: false), 'you shit and fuck');
      final spans = <TextSpan>[];
      rich.text.visitChildren((span) {
        if (span is TextSpan && span.style?.backgroundColor != null) spans.add(span);
        return true;
      });
      expect(spans.map((s) => s.text), ['shit', 'fuck']);
      expect(spans.first.semanticsLabel, 'restricted term: shit');
    });

    testWidgets('overlapping or out-of-order ranges never break the text', (tester) async {
      await pumpWidgetApp(
        tester,
        const BlockedMessageSheet(
            text: 'abcdef', terms: [RestrictedTerm(2, 4), RestrictedTerm(1, 3)]),
      );

      expect(
          find.byWidgetPredicate((w) =>
              w is RichText && w.text.toPlainText(includeSemanticsLabels: false) == 'abcdef'),
          findsOneWidget);
    });
  });

  group('time', () {
    testWidgets('formats how long ago, and falls back to a date after a week', (tester) async {
      late BuildContext context;
      await pumpWidgetApp(tester, Builder(builder: (c) {
        context = c;
        return const SizedBox();
      }));
      final now = DateTime(2026, 11, 17, 12);

      expect(chatAgo(context, now.subtract(const Duration(seconds: 20)), now), 'Just now');
      expect(chatAgo(context, now.subtract(const Duration(minutes: 5)), now), '5m ago');
      expect(chatAgo(context, now.subtract(const Duration(hours: 3)), now), '3h ago');
      expect(chatAgo(context, now.subtract(const Duration(days: 2)), now), '2d ago');
      expect(chatAgo(context, now.subtract(const Duration(days: 9)), now), isNot(contains('ago')));
      expect(chatAgo(context, null, now), '');
      expect(chatClock(context, DateTime(2026, 11, 17, 9, 5)), contains('9:05'));
      expect(sameDay(now, DateTime(2026, 11, 17, 1)), isTrue);
      expect(sameDay(now, DateTime(2026, 11, 18, 12)), isFalse);
    });
  });

  group('error messages', () {
    final l10n = lookupAppLocalizations(const Locale('en'));

    test('chat sends map every documented code', () {
      expect(chatSendErrorMessage(l10n, _error('ERROR_MESSAGE_TOO_LONG')),
          'Message exceeds 2000 characters');
      expect(chatSendErrorMessage(l10n, _error('ERROR_EMPTY_MESSAGE')),
          'Write a message before sending');
      expect(chatSendErrorMessage(l10n, _error('RATE_LIMIT_EXCEEDED', status: 429)),
          "You're sending messages too fast. Slow down a little");
      expect(
          chatSendErrorMessage(l10n, _error('RATE_LIMIT_EXCEEDED', status: 429),
              afterOverride: true),
          "You've used all your overrides for today");
      expect(chatSendErrorMessage(l10n, _error('ERROR_BLOCKED', status: 403)),
          "You can't contact this seller");
      expect(chatSendErrorMessage(l10n, _error('ERROR_SELLER_UNAVAILABLE', status: 409)),
          'Seller is currently unavailable');
      expect(chatSendErrorMessage(l10n, _error('ERROR_THREAD_READ_ONLY', status: 409)),
          'This conversation is closed');
      expect(chatSendErrorMessage(l10n, _error('ERROR_IMAGE_TOO_LARGE')), 'Image exceeds 7 MB');
      expect(
          chatSendErrorMessage(
              l10n,
              const ApiError(
                  type: ApiErrorType.business,
                  message: 'Image is big',
                  code: 'ERROR_IMAGE_TOO_LARGE')),
          'Image exceeds 5 MB');
      expect(chatSendErrorMessage(l10n, _error('ERROR_IMAGE_INVALID')), "This image can't be sent");
      expect(chatSendErrorMessage(l10n, _error('ERROR_POLICY_AGREEMENT_OUTDATED', status: 409)),
          'The agreement text has changed. Update the app and try again');
      expect(chatSendErrorMessage(l10n, _error('SOMETHING_ELSE')), 'Unable to send. Try again');
      expect(chatSendErrorMessage(l10n, 'not an api error'), 'Unable to send. Try again');
      expect(chatSendErrorMessage(l10n, const ApiError(type: ApiErrorType.network, message: 'x')),
          l10n.errorUnableToConnect);
    });

    test('read-only reasons have their own words', () {
      for (final reason in ReadOnlyReason.values) {
        expect(readOnlyMessage(l10n, reason), isNotEmpty);
      }
    });

    test('contact errors map the story codes and the login text', () {
      expect(contactErrorMessage(l10n, _error('ERROR_BLOCKED', status: 403)),
          'You cannot contact this seller');
      expect(contactErrorMessage(l10n, _error('ERROR_SELLER_UNAVAILABLE', status: 409)),
          'Seller is currently unavailable');
      expect(contactErrorMessage(l10n, _error('WARNING_RATE_LIMIT', status: 429)),
          'Too many contact attempts. Try again later');
      expect(contactErrorMessage(l10n, _error('ERROR_LISTING_NOT_AVAILABLE', status: 404)),
          l10n.listingViewNotAvailable);
      expect(contactErrorMessage(l10n, _error('ERROR_OWN_LISTING', status: 409)),
          'This is your own listing');
      expect(contactErrorMessage(l10n, _error('ERROR_ACCOUNT_NOT_ACTIVE', status: 403)),
          'Complete your registration to contact sellers');
      expect(
          contactErrorMessage(
              l10n, const ApiError(type: ApiErrorType.unauthorized, message: 'x', statusCode: 401)),
          'Please login to contact seller');
      expect(contactErrorMessage(l10n, const ApiError.sessionExpired()),
          'Please login to contact seller');
      expect(contactErrorMessage(l10n, const ApiError(type: ApiErrorType.network, message: 'x')),
          l10n.errorUnableToConnect);
      expect(contactErrorMessage(l10n, 'odd'), l10n.errorSomethingWentWrong);
    });
  });
}
