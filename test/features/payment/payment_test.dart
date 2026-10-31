import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/config/app_config.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/payment/data/mock_payment_checkout.dart';
import 'package:valuex_mobile/features/payment/data/payment_repository.dart';
import 'package:valuex_mobile/features/payment/domain/payment_checkout.dart';
import 'package:valuex_mobile/features/payment/domain/payment_status.dart';
import 'package:valuex_mobile/features/payment/presentation/mock_checkout_sheet.dart';
import 'package:valuex_mobile/features/payment/presentation/payment_error_messages.dart';
import 'package:valuex_mobile/features/payment/presentation/payment_flow.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';
import 'package:valuex_mobile/l10n/app_localizations_en.dart';
import 'package:valuex_mobile/l10n/app_localizations_hi.dart';

import '../../helpers/app_harness.dart' show FakeScreenProtection, testConfig;
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_secure_storage.dart';
import '../../helpers/fonts.dart';

class _MockPaymentRepository extends Mock implements PaymentRepository {}

class _FakeCheckout implements PaymentCheckout {
  final CheckoutOutcome? outcome;
  final Object? error;
  int opened = 0;

  _FakeCheckout({this.outcome, this.error});

  @override
  Future<CheckoutOutcome> open(BuildContext context, CheckoutRequest request) async {
    opened++;
    if (error != null) throw error!;
    return outcome!;
  }
}

const _request = CheckoutRequest(
  paymentId: 'p1',
  orderId: 'order-1',
  amount: 49,
  currency: 'INR',
  publicKey: 'mock_public_key',
);

PaymentStatus _status(String status, {String? reason}) => PaymentStatus(
      paymentId: 'p1',
      status: status,
      amount: 49,
      currency: 'INR',
      failureReason: reason,
    );

Map<String, dynamic> _statusJson(String status) =>
    {'paymentId': 'p1', 'status': status, 'amount': 49.0, 'currency': 'INR', 'failureReason': null};

void main() {
  setUpAll(loadBrandFonts);

  group('models', () {
    test('CheckoutRequest reads the checkout details the server returns', () {
      final request = CheckoutRequest.fromJson({
        'paymentId': 'p1',
        'orderId': 'order-1',
        'amount': 49.5,
        'currency': 'INR',
        'publicKey': 'k',
        'expiresAt': '2026-10-30T10:00:00Z',
      });

      expect(request.paymentId, 'p1');
      expect(request.orderId, 'order-1');
      expect(request.amount, 49.5);
      expect(request.publicKey, 'k');
    });

    test('CheckoutRequest defaults the currency and key when the server omits them', () {
      final request = CheckoutRequest.fromJson({'paymentId': 'p1', 'orderId': 'o', 'amount': 10});

      expect(request.currency, 'INR');
      expect(request.publicKey, '');
    });

    test('PaymentStatus tells open, failed and paid states apart', () {
      expect(_status('PAYMENT_INITIATED').isOpen, isTrue);
      expect(_status('PAYMENT_PENDING').isOpen, isTrue);
      expect(_status('PAYMENT_FAILED').isFailed, isTrue);
      expect(_status('PAYMENT_FAILED').isPaid, isFalse);
      expect(_status('PAYMENT_SUCCESS').isPaid, isTrue);
      expect(_status('ESCROW_HELD').isPaid, isTrue);
      expect(_status('PAYMENT_PENDING').isPaid, isFalse);
    });

    test('PaymentStatus parses the server answer', () {
      final status =
          PaymentStatus.fromJson({..._statusJson('PAYMENT_FAILED'), 'failureReason': 'EXPIRED'});

      expect(status.paymentId, 'p1');
      expect(status.amount, 49.0);
      expect(status.failureReason, 'EXPIRED');
    });
  });

  group('app config', () {
    AppConfig parse(String env, [String? provider]) => AppConfig.parse(
          env: env,
          apiBaseUrl:
              env == 'dev' ? 'http://localhost/api/v1' : 'https://api.valuex.example/api/v1',
          aadhaarFlow: env == 'prod' ? 'thirdparty' : 'sandbox',
          googleSignIn: env == 'prod' ? 'native' : 'mock',
          googleServerClientId: env == 'prod' ? 'client' : '',
          addressSearch: env == 'prod' ? 'google' : 'mock',
          googlePlacesApiKey: env == 'prod' ? 'key' : '',
          paymentProvider: provider ?? 'none',
        );

    test('has no payment checkout unless it is configured', () {
      expect(parse('dev').paymentMode, PaymentMode.none);
      expect(parse('dev').useMockPayment, isFalse);
    });

    test('allows the dummy checkout in dev only', () {
      expect(parse('dev', 'mock').useMockPayment, isTrue);
      expect(() => parse('staging', 'mock'), throwsA(isA<AppConfigException>()));
      expect(() => parse('prod', 'mock'), throwsA(isA<AppConfigException>()));
    });

    test('rejects an unknown payment provider', () {
      expect(() => parse('dev', 'razorpay'), throwsA(isA<AppConfigException>()));
    });
  });

  group('repository', () {
    late FakeHttpAdapter api;
    late PaymentRepository repository;

    void use(FakeHandler handler) {
      api = FakeHttpAdapter(handler);
      repository = PaymentRepository(
        ApiClient(FakeSecureStorage(accessToken: 'a', refreshToken: 'r'), testConfig, adapter: api),
      );
    }

    test('reads the status of a payment', () async {
      use((_) async => FakeHttpAdapter.ok(_statusJson('PAYMENT_SUCCESS')));

      final status = await repository.getStatus('p1');

      expect(api.requests.single.method, 'GET');
      expect(api.requests.single.path, '/payments/p1');
      expect(status.isPaid, isTrue);
    });

    test('reports a checkout result with and without a gateway payment id', () async {
      use((_) async => FakeHttpAdapter.ok(_statusJson('PAYMENT_PENDING')));

      await repository.reportCheckoutResult('p1', result: 'COMPLETED', gatewayPaymentId: 'pay_1');
      await repository.reportCheckoutResult('p1', result: 'CANCELLED');

      expect(api.requests.first.path, '/payments/p1/checkout-result');
      expect(api.requests.first.method, 'POST');
      expect(api.requests.first.data, {'result': 'COMPLETED', 'gatewayPaymentId': 'pay_1'});
      expect(api.requests.last.data, {'result': 'CANCELLED'});
    });

    test('asks the dummy gateway to finish a payment as paid or failed', () async {
      use((_) async => FakeHttpAdapter.ok(_statusJson('PAYMENT_SUCCESS')));

      await repository.simulate('p1', success: true);
      await repository.simulate('p1', success: false);

      expect(api.requests.first.path, '/dev/payments/p1/simulate');
      expect(api.requests.first.data, {'outcome': 'SUCCESS'});
      expect(api.requests.last.data, {'outcome': 'FAILURE'});
    });

    test('surfaces the gateway-unavailable error code', () async {
      use((_) async => FakeHttpAdapter.error(503, 'ERROR_GATEWAY_UNAVAILABLE', 'down'));

      await expectLater(
        repository.getStatus('p1'),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'ERROR_GATEWAY_UNAVAILABLE')),
      );
    });
  });

  group('payment flow', () {
    late _MockPaymentRepository repository;
    late FakeScreenProtection protection;

    setUp(() {
      repository = _MockPaymentRepository();
      protection = FakeScreenProtection();
    });

    Future<BuildContext> pumpContext(WidgetTester tester) async {
      late BuildContext context;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (c) {
          context = c;
          return const SizedBox();
        }),
      ));
      return context;
    }

    Future<PaymentResult> run(
      WidgetTester tester,
      PaymentCheckout checkout, {
      Duration pollInterval = const Duration(milliseconds: 10),
      Duration timeout = const Duration(milliseconds: 50),
    }) async {
      final context = await pumpContext(tester);
      final flow = PaymentFlow(checkout, repository, protection,
          pollInterval: pollInterval, timeout: timeout);
      return tester.runAsync(() => flow.start(context, _request)).then((r) => r!);
    }

    void stubReport(PaymentStatus? status, {String result = 'COMPLETED'}) {
      when(() => repository.reportCheckoutResult('p1',
          result: result, gatewayPaymentId: any(named: 'gatewayPaymentId'))).thenAnswer((_) async {
        if (status == null) {
          throw const ApiError(type: ApiErrorType.network, message: 'No connection');
        }
        return status;
      });
    }

    testWidgets('confirms the payment when the server says it is paid, and protects the screen',
        (tester) async {
      stubReport(_status('PAYMENT_SUCCESS'));
      final checkout = _FakeCheckout(outcome: const CheckoutCompleted(gatewayPaymentId: 'pay_1'));

      final result = await run(tester, checkout);

      expect(result, PaymentResult.confirmed);
      expect(protection.enabled, 1);
      expect(protection.disabled, 1);
      verify(() =>
              repository.reportCheckoutResult('p1', result: 'COMPLETED', gatewayPaymentId: 'pay_1'))
          .called(1);
    });

    testWidgets('keeps checking until the server settles the payment', (tester) async {
      stubReport(_status('PAYMENT_PENDING'));
      var reads = 0;
      when(() => repository.getStatus('p1')).thenAnswer((_) async {
        reads++;
        return _status(reads < 3 ? 'PAYMENT_PENDING' : 'PAYMENT_SUCCESS');
      });

      final result = await run(tester, _FakeCheckout(outcome: const CheckoutCompleted()));

      expect(result, PaymentResult.confirmed);
      expect(reads, 3);
    });

    testWidgets(
        'never trusts the checkout: still pending after the timeout is pending, not confirmed',
        (tester) async {
      stubReport(_status('PAYMENT_PENDING'));
      when(() => repository.getStatus('p1')).thenAnswer((_) async => _status('PAYMENT_PENDING'));

      final result = await run(tester, _FakeCheckout(outcome: const CheckoutCompleted()));

      expect(result, PaymentResult.pending);
      expect(protection.isActive, isFalse);
    });

    testWidgets('is pending when the server cannot be reached at all', (tester) async {
      stubReport(null);
      when(() => repository.getStatus('p1'))
          .thenThrow(const ApiError(type: ApiErrorType.network, message: 'No connection'));

      final result = await run(tester, _FakeCheckout(outcome: const CheckoutCompleted()));

      expect(result, PaymentResult.pending);
    });

    testWidgets('fails when the server says the payment failed', (tester) async {
      stubReport(_status('PAYMENT_FAILED'), result: 'FAILED');

      final result = await run(tester, _FakeCheckout(outcome: const CheckoutFailed('DECLINED')));

      expect(result, PaymentResult.failed);
    });

    testWidgets('reports a cancelled checkout and returns cancelled', (tester) async {
      stubReport(_status('PAYMENT_PENDING'), result: 'CANCELLED');

      final result = await run(tester, _FakeCheckout(outcome: const CheckoutCancelled()));

      expect(result, PaymentResult.cancelled);
      verify(() => repository.reportCheckoutResult('p1',
          result: 'CANCELLED', gatewayPaymentId: any(named: 'gatewayPaymentId'))).called(1);
      verifyNever(() => repository.getStatus(any()));
    });

    testWidgets('still returns cancelled when reporting the cancel fails', (tester) async {
      stubReport(null, result: 'CANCELLED');

      final result = await run(tester, _FakeCheckout(outcome: const CheckoutCancelled()));

      expect(result, PaymentResult.cancelled);
    });

    testWidgets('releases the screen protection when the checkout cannot open', (tester) async {
      const error = ApiError(
        type: ApiErrorType.server,
        message: 'down',
        code: 'ERROR_GATEWAY_UNAVAILABLE',
      );

      final context = await pumpContext(tester);
      final flow = PaymentFlow(_FakeCheckout(error: error), repository, protection);

      final thrown = await tester.runAsync(() async {
        try {
          await flow.start(context, _request);
        } on ApiError catch (e) {
          return e;
        }
        return null;
      });

      expect(thrown?.code, 'ERROR_GATEWAY_UNAVAILABLE');
      expect(protection.enabled, 1);
      expect(protection.disabled, 1);
    });

    testWidgets('does not open the checkout when the screen has gone away', (tester) async {
      final context = await pumpContext(tester);
      await tester.pumpWidget(const SizedBox());
      final checkout = _FakeCheckout(outcome: const CheckoutCompleted());
      final flow = PaymentFlow(checkout, repository, protection);

      final result = await tester.runAsync(() => flow.start(context, _request));

      expect(result, PaymentResult.cancelled);
      expect(checkout.opened, 0);
      expect(protection.enabled, 1);
      expect(protection.disabled, 1);
    });
  });

  group('checkout provider', () {
    ProviderContainer containerFor(AppConfig config) {
      final container = ProviderContainer(overrides: [
        appConfigProvider.overrideWithValue(config),
        paymentRepositoryProvider.overrideWithValue(_MockPaymentRepository()),
      ]);
      addTearDown(container.dispose);
      return container;
    }

    test('is the dummy checkout only when the app is configured for it', () {
      final mock = AppConfig.parse(
        env: 'dev',
        apiBaseUrl: 'http://localhost/api/v1',
        aadhaarFlow: 'sandbox',
        paymentProvider: 'mock',
      );

      expect(containerFor(mock).read(paymentCheckoutProvider), isA<MockPaymentCheckout>());
      expect(containerFor(testConfig).read(paymentCheckoutProvider),
          isA<UnavailablePaymentCheckout>());
    });

    test('the unavailable checkout fails with the gateway-unavailable code', () {
      expect(
        () => const UnavailablePaymentCheckout().open(_NoContext(), _request),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'ERROR_GATEWAY_UNAVAILABLE')),
      );
    });

    test('builds the payment flow from the providers', () {
      final container = containerFor(testConfig);

      expect(container.read(paymentFlowProvider), isA<PaymentFlow>());
    });
  });

  group('mock checkout', () {
    late _MockPaymentRepository repository;

    setUp(() {
      repository = _MockPaymentRepository();
      when(() => repository.simulate('p1', success: any(named: 'success')))
          .thenAnswer((_) async => _status('PAYMENT_SUCCESS'));
    });

    Future<CheckoutOutcome?> pick(WidgetTester tester, Key? button) async {
      CheckoutOutcome? outcome;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  outcome = await MockPaymentCheckout(repository).open(context, _request),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      if (button == null) {
        await tester.tapAt(const Offset(5, 5));
      } else {
        await tester.tap(find.byKey(button));
      }
      await tester.pumpAndSettle();
      return outcome;
    }

    testWidgets('Pay completes the payment through the simulate endpoint', (tester) async {
      final outcome = await pick(tester, const Key('mockCheckoutPay'));

      expect(outcome, isA<CheckoutCompleted>());
      verify(() => repository.simulate('p1', success: true)).called(1);
    });

    testWidgets('Fail fails the payment through the simulate endpoint', (tester) async {
      final outcome = await pick(tester, const Key('mockCheckoutFail'));

      expect(outcome, isA<CheckoutFailed>());
      expect((outcome! as CheckoutFailed).reason, MockPaymentCheckout.declinedReason);
      verify(() => repository.simulate('p1', success: false)).called(1);
    });

    testWidgets('Cancel and dismissing the sheet both cancel without calling the server',
        (tester) async {
      expect(await pick(tester, const Key('mockCheckoutCancel')), isA<CheckoutCancelled>());
      expect(await pick(tester, null), isA<CheckoutCancelled>());
      verifyNever(() => repository.simulate(any(), success: any(named: 'success')));
    });
  });

  group('MockCheckoutSheet', () {
    Future<void> show(WidgetTester tester,
        {Locale locale = const Locale('en'), double textScale = 1}) async {
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: MockCheckoutSheet(amount: 49, currency: 'INR')),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the test title, the note, the amount and three actions in English',
        (tester) async {
      await show(tester);

      expect(find.text('Test payment'), findsOneWidget);
      expect(find.text('This is a test checkout. No money is charged.'), findsOneWidget);
      expect(find.text('Amount: ₹49.00'), findsOneWidget);
      expect(find.text('Pay'), findsOneWidget);
      expect(find.text('Fail'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('shows Hindi text to a Hindi reader', (tester) async {
      await show(tester, locale: const Locale('hi'));

      expect(find.text('टेस्ट भुगतान'), findsOneWidget);
      expect(find.text('भुगतान करें'), findsOneWidget);
      expect(find.text('रद्द करें'), findsOneWidget);
    });

    testWidgets('shows another currency with its code', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: MockCheckoutSheet(amount: 5, currency: 'USD')),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Amount: USD 5.00'), findsOneWidget);
    });

    testWidgets('meets the tap target and label guidelines and marks its title as a header',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await show(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      expect(tester.getSemantics(find.text('Test payment')), isSemantics(isHeader: true));
      semantics.dispose();
    });

    testWidgets('lays out without overflow at 2x text size', (tester) async {
      await show(tester, textScale: 2);

      expect(tester.takeException(), isNull);
    });
  });

  group('error messages', () {
    final en = AppLocalizationsEn();
    final hi = AppLocalizationsHi();

    test('maps the payment error codes in English and Hindi', () {
      expect(
          paymentCodeMessage(en, 'ERROR_GATEWAY_UNAVAILABLE'), en.paymentErrorGatewayUnavailable);
      expect(paymentCodeMessage(en, 'ERROR_PAYMENT_FAILED'), en.paymentErrorFailed);
      expect(paymentCodeMessage(en, 'ERROR_PAYMENT_TIMEOUT'), en.paymentErrorTimeout);
      expect(
          paymentCodeMessage(hi, 'ERROR_GATEWAY_UNAVAILABLE'), hi.paymentErrorGatewayUnavailable);
      expect(paymentCodeMessage(en, 'SOMETHING_ELSE'), isNull);
      expect(paymentCodeMessage(en, null), isNull);
    });

    test('falls back to the general message for other errors', () {
      const gateway =
          ApiError(type: ApiErrorType.server, message: 'x', code: 'ERROR_GATEWAY_UNAVAILABLE');
      const offline = ApiError(type: ApiErrorType.network, message: 'x');
      const unknown = ApiError(type: ApiErrorType.business, message: 'x', code: 'OTHER');

      expect(paymentErrorMessage(en, gateway), en.paymentErrorGatewayUnavailable);
      expect(paymentErrorMessage(en, offline), en.errorUnableToConnect);
      expect(paymentErrorMessage(en, unknown), en.errorSomethingWentWrong);
      expect(paymentErrorMessage(en, Exception('boom')), en.errorSomethingWentWrong);
    });
  });
}

class _NoContext extends Fake implements BuildContext {}
