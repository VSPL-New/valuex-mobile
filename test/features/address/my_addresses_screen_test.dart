import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/config/app_config.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/theme/app_theme.dart';
import 'package:valuex_mobile/features/address/data/address_repository.dart';
import 'package:valuex_mobile/features/address/domain/address_value.dart';
import 'package:valuex_mobile/features/address/domain/saved_address.dart';
import 'package:valuex_mobile/features/address/presentation/my_addresses_screen.dart';
import 'package:valuex_mobile/features/address/presentation/providers/address_providers.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';
import 'package:valuex_mobile/l10n/app_localizations_en.dart';

import '../../helpers/fonts.dart';
import '../cart/cart_fixtures.dart';

final _config = AppConfig.parse(
  env: 'dev',
  apiBaseUrl: 'http://localhost:8080/api/v1',
  aadhaarFlow: 'sandbox',
);

const _verified = SavedAddress(
  id: 'a1',
  label: 'Home',
  address: '12 MG Road, Indiranagar',
  landmark: 'Flat 4',
  city: 'Bengaluru',
  state: 'Karnataka',
  pincode: '560038',
  isDefault: true,
  verified: true,
);

const _office = SavedAddress(
  id: 'a2',
  label: 'Office',
  address: '9 Baner Road',
  city: 'Pune',
  state: 'Maharashtra',
  pincode: '411045',
);

const _unnamed = SavedAddress(
  id: 'a3',
  address: '4 Residency Road, Shanti Nagar',
  city: 'Bengaluru',
  state: 'Karnataka',
  pincode: '560025',
);

ApiError _error(String code, {int status = 409}) =>
    ApiError(type: ApiErrorType.business, message: code, code: code, statusCode: status);

void main() {
  setUpAll(() async {
    await loadBrandFonts();
    registerFallbackValue(
      const AddressValue(address: 'a', city: 'c', state: 's', pincode: '560001'),
    );
  });

  late MockAddressRepository repository;

  setUp(() {
    repository = MockAddressRepository();
    when(() => repository.savedAddresses()).thenAnswer((_) async => [_verified, _office]);
    when(() => repository.setDefault(any())).thenAnswer((_) async => _office);
    when(() => repository.delete(any())).thenAnswer((_) async {});
    when(() => repository.verify(any())).thenAnswer((_) async => false);
    when(() => repository.update(any(), any(), label: any(named: 'label')))
        .thenAnswer((_) async => _office);
    when(() => repository.create(any(),
        label: any(named: 'label'),
        makeDefault: any(named: 'makeDefault'))).thenAnswer((_) async => _office);
  });

  Future<void> open(WidgetTester tester, {double textScale = 1}) async {
    tester.view.physicalSize = const Size(390, 1600) * 2;
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
        home: const MyAddressesScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> menu(WidgetTester tester, String name, String item) async {
    await tester.tap(find.byTooltip('Options for $name'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
  }

  group('the list', () {
    testWidgets('shows each address with its name and full address, the default first',
        (tester) async {
      await open(tester);

      expect(find.text('My Addresses'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Office'), findsOneWidget);
      expect(find.text('Flat 4, 12 MG Road, Indiranagar, Bengaluru, Karnataka 560038'),
          findsOneWidget);
      expect(find.text('9 Baner Road, Pune, Maharashtra 411045'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Home')).dy,
          lessThan(tester.getTopLeft(find.text('Office')).dy));
    });

    testWidgets('marks the default, and Verified only for an address a provider confirmed',
        (tester) async {
      await open(tester);

      expect(find.text('Default'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
    });

    testWidgets('calls an address with no name "Address"', (tester) async {
      when(() => repository.savedAddresses()).thenAnswer((_) async => [_unnamed]);
      await open(tester);

      expect(find.text('Address'), findsOneWidget);
    });

    testWidgets('shows an empty state with a way to add the first address', (tester) async {
      when(() => repository.savedAddresses()).thenAnswer((_) async => const []);
      await open(tester);

      expect(find.text('You have no saved addresses'), findsOneWidget);
      await tester.tap(find.text('Add address'));
      await tester.pumpAndSettle();
      expect(find.text('New address'), findsOneWidget);
    });

    testWidgets('shows an error with Retry, and loads again on Retry', (tester) async {
      when(() => repository.savedAddresses()).thenThrow(_error('ERROR_X', status: 500));
      await open(tester);
      expect(find.text("We couldn't load your addresses"), findsOneWidget);

      when(() => repository.savedAddresses()).thenAnswer((_) async => [_verified]);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('lays out at a large text size', (tester) async {
      await open(tester, textScale: 2);

      expect(tester.takeException(), isNull);
      expect(find.text('Home'), findsOneWidget);
    });
  });

  group('set as default', () {
    testWidgets('is offered only for an address that is not the default', (tester) async {
      await open(tester);

      await tester.tap(find.byTooltip('Options for Home'));
      await tester.pumpAndSettle();
      expect(find.text('Set as default'), findsNothing);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Options for Office'));
      await tester.pumpAndSettle();
      expect(find.text('Set as default'), findsOneWidget);
    });

    testWidgets('changes the default and reads the list again', (tester) async {
      await open(tester);

      await menu(tester, 'Office', 'Set as default');

      verify(() => repository.setDefault('a2')).called(1);
      verify(() => repository.savedAddresses()).called(2);
      expect(find.text('Default address changed'), findsOneWidget);
    });

    testWidgets('says so when it fails', (tester) async {
      when(() => repository.setDefault(any())).thenThrow(_error('ERROR_X', status: 500));
      await open(tester);

      await menu(tester, 'Office', 'Set as default');

      expect(find.text('Something went wrong. Please try again'), findsOneWidget);
    });
  });

  group('delete', () {
    testWidgets('asks first, then deletes and reads the list again', (tester) async {
      await open(tester);

      await menu(tester, 'Office', 'Delete');
      expect(find.text('Delete this address?'), findsOneWidget);
      expect(find.text('Office will be removed from your saved addresses.'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      verify(() => repository.delete('a2')).called(1);
      verify(() => repository.savedAddresses()).called(2);
      expect(find.text('Address deleted'), findsOneWidget);
    });

    testWidgets('deletes nothing when the user cancels', (tester) async {
      await open(tester);

      await menu(tester, 'Office', 'Delete');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => repository.delete(any()));
    });

    testWidgets('explains that an address in use cannot be deleted', (tester) async {
      when(() => repository.delete(any())).thenThrow(_error('ERROR_ADDRESS_IN_USE'));
      await open(tester);

      await menu(tester, 'Office', 'Delete');
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(
        find.text(
            'This address is used by an item in your cart or a listing. Remove it there first'),
        findsOneWidget,
      );
    });
  });

  group('add and edit', () {
    testWidgets('adds an address from the form and reads the list again', (tester) async {
      await open(tester);

      await tester.scrollUntilVisible(find.text('Add address'), 200);
      await tester.tap(find.text('Add address'));
      await tester.pumpAndSettle();
      expect(find.text('New address'), findsOneWidget);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), '4 Residency Road, Shanti Nagar');
      await tester.enterText(fields.at(3), 'Bengaluru');
      await tester.enterText(fields.at(4), '560025');
      await tester.tap(find.text('Select your state'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Karnataka'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 900));
      await tester.ensureVisible(find.text('Save address'));
      await tester.tap(find.text('Save address'));
      await tester.pumpAndSettle();

      verify(() => repository.create(any(),
          label: any(named: 'label'), makeDefault: any(named: 'makeDefault'))).called(1);
      verify(() => repository.savedAddresses()).called(2);
      expect(find.text('Address saved'), findsOneWidget);
    });

    testWidgets('opens the form filled with the address and its name selected', (tester) async {
      await open(tester);

      await menu(tester, 'Office', 'Edit');

      expect(find.text('Edit address'), findsOneWidget);
      expect(find.widgetWithText(TextField, '9 Baner Road'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Pune'), findsOneWidget);
      expect(find.widgetWithText(TextField, '411045'), findsOneWidget);
      expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Office')).selected, isTrue);
      expect(find.byType(SwitchListTile), findsNothing);
    });

    testWidgets('a rename alone is saved without checking the address again', (tester) async {
      await open(tester);

      await menu(tester, 'Office', 'Edit');
      await tester.tap(find.widgetWithText(ChoiceChip, 'Home'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 900));
      await tester.ensureVisible(find.text('Save address'));
      await tester.tap(find.text('Save address'));
      await tester.pumpAndSettle();

      verify(() => repository.update('a2', any(), label: 'Home')).called(1);
      verifyNever(() => repository.verify(any()));
      expect(find.text('Address updated'), findsOneWidget);
    });

    testWidgets('a changed address is checked again before it is saved', (tester) async {
      await open(tester);

      await menu(tester, 'Office', 'Edit');
      await tester.enterText(find.widgetWithText(TextField, '411045'), '411001');
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      verify(() => repository.verify(any())).called(1);
      expect(find.text('Address verified'), findsNothing);
    });

    testWidgets('keeps a custom name and shows it in the form', (tester) async {
      when(() => repository.savedAddresses()).thenAnswer(
        (_) async => [
          const SavedAddress(
            id: 'a4',
            label: "Mum's flat",
            address: '9 Baner Road',
            city: 'Pune',
            state: 'Maharashtra',
            pincode: '411045',
          ),
        ],
      );
      await open(tester);

      await menu(tester, "Mum's flat", 'Edit');

      expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Other')).selected, isTrue);
      expect(find.widgetWithText(TextField, "Mum's flat"), findsOneWidget);
    });
  });

  group('the message for a refused change', () {
    final l10n = AppLocalizationsEn();

    test('names an address in use, the limit, and anything else', () {
      expect(addressManageError(l10n, _error('ERROR_ADDRESS_IN_USE')), l10n.addressErrorInUse);
      expect(addressManageError(l10n, _error('ERROR_ADDRESS_LIMIT_REACHED', status: 400)),
          l10n.addressErrorLimit);
      expect(addressManageError(l10n, _error('ERROR_OTHER')), l10n.addressActionFailed);
      expect(addressManageError(l10n, StateError('boom')), l10n.addressActionFailed);
    });
  });
}
