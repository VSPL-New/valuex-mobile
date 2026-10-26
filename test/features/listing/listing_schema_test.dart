import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/features/listing/domain/category.dart';
import 'package:valuex_mobile/features/listing/domain/listing_details.dart';
import 'package:valuex_mobile/features/listing/domain/listing_schema.dart';

import 'listing_fixtures.dart';

void main() {
  group('category models', () {
    test('CategoryNode reads the server JSON and defaults the optional flags', () {
      final node = CategoryNode.fromJson(
          {'code': 'L1-X', 'name': 'X', 'level': 1, 'hasChildren': true, 'popular': true});
      expect(node.hasChildren, isTrue);
      expect(node.popular, isTrue);
      expect(node.marketplaceStatus, 'ALLOWED');
      final leaf = CategoryNode.fromJson({'code': 'CAT-1', 'name': 'Y', 'level': 3});
      expect(leaf.hasChildren, isFalse);
      expect(leaf.popular, isFalse);
    });

    test('CategoryRef lists its ancestors without itself', () {
      final ref = phoneSchema.category;
      expect(ref.code, 'CAT-1');
      expect(ref.path, hasLength(3));
      expect(ref.parentsLabel, 'Mobiles & Tablets > Smartphones');
      expect(const CategoryRef(code: 'c', name: 'n').parentsLabel, isEmpty);
    });

    test('scopes map to the API values', () {
      expect(CategoryScope.popular.apiValue, 'POPULAR');
      expect(CategoryScope.others.apiValue, 'OTHERS');
      expect(CategoryScope.all.apiValue, 'ALL');
    });
  });

  group('ListingSchema', () {
    test('reads the category, common flags and fields', () {
      expect(phoneSchema.group, 'GOODS');
      expect(phoneSchema.isRealEstate, isFalse);
      expect(phoneSchema.common.quantityVisible, isTrue);
      expect(phoneSchema.fields, hasLength(5));
      expect(phoneSchema.keys, containsAll(['brand', 'storage_gb', 'age_months']));
      expect(phoneSchema.field('storage_gb')!.options.first.label, '64 GB');
      expect(phoneSchema.field('nope'), isNull);
      expect(phoneSchema.field('age_months')!.isMore, isTrue);
      expect(phoneSchema.moreFields.map((f) => f.key), ['age_months']);
      expect(phoneSchema.categoryFields.map((f) => f.key),
          ['brand', 'storage_gb', 'battery_health_pct', 'pincode']);
      expect(phoneSchema.field('battery_health_pct')!.unit, '%');
      expect(phoneSchema.field('battery_health_pct')!.max, 100);
    });

    test('field types map from the API and unknown ones become text', () {
      expect(FieldType.parse('MULTI_OPTION'), FieldType.multiOption);
      expect(FieldType.parse('OPTION_OR_TEXT'), FieldType.optionOrText);
      expect(FieldType.parse('TEXT_LIST'), FieldType.textList);
      expect(FieldType.parse('OBJECT'), FieldType.object);
      expect(FieldType.parse('JSON'), FieldType.json);
      expect(FieldType.parse('LONG_TEXT'), FieldType.longText);
      expect(FieldType.parse('BOOLEAN'), FieldType.boolean);
      expect(FieldType.parse('DATE'), FieldType.date);
      expect(FieldType.parse('SOMETHING'), FieldType.text);
      expect(FieldType.integer.isNumber, isTrue);
      expect(FieldType.text.isNumber, isFalse);
    });

    test('a real estate schema derives the price and asks the one for the intent', () {
      expect(homeSchema.isRealEstate, isTrue);
      expect(homeSchema.common.priceDerived, isTrue);
      expect(homeSchema.transactionIntents, ['SALE', 'RENT']);
      final sale = homeSchema.field('sale_price')!;
      final rent = homeSchema.field('monthly_rent')!;
      expect(sale.requiredWhen!.values, ['SALE']);
      expect(homeSchema.isRequired(sale, const {}), isFalse);
      expect(homeSchema.isRequired(sale, const {'transaction_intent': 'SALE'}), isTrue);
      expect(homeSchema.isRequired(rent, const {'transaction_intent': 'SALE'}), isFalse);
      expect(homeSchema.isRequired(rent, const {'transaction_intent': 'RENT'}), isTrue);
      expect(homeSchema.isRequired(homeSchema.field('transaction_intent')!, const {}), isTrue);
    });

    test('lists keys that are missing or invalid', () {
      expect(phoneSchema.invalidKeys(const {}), ['brand', 'storage_gb']);
      expect(phoneSchema.invalidKeys(const {'brand': 'Sony', 'storage_gb': '64_GB'}), isEmpty);
      expect(
        phoneSchema.invalidKeys(const {
          'brand': 'Sony',
          'storage_gb': '64_GB',
          'battery_health_pct': '120',
          'age_months': '-1',
          'pincode': '012345',
        }),
        ['battery_health_pct', 'age_months', 'pincode'],
      );
      expect(homeSchema.invalidKeys(const {'transaction_intent': 'SALE'}), ['sale_price']);
    });
  });

  group('isValidValue', () {
    final decimal = phoneSchema.field('battery_health_pct')!;
    final integer = phoneSchema.field('age_months')!;
    final text = phoneSchema.field('brand')!;

    test('numbers must parse, fit the range and the allowed decimals', () {
      expect(isValidValue(decimal, '99.5'), isTrue);
      expect(isValidValue(decimal, 100), isTrue);
      expect(isValidValue(decimal, '100.01'), isFalse);
      expect(isValidValue(decimal, '1.234'), isFalse);
      expect(isValidValue(decimal, 'abc'), isFalse);
      expect(isValidValue(integer, '12'), isTrue);
      expect(isValidValue(integer, '1,200'), isTrue);
      expect(isValidValue(integer, '1.5'), isFalse);
      expect(isValidValue(integer, '1201'), isFalse);
    });

    test('text keeps to its length and pattern', () {
      expect(isValidValue(text, 'Sony'), isTrue);
      expect(isValidValue(text, 'a' * 11), isFalse);
      final pincode = phoneSchema.field('pincode')!;
      expect(isValidValue(pincode, '560001'), isTrue);
      expect(isValidValue(pincode, '56000'), isFalse);
    });

    test('other types are accepted as they are', () {
      expect(isValidValue(phoneSchema.field('storage_gb')!, '64_GB'), isTrue);
    });

    test('blank means empty text, lists and maps', () {
      expect(isBlankValue(null), isTrue);
      expect(isBlankValue('  '), isTrue);
      expect(isBlankValue(const []), isTrue);
      expect(isBlankValue(const {}), isTrue);
      expect(isBlankValue(false), isFalse);
      expect(isBlankValue(0), isFalse);
      expect(isBlankValue('x'), isFalse);
    });
  });

  group('ListingDetailsDraft', () {
    test('an empty draft is missing the title, category and description', () {
      expect(const ListingDetailsDraft().invalidFields(null),
          [DetailsField.title, DetailsField.category, DetailsField.description]);
      expect(const ListingDetailsDraft().isValid(null), isFalse);
    });

    test('with a goods schema every common field is asked', () {
      expect(
          const ListingDetailsDraft(categoryCode: 'CAT-1', quantity: '').invalidFields(phoneSchema),
          [
            DetailsField.title,
            DetailsField.condition,
            DetailsField.conditionNotes,
            DetailsField.description,
            DetailsField.price,
            DetailsField.negotiable,
            DetailsField.quantity,
          ]);
    });

    test('a complete draft is valid', () {
      expect(complete.isValid(phoneSchema), isTrue);
      expect(complete.parsedPrice, 1299.5);
      expect(complete.parsedQuantity, 2);
    });

    test('a real estate draft needs no condition, price or quantity of its own', () {
      const draft = ListingDetailsDraft(
        title: 'Flat',
        categoryCode: 'CAT-9',
        description: 'Near the metro',
        negotiable: false,
        attributes: {'transaction_intent': 'RENT', 'monthly_rent': '25000'},
      );
      expect(draft.invalidFields(homeSchema), isEmpty);
      expect(draft.isValid(homeSchema), isTrue);
      expect(
          draft.copyWith(attributes: {'transaction_intent': 'RENT'}).isValid(homeSchema), isFalse);
    });

    test('rejects blank and over-long text', () {
      expect(complete.copyWith(title: '   ').invalidFields(phoneSchema), [DetailsField.title]);
      expect(complete.copyWith(title: 'a' * 101).invalidFields(phoneSchema), [DetailsField.title]);
      expect(complete.copyWith(title: 'a' * 100).isValid(phoneSchema), isTrue);
      expect(complete.copyWith(description: 'a' * 2001).invalidFields(phoneSchema),
          [DetailsField.description]);
      expect(complete.copyWith(conditionNotes: 'a' * 1001).invalidFields(phoneSchema),
          [DetailsField.conditionNotes]);
    });

    test('price accepts up to 2 decimals and the new limit only', () {
      for (final bad in ['', '0', '0.00', 'abc', '-5', '1.234', '100000000.01', '1e3']) {
        expect(complete.copyWith(price: bad).parsedPrice, isNull, reason: bad);
      }
      expect(complete.copyWith(price: '100000000').parsedPrice, 100000000);
      expect(complete.copyWith(price: ' 99.9 ').parsedPrice, 99.9);
      expect(ListingDetailsRules.maxPriceRupees, 100000000);
    });

    test('quantity is a whole number from 1 to 1000', () {
      for (final bad in ['', '0', '1001', '1.5', 'x']) {
        expect(complete.copyWith(quantity: bad).parsedQuantity, isNull, reason: bad);
      }
      expect(complete.copyWith(quantity: '1000').parsedQuantity, 1000);
    });

    test('the payload keeps only the category keys, sends numbers as numbers, drops blanks', () {
      final draft = complete.copyWith(attributes: {
        'brand': ' Sony ',
        'battery_health_pct': '1,0',
        'age_months': '18',
        'storage_gb': '',
        'not_in_schema': 'x',
      });
      expect(draft.attributePayload(phoneSchema),
          {'brand': 'Sony', 'battery_health_pct': 10, 'age_months': 18});
    });

    test('the request body has only what the category shows', () {
      final goods = complete.toJson(phoneSchema, city: 'Pune');
      expect(goods['title'], 'Sony headphones');
      expect(goods['condition'], 'GOOD');
      expect(goods['conditionNotes'], 'Small scratch');
      expect(goods['price'], 1299.5);
      expect(goods['negotiable'], isTrue);
      expect(goods['quantity'], 2);
      expect(goods['location'], 'Pune');
      expect(goods['attributes'], {'brand': 'Sony', 'storage_gb': '64_GB'});

      final home = complete.toJson(homeSchema);
      expect(home.containsKey('condition'), isFalse);
      expect(home.containsKey('conditionNotes'), isFalse);
      expect(home.containsKey('price'), isFalse);
      expect(home.containsKey('quantity'), isFalse);
      expect(home['negotiable'], isTrue);
    });
  });

  group('ListingCondition', () {
    test('maps API values both ways', () {
      expect(ListingCondition.fromApi('LIKE_NEW'), ListingCondition.likeNew);
      expect(ListingCondition.fromApi('x'), isNull);
      expect(ListingCondition.fromApi(null), isNull);
      expect(ListingCondition.poor.apiValue, 'POOR');
    });
  });

  group('AiSuggestion and feedback', () {
    const suggestion = AiSuggestion(
      id: 's1',
      categoryCode: 'CAT-1',
      title: 'Headphones',
      condition: ListingCondition.good,
      description: 'Over-ear',
    );

    test('asDraft clips long text and leaves price empty', () {
      final draft = AiSuggestion(id: 'x', title: 'a' * 150, description: 'b' * 2500).asDraft;
      expect(draft.title.length, 100);
      expect(draft.description.length, 2000);
      expect(draft.price, isEmpty);
      expect(const AiSuggestion(id: 'y').asDraft.title, isEmpty);
    });

    test('reports accepted, edited and rejected fields only for suggested ones', () {
      final current = complete.copyWith(title: 'Sony WH-1000', description: ' ');
      final feedback = suggestionFeedback(suggestion, current);
      final actions = {for (final f in feedback) f.field: f.action};
      expect(actions, {
        'CATEGORY': SuggestionAction.accepted,
        'TITLE': SuggestionAction.edited,
        'CONDITION': SuggestionAction.accepted,
        'DESCRIPTION': SuggestionAction.rejected,
      });
      expect(feedback.firstWhere((f) => f.field == 'TITLE').toJson(), {
        'field': 'TITLE',
        'action': 'EDITED',
        'originalValue': 'Headphones',
        'finalValue': 'Sony WH-1000',
      });
      expect(suggestionFeedback(const AiSuggestion(id: 'z'), complete), isEmpty);
    });
  });
}
