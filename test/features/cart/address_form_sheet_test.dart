import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/config/app_config.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/theme/app_theme.dart';
import 'package:valuex_mobile/core/widgets/brand_gradient_button.dart';

import 'package:valuex_mobile/features/address/data/address_repository.dart';
import 'package:valuex_mobile/features/address/domain/address_value.dart';
import 'package:valuex_mobile/features/address/domain/saved_address.dart';
import 'package:valuex_mobile/features/address/presentation/providers/address_providers.dart';
import 'package:valuex_mobile/features/address/presentation/widgets/address_form_sheet.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../helpers/fonts.dart';
import 'cart_fixtures.dart';

final _config = AppConfig.parse(
  env: 'dev',
  apiBaseUrl: 'http://localhost:8080/api/v1',
  aadhaarFlow: 'sandbox',
);

const _line = '4 Residency Road, Shanti Nagar';

const _saved = SavedAddress(
  id: 'a3',
  label: 'Office',
  address: _line,
  city: 'Bengaluru',
  state: 'Karnataka',
  pincode: '560025',
);

ApiError _error(String code, {int status = 400}) =>
    ApiError(type: ApiErrorType.business, message: code, code: code, statusCode: status);

void main() {
  setUpAll(() async {
    await loadBrandFonts();
    registerFallbackValue(
        const AddressValue(address: 'a', city: 'c', state: 's', pincode: '560001'));
  });

  late MockAddressRepository repository;
  SavedAddress? result;
  var closed = false;

  setUp(() {
    repository = MockAddressRepository();
    result = null;
    closed = false;
    when(() => repository.verify(any())).thenAnswer((_) async {});
    when(() => repository.create(
          any(),
          label: any(named: 'label'),
          makeDefault: any(named: 'makeDefault'),
        )).thenAnswer((_) async => _saved);
  });

  Future<void> open(
    WidgetTester tester, {
    bool hasSavedAddresses = false,
    double textScale = 1,
    Size size = const Size(390, 1600),
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(_config),
        addressRepositoryProvider.overrideWithValue(repository),
        addressSearchServiceProvider.overrideWithValue(FakeAddressSearch()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showAddressFormSheet(context, hasSavedAddresses: hasSavedAddresses);
                closed = true;
              },
              child: const Text('open form'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open form'));
    await tester.pumpAndSettle();
  }

  Future<void> fillByHand(WidgetTester tester) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), _line);
    await tester.enterText(fields.at(3), 'Bengaluru');
    await tester.enterText(fields.at(4), '560025');
    await tester.tap(find.text('Select your state'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Karnataka'));
    await tester.pumpAndSettle();
  }

  bool saveEnabled(WidgetTester tester) =>
      tester.widget<BrandGradientButton>(find.byType(BrandGradientButton)).onPressed != null;

  Finder saveButton() => find.text('Save address');

  testWidgets('shows the fields and says the first address becomes the default', (tester) async {
    await open(tester);

    expect(find.text('New address'), findsOneWidget);
    expect(find.text('Street and area'), findsOneWidget);
    expect(find.text('City'), findsOneWidget);
    expect(find.text('Pincode'), findsOneWidget);
    expect(find.text('Name this address'), findsOneWidget);
    expect(find.text('Your first address is saved as your default'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
  });

  testWidgets('offers the default switch when the buyer already has an address', (tester) async {
    await open(tester, hasSavedAddresses: true);

    expect(find.text('Make this my default address'), findsOneWidget);
    expect(find.text('Your first address is saved as your default'), findsNothing);
  });

  testWidgets('saves a typed address with a name and returns it', (tester) async {
    await open(tester);
    await fillByHand(tester);
    await tester.tap(find.text('Office'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 900));

    await tester.ensureVisible(saveButton());
    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    verify(() => repository.create(
          const AddressValue(
              address: _line, city: 'Bengaluru', state: 'Karnataka', pincode: '560025'),
          label: 'Office',
          makeDefault: false,
        )).called(1);
    expect(closed, isTrue);
    expect(result?.id, 'a3');
  });

  testWidgets('sends the default switch only when the buyer has other addresses', (tester) async {
    await open(tester, hasSavedAddresses: true);
    await fillByHand(tester);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 900));

    await tester.ensureVisible(saveButton());
    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    verify(() => repository.create(
          any(),
          label: null,
          makeDefault: true,
        )).called(1);
  });

  testWidgets('a custom name is sent as typed', (tester) async {
    await open(tester);
    await fillByHand(tester);
    await tester.tap(find.text('Other'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, "Mum's flat");
    await tester.pump(const Duration(milliseconds: 900));

    await tester.ensureVisible(saveButton());
    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    verify(() => repository.create(any(), label: "Mum's flat", makeDefault: false)).called(1);
  });

  testWidgets('Save stays off until the address is complete', (tester) async {
    await open(tester);
    expect(saveEnabled(tester), isFalse);

    await tester.enterText(find.byType(TextField).at(1), 'too short');
    await tester.pump();
    expect(saveEnabled(tester), isFalse);

    await fillByHand(tester);
    expect(saveEnabled(tester), isTrue);

    await tester.enterText(find.byType(TextField).at(4), '0123');
    await tester.pump();
    expect(saveEnabled(tester), isFalse);
  });

  testWidgets('checks the address while the buyer types and says so', (tester) async {
    await open(tester);

    await fillByHand(tester);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.text('Address verified'), findsOneWidget);
    verify(() => repository.verify(any())).called(1);
  });

  testWidgets('an address the server refuses shows why and stays open', (tester) async {
    when(() => repository.create(
          any(),
          label: any(named: 'label'),
          makeDefault: any(named: 'makeDefault'),
        )).thenAnswer((_) async => throw _error('ERROR_PINCODE_MISMATCH'));
    await open(tester);
    await fillByHand(tester);
    await tester.pump(const Duration(milliseconds: 900));

    await tester.ensureVisible(saveButton());
    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    expect(find.text('The pincode does not match the selected city or state'), findsOneWidget);
    expect(closed, isFalse);
  });

  testWidgets('a failure that is not a refusal says to try again and stays open', (tester) async {
    when(() => repository.create(
              any(),
              label: any(named: 'label'),
              makeDefault: any(named: 'makeDefault'),
            ))
        .thenAnswer(
            (_) async => throw const ApiError(type: ApiErrorType.network, message: 'offline'));
    await open(tester);
    await fillByHand(tester);
    await tester.pump(const Duration(milliseconds: 900));

    await tester.ensureVisible(saveButton());
    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    expect(find.text("We couldn't save the address. Please try again"), findsOneWidget);
    expect(closed, isFalse);
    expect(saveEnabled(tester), isTrue);
  });

  testWidgets('does not overflow at 320 px and 200 percent text', (tester) async {
    await open(tester, textScale: 2, size: const Size(320, 1800));

    expect(tester.takeException(), isNull);
  });
}
