import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/cart/presentation/cart_error_messages.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';
import 'package:valuex_mobile/l10n/app_localizations_en.dart';

ApiError _error(String code, {Map<String, String> details = const {}}) => ApiError(
      type: ApiErrorType.business,
      message: 'server words',
      code: code,
      statusCode: 409,
      details: details,
    );

void main() {
  final AppLocalizations l10n = AppLocalizationsEn();

  group('cartErrorMessage', () {
    test('says the limit when the server sends it, and a general line when it does not', () {
      expect(
        cartErrorMessage(l10n, _error('ERROR_MAX_CART_ITEMS', details: {'limit': '20'})),
        'Cart limit reached (20 items)',
      );
      expect(
        cartErrorMessage(l10n, _error('ERROR_MAX_CART_ITEMS')),
        'Cart limit reached. Remove an item to add another',
      );
    });

    test('gives each cart code its own text', () {
      expect(cartErrorMessage(l10n, _error('ERROR_PRICE_NOT_ACCEPTED')), contains('accepted'));
      expect(cartErrorMessage(l10n, _error('ERROR_UNAUTHORIZED_CHECKOUT')), contains('own item'));
      expect(cartErrorMessage(l10n, _error('ERROR_CHECKOUT_NOT_APPLICABLE')), contains("can't be"));
      expect(cartErrorMessage(l10n, _error('ERROR_CART_ITEM_NOT_FOUND')), contains('not in'));
      expect(
          cartErrorMessage(l10n, _error('ERROR_CHECKOUT_UNAVAILABLE')), contains('not available'));
    });

    test('falls back to the Buy Now texts and to a generic one for anything else', () {
      expect(cartErrorMessage(l10n, _error('ERROR_ITEM_RESERVED')), isNotEmpty);
      expect(cartErrorMessage(l10n, _error('ERROR_SOMETHING_NEW')), isNotEmpty);
      expect(cartErrorMessage(l10n, StateError('boom')), isNotEmpty);
    });
  });

  group('cartErrorStalesPage', () {
    test('is true for the refusals that mean the listing page is out of date', () {
      for (final code in [
        'ERROR_ITEM_RESERVED',
        'ERROR_PRICE_NOT_ACCEPTED',
        'ERROR_ITEM_UNAVAILABLE',
        'ERROR_LISTING_NOT_AVAILABLE',
      ]) {
        expect(cartErrorStalesPage(_error(code)), isTrue, reason: code);
      }
    });

    test('is false for a full cart, a network failure or something that is not an ApiError', () {
      expect(cartErrorStalesPage(_error('ERROR_MAX_CART_ITEMS')), isFalse);
      expect(cartErrorStalesPage(StateError('x')), isFalse);
    });
  });

  group('cartProblemText', () {
    test('turns the server problem code into a line, and no code into none', () {
      expect(cartProblemText(l10n, null), isNull);
      expect(cartProblemText(l10n, 'ERROR_PRICE_CHANGED'), 'Price changed. Please review');
      expect(cartProblemText(l10n, 'ERROR_CART_EXPIRED'), 'Cart item expired. Please add again');
      expect(cartProblemText(l10n, 'ERROR_ACCEPTANCE_EXPIRED'), contains('acceptance expired'));
      expect(cartProblemText(l10n, 'ERROR_ITEM_UNAVAILABLE'), 'No longer available');
      expect(cartProblemText(l10n, 'ERROR_OTHER'), 'No longer available');
    });
  });
}
