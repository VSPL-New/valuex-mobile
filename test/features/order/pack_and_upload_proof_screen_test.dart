import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/core/theme/app_theme.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/domain/entities/user_profile.dart';
import 'package:valuex_mobile/features/listing/data/photo_source.dart';
import 'package:valuex_mobile/features/listing/domain/listing_photo.dart';
import 'package:valuex_mobile/features/order/data/mock_seller_order_repository.dart';
import 'package:valuex_mobile/features/order/domain/entities/packing.dart';
import 'package:valuex_mobile/features/order/domain/repositories/seller_order_repository.dart';
import 'package:valuex_mobile/features/order/presentation/packing/pack_and_upload_proof_screen.dart';
import 'package:valuex_mobile/features/order/presentation/providers/seller_order_providers.dart';
import 'package:valuex_mobile/features/profile/data/profile_repository.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

class _MockRepository extends Mock implements SellerOrderRepository {}

/// Gives one photo per pick, of the size the test sets; or refuses access.
class _FakePhotoSource implements PhotoSource {
  int width = 1200;
  int height = 900;
  bool denied = false;
  bool unreadable = false;

  @override
  Future<List<PickedPhoto>> pick(PhotoSourceKind kind, {required int limit}) async {
    if (denied) throw PhotoAccessDeniedException(kind);
    return [
      PickedPhoto(name: 'a.jpg', bytes: Uint8List.fromList([1, 2, 3]))
    ];
  }

  @override
  Future<PhotoInspection?> inspect(Uint8List bytes) async =>
      unreadable ? null : PhotoInspection(contentType: 'image/jpeg', width: width, height: height);
}

void main() {
  late _FakePhotoSource photos;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(ProofKind.itemCondition);
  });

  setUp(() => photos = _FakePhotoSource());

  Future<void> pump(
    WidgetTester tester, {
    SellerOrderRepository? repo,
    String orderId = 'mock-1000',
    Locale locale = const Locale('en'),
    double textScale = 1,
    double height = 6000,
  }) async {
    tester.view.physicalSize = Size(1080, height);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  final done = await context.push<bool>(RouteNames.sellerOrderPacking(orderId));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('returned $done')));
                  }
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.sellerOrderPackingPattern,
          builder: (context, state) =>
              PackAndUploadProofScreen(orderId: state.pathParameters['orderId']!),
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sellerOrderRepositoryProvider.overrideWithValue(repo ?? MockSellerOrderRepository()),
        photoSourceProvider.overrideWithValue(photos),
        userProfileProvider.overrideWith((ref) async => const UserProfile(
            userId: 'seller-1', status: AccountStatus.active, aadhaarVerified: true)),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> add(WidgetTester tester, String section) async {
    final tile = find.bySemanticsLabel(section);
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();
  }

  Future<void> enterSize(WidgetTester tester, {String weight = '1.2'}) async {
    final fields = find.byType(TextFormField);
    for (final (index, value) in [weight, '30', '20', '15'].indexed) {
      await tester.ensureVisible(fields.at(index));
      await tester.enterText(fields.at(index), value);
    }
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    final button = find.text('Submit Proof & Schedule Pickup');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('shows the Make screen: order, steps, empty sections, escrow and the hint',
      (tester) async {
    await pump(tester);

    expect(find.text('Pack & Upload Proof'), findsOneWidget);
    expect(find.text('Required before pickup is scheduled'), findsOneWidget);
    expect(find.text('Sony A7III Camera Body'), findsOneWidget);
    expect(find.text('Order #ORD-S-1000'), findsOneWidget);
    expect(find.text('STEPS TO FOLLOW:'), findsOneWidget);
    expect(find.text('Wrap item securely with bubble wrap/foam'), findsOneWidget);
    expect(find.text('Min 2, max 4 photos required'), findsOneWidget);
    expect(find.text('0/4'), findsOneWidget);
    expect(find.text('0/2'), findsOneWidget);
    expect(find.textContaining('is held in escrow'), findsOneWidget);
    expect(find.textContaining('85,000'), findsOneWidget);
    expect(find.text('Add at least 2 item photos + 1 packaging photo'), findsOneWidget);
    expect(
        find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.label == '0 of 4 photos added'),
        findsOneWidget);
  });

  testWidgets('adds the photos, enters the size and finishes, returning done', (tester) async {
    await pump(tester);

    await add(tester, 'Add item photo');
    await add(tester, 'Add item photo');
    await add(tester, 'Add packaging photo');
    expect(find.text('2/4'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
    expect(find.bySemanticsLabel('Item photo 2 of 2'), findsOneWidget);
    expect(find.text('Add at least 2 item photos + 1 packaging photo'), findsNothing);

    await enterSize(tester);
    await submit(tester);

    expect(find.text('returned true'), findsOneWidget);
  });

  testWidgets('removes a photo and checks the packed size before sending', (tester) async {
    await pump(tester);
    await add(tester, 'Add item photo');
    await add(tester, 'Add item photo');
    await add(tester, 'Add packaging photo');

    await tester.tap(find.byTooltip('Remove photo').first);
    await tester.pumpAndSettle();
    expect(find.text('1/4'), findsOneWidget);
    await add(tester, 'Add item photo');

    await enterSize(tester, weight: '31');
    await submit(tester);

    expect(find.text('Enter a packed weight between 0.05 and 30 kg'), findsOneWidget);
    expect(find.text('Pack & Upload Proof'), findsOneWidget);
  });

  testWidgets('says why a photo was not added', (tester) async {
    await pump(tester);

    photos.height = 300;
    await add(tester, 'Add item photo');
    expect(find.text('Image quality low. Upload clearer photo'), findsOneWidget);

    photos.unreadable = true;
    await add(tester, 'Add item photo');
    expect(find.text("This photo can't be used. Choose another"), findsOneWidget);

    photos.denied = true;
    await add(tester, 'Add item photo');
    expect(find.text('Allow access to your camera or photos in Settings to add a photo'),
        findsOneWidget);
    expect(find.text('0/4'), findsOneWidget);
  });

  testWidgets('a failed upload can be retried from its photo', (tester) async {
    final repo = _MockRepository();
    final sample = await MockSellerOrderRepository().packing('mock-1000');
    when(() => repo.packing('mock-1000')).thenAnswer((_) async => sample);
    var fail = true;
    when(() => repo.uploadProofPhoto(
          ownerId: any(named: 'ownerId'),
          fileName: any(named: 'fileName'),
          contentType: any(named: 'contentType'),
          bytes: any(named: 'bytes'),
          width: any(named: 'width'),
          height: any(named: 'height'),
        )).thenAnswer((_) async {
      if (fail) throw const ApiError(type: ApiErrorType.network, message: 'offline');
      return 'media-1';
    });
    when(() => repo.attachProof('mock-1000', 'media-1', ProofKind.itemCondition)).thenAnswer(
        (_) async =>
            OrderProof(id: 'p1', kind: ProofKind.itemCondition, uploadedAt: DateTime(2026)));
    await pump(tester, repo: repo);

    await add(tester, 'Add item photo');
    expect(find.text('Failed to upload images. Try again'), findsOneWidget);
    expect(find.text('1/4'), findsOneWidget);

    fail = false;
    // The top-right corner is the remove button; the rest of the photo retries.
    final failed = find.bySemanticsLabel('Upload failed. Tap to try again');
    await tester.tapAt(tester.getBottomLeft(failed) + const Offset(10, -10));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Item photo 1 of 1'), findsOneWidget);
  });

  testWidgets('goes back to the list when the order has moved on', (tester) async {
    final repo = _MockRepository();
    final sample = await MockSellerOrderRepository().packing('mock-1000');
    when(() => repo.packing('mock-1000')).thenAnswer((_) async => sample);
    when(() => repo.uploadProofPhoto(
          ownerId: any(named: 'ownerId'),
          fileName: any(named: 'fileName'),
          contentType: any(named: 'contentType'),
          bytes: any(named: 'bytes'),
          width: any(named: 'width'),
          height: any(named: 'height'),
        )).thenAnswer((_) async => 'media-1');
    when(() => repo.attachProof(any(), any(), any())).thenThrow(const ApiError(
        type: ApiErrorType.business, message: 'moved', code: 'ERROR_ORDER_ACTION_NOT_ALLOWED'));
    await pump(tester, repo: repo);

    await add(tester, 'Add item photo');

    expect(find.text('open'), findsOneWidget);
    expect(find.text('This order has already moved to the next step. Refreshing'), findsOneWidget);
  });

  testWidgets('offers Retry when the order cannot be loaded', (tester) async {
    final repo = _MockRepository();
    var calls = 0;
    when(() => repo.packing('o1')).thenAnswer((_) async {
      if (calls++ == 0) throw const ApiError(type: ApiErrorType.network, message: 'offline');
      return MockSellerOrderRepository().packing('mock-1000');
    });
    await pump(tester, repo: repo, orderId: 'o1');

    expect(find.text('Unable to load this order. Tap Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Order #ORD-S-1000'), findsOneWidget);
  });

  testWidgets('fits in Hindi at twice the text size', (tester) async {
    await pump(tester, locale: const Locale('hi'), textScale: 2, height: 2400);

    expect(find.text('पैक करें और प्रमाण अपलोड करें'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
