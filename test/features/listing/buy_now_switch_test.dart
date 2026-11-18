import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/features/listing/domain/existing_listing.dart';
import 'package:valuex_mobile/features/listing/domain/listing_details.dart';
import 'package:valuex_mobile/features/listing/domain/listing_schema.dart';

import 'listing_fixtures.dart';

void main() {
  group('Allow Buy Now on the listing form (US-068)', () {
    test('is on for a new listing', () {
      expect(const ListingDetailsDraft().buyNowEnabled, isTrue);
    });

    test('is kept when another field is edited and changed on its own', () {
      final off = complete.copyWith(buyNowEnabled: false);

      expect(off.buyNowEnabled, isFalse);
      expect(off.copyWith(title: 'New title').buyNowEnabled, isFalse);
      expect(off.copyWith(buyNowEnabled: true).buyNowEnabled, isTrue);
    });

    test('is sent with the details where the form asks for negotiable', () {
      expect(complete.toJson(phoneSchema)['buyNowEnabled'], isTrue);
      expect(complete.copyWith(buyNowEnabled: false).toJson(phoneSchema)['buyNowEnabled'], isFalse);
    });

    test('is not sent where the form does not ask for negotiable (property)', () {
      final property = ListingSchema.fromJson(schemaJson(
        group: 'REAL_ESTATE',
        profile: 'PROP_HOME',
        common: {
          'conditionVisible': false,
          'quantityVisible': false,
          'negotiableVisible': false,
          'priceDerived': true,
        },
        fields: [],
      ));

      final json = complete.toJson(property);

      expect(json.containsKey('buyNowEnabled'), isFalse);
    });

    test('Buy Now or offers must stay on: both off is invalid', () {
      final bothOff = complete.copyWith(negotiable: false, buyNowEnabled: false);

      expect(bothOff.invalidFields(phoneSchema), [DetailsField.purchaseOption]);
      expect(bothOff.isValid(phoneSchema), isFalse);
    });

    test('Buy Now off with offers on, or Buy Now on with offers off, is valid', () {
      expect(complete.copyWith(buyNowEnabled: false).invalidFields(phoneSchema), isEmpty);
      expect(complete.copyWith(negotiable: false).invalidFields(phoneSchema), isEmpty);
    });

    test('an unanswered negotiable question is still reported as negotiable, not as the rule', () {
      final draft = complete.copyWith(buyNowEnabled: false);
      final unanswered = ListingDetailsDraft(
        title: draft.title,
        categoryCode: draft.categoryCode,
        condition: draft.condition,
        conditionNotes: draft.conditionNotes,
        description: draft.description,
        price: draft.price,
        buyNowEnabled: false,
        attributes: draft.attributes,
      );

      expect(unanswered.invalidFields(phoneSchema), [DetailsField.negotiable]);
    });

    test('a saved listing is read with the switch, on when the server does not say', () {
      final off = ExistingListing.fromJson({
        'listingId': 'l1',
        'status': 'PUBLISHED',
        'buyNowEnabled': false,
      });
      final unknown = ExistingListing.fromJson({'listingId': 'l1', 'status': 'DRAFT'});

      expect(off.draft.buyNowEnabled, isFalse);
      expect(unknown.draft.buyNowEnabled, isTrue);
    });
  });
}
