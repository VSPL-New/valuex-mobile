import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/negotiation/data/negotiation_repository.dart';
import 'package:valuex_mobile/features/negotiation/domain/negotiation.dart';
import 'package:valuex_mobile/features/negotiation/presentation/counter_sheet.dart';
import 'package:valuex_mobile/features/negotiation/presentation/offer_sheet.dart';

import '../../helpers/fonts.dart';
import 'negotiation_fixtures.dart';

class _Launcher extends StatelessWidget {
  final void Function(String?) onResult;
  final VoidCallback? onChat;

  const _Launcher({required this.onResult, this.onChat});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async => onResult(await showOfferSheet(
              context,
              listingId: 'l1',
              askingPrice: 14500,
              onChat: onChat,
            )),
            child: const Text('open'),
          ),
        ),
      );
}

ApiError _error(String code, {Map<String, String> details = const {}}) => ApiError(
      type: ApiErrorType.business,
      message: 'x',
      code: code,
      statusCode: 409,
      details: details,
    );

void main() {
  late MockNegotiationRepository repo;
  String? result;
  var resulted = false;

  setUpAll(loadBrandFonts);

  setUp(() {
    repo = MockNegotiationRepository();
    result = null;
    resulted = false;
  });

  Future<void> open(WidgetTester tester,
      {VoidCallback? onChat, Locale locale = const Locale('en')}) async {
    await pumpNegotiationApp(
      tester,
      _Launcher(
          onResult: (value) {
            result = value;
            resulted = true;
          },
          onChat: onChat),
      repo: repo,
      locale: locale,
    );
    await tester.tap(find.text(locale.languageCode == 'hi' ? 'open' : 'open'));
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
  }

  void whenOfferSucceeds() {
    when(() => repo.makeOffer('l1',
            amount: any(named: 'amount'),
            clientRequestId: any(named: 'clientRequestId'),
            confirmLowOffer: any(named: 'confirmLowOffer')))
        .thenAnswer((_) async => MadeOffer(negotiation: negotiation(id: 'n7'), created: true));
  }

  testWidgets('shows the asking price, the allowed range and a Send button', (tester) async {
    await open(tester);

    expect(find.text('Make an offer'), findsOneWidget);
    expect(find.text('Asking price: ₹14,500'), findsOneWidget);
    expect(find.text('You can offer up to ₹14,500'), findsOneWidget);
    expect(find.text('Send offer'), findsOneWidget);
    expect(find.text('Chat with seller'), findsNothing);
  });

  testWidgets('refuses an empty amount, a bad amount and one above the asking price',
      (tester) async {
    await open(tester);

    await tester.tap(find.text('Send offer'));
    await tester.pump();
    expect(find.text('Enter your offer'), findsOneWidget);

    await type(tester, '12.');
    expect(find.text('Enter a valid amount, for example 850 or 850.50'), findsOneWidget);

    await type(tester, '14500.01');
    expect(find.text('Offer must be between ₹1 and ₹14,500'), findsOneWidget);
    await tester.tap(find.text('Send offer'));
    await tester.pump();
    verifyNever(() => repo.makeOffer(any(),
        amount: any(named: 'amount'), clientRequestId: any(named: 'clientRequestId')));
  });

  testWidgets('sends the amount as text and closes with the negotiation id', (tester) async {
    whenOfferSucceeds();
    await open(tester);

    await type(tester, '12000.5');
    await tester.tap(find.text('Send offer'));
    await tester.pumpAndSettle();

    expect(resulted, isTrue);
    expect(result, 'n7');
    final captured = verify(() => repo.makeOffer('l1',
        amount: captureAny(named: 'amount'),
        clientRequestId: any(named: 'clientRequestId'),
        confirmLowOffer: false)).captured;
    expect(captured.single, '12000.50');
  });

  testWidgets('asks before sending a very low offer and sends it again once confirmed',
      (tester) async {
    var calls = 0;
    when(() => repo.makeOffer('l1',
        amount: any(named: 'amount'),
        clientRequestId: any(named: 'clientRequestId'),
        confirmLowOffer: any(named: 'confirmLowOffer'))).thenAnswer((invocation) async {
      calls++;
      if (invocation.namedArguments[#confirmLowOffer] != true) throw _error('WARNING_LOW_OFFER');
      return MadeOffer(negotiation: negotiation(id: 'n7'), created: true);
    });
    await open(tester);

    await type(tester, '1000');
    await tester.tap(find.text('Send offer'));
    await tester.pumpAndSettle();
    expect(find.text('Much lower than the asking price'), findsOneWidget);
    expect(find.textContaining('significantly lower'), findsOneWidget);

    await tester.tap(find.text('Send anyway'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(result, 'n7');
  });

  testWidgets('keeps the amount when the buyer chooses to change a low offer', (tester) async {
    when(() => repo.makeOffer('l1',
        amount: any(named: 'amount'),
        clientRequestId: any(named: 'clientRequestId'),
        confirmLowOffer: any(named: 'confirmLowOffer'))).thenThrow(_error('WARNING_LOW_OFFER'));
    await open(tester);

    await type(tester, '1000');
    await tester.tap(find.text('Send offer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change offer'));
    await tester.pumpAndSettle();

    expect(resulted, isFalse);
    expect(find.text('1000'), findsOneWidget);
  });

  testWidgets('opens the negotiation the buyer already has', (tester) async {
    when(() => repo.makeOffer('l1',
            amount: any(named: 'amount'),
            clientRequestId: any(named: 'clientRequestId'),
            confirmLowOffer: any(named: 'confirmLowOffer')))
        .thenThrow(_error('ERROR_NEGOTIATION_EXISTS', details: {'negotiationId': 'n3'}));
    await open(tester);

    await type(tester, '12000');
    await tester.tap(find.text('Send offer'));
    await tester.pumpAndSettle();

    expect(result, 'n3');
  });

  testWidgets('shows the server refusal in words and stays open', (tester) async {
    when(() => repo.makeOffer('l1',
        amount: any(named: 'amount'),
        clientRequestId: any(named: 'clientRequestId'),
        confirmLowOffer: any(named: 'confirmLowOffer'))).thenThrow(_error('ERROR_ITEM_RESERVED'));
    await open(tester);

    await type(tester, '12000');
    await tester.tap(find.text('Send offer'));
    await tester.pumpAndSettle();

    expect(find.text('This item is reserved for another buyer right now'), findsOneWidget);
    expect(resulted, isFalse);
  });

  testWidgets('a refusal without its own code falls back to the contact text', (tester) async {
    when(() => repo.makeOffer('l1',
        amount: any(named: 'amount'),
        clientRequestId: any(named: 'clientRequestId'),
        confirmLowOffer: any(named: 'confirmLowOffer'))).thenThrow(_error('ERROR_BLOCKED'));
    await open(tester);

    await type(tester, '12000');
    await tester.tap(find.text('Send offer'));
    await tester.pumpAndSettle();

    expect(find.textContaining('cannot contact'), findsOneWidget);
  });

  testWidgets('offers a link to chat with the seller first', (tester) async {
    var chatTapped = false;
    await open(tester, onChat: () => chatTapped = true);

    await tester.tap(find.text('Chat with seller'));
    await tester.pump();

    expect(chatTapped, isTrue);
  });

  testWidgets('works in Hindi at large text on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640) * 2;
    await open(tester, locale: const Locale('hi'));

    expect(find.text('ऑफ़र दें'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  group('counter sheet', () {
    const range = CounterRange(min: 12000.01, max: 14500);

    Future<void> openCounter(WidgetTester tester) async {
      await pumpNegotiationApp(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  final amount = await showCounterSheet(context, range: range);
                  result = amount;
                  resulted = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
        repo: repo,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the corridor and refuses an amount outside it', (tester) async {
      await openCounter(tester);

      expect(find.text('Counter offer'), findsWidgets);
      expect(find.text('Enter between ₹12,000.01 and ₹14,500'), findsOneWidget);

      await type(tester, '12000');
      expect(find.text('Counter offer must be between ₹12,000.01 and ₹14,500'), findsOneWidget);
      await tester.tap(find.text('Send counter offer'));
      await tester.pump();
      expect(resulted, isFalse);

      await tester.tap(find.byType(TextField));
      await type(tester, '');
      await tester.tap(find.text('Send counter offer'));
      await tester.pump();
      expect(find.text('Enter your offer'), findsOneWidget);

      await type(tester, '12.');
      expect(find.text('Enter a valid amount, for example 850 or 850.50'), findsOneWidget);
    });

    testWidgets('closes with the amount as text when it is inside the corridor', (tester) async {
      await openCounter(tester);

      await type(tester, '13000.5');
      await tester.tap(find.text('Send counter offer'));
      await tester.pumpAndSettle();

      expect(result, '13000.50');
    });

    testWidgets('moves the amount field when the slider is dragged inside the corridor',
        (tester) async {
      await openCounter(tester);
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      await tester.drag(slider, const Offset(400, 0));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '14500');
      await tester.tap(find.text('Send counter offer'));
      await tester.pumpAndSettle();
      expect(result, '14500');
    });

    testWidgets('keeps the slider at the corridor ends and in step with a typed amount',
        (tester) async {
      await openCounter(tester);
      double value() => tester.widget<Slider>(find.byType(Slider)).value;

      expect(value(), 12001);
      await type(tester, '13000');
      expect(value(), 13000);
      await type(tester, '12000.01');
      expect(value(), 12001);
      await type(tester, '14500');
      expect(value(), 14500);
      await type(tester, '99999');
      expect(value(), 14500);
    });

    testWidgets('speaks the slider in rupees', (tester) async {
      await openCounter(tester);

      expect(find.bySemanticsLabel('Counter amount'), findsWidgets);
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.semanticFormatterCallback!(13000.4), '₹13,000');
    });

    testWidgets('has no slider when the corridor holds a single rupee', (tester) async {
      await pumpNegotiationApp(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showCounterSheet(
                context,
                range: const CounterRange(min: 900.01, max: 900.99),
              ),
              child: const Text('open'),
            ),
          ),
        ),
        repo: repo,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('accepts both ends of the corridor', (tester) async {
      await openCounter(tester);

      await type(tester, '14500');
      await tester.tap(find.text('Send counter offer'));
      await tester.pumpAndSettle();

      expect(result, '14500');
    });
  });
}
