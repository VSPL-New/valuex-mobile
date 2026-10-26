// Sample category forms shared by the listing tests.
import 'package:valuex_mobile/features/listing/domain/listing_details.dart';
import 'package:valuex_mobile/features/listing/domain/listing_schema.dart';

Map<String, dynamic> field(
  String key,
  String type, {
  bool required = false,
  String? unit,
  String section = 'CATEGORY',
  List<Map<String, String>> options = const [],
  Map<String, dynamic> validation = const {},
  Map<String, dynamic>? requiredWhen,
  String? prefillOption,
}) =>
    {
      'key': key,
      'label': key.replaceAll('_', ' '),
      'type': type,
      'unit': unit,
      'required': required,
      'requiredWhen': requiredWhen,
      'section': section,
      'options': options,
      'validation': validation,
      'aiPrefill': false,
      'order': 0,
      'prefillOption': prefillOption,
    };

Map<String, dynamic> schemaJson({
  String code = 'CAT-1',
  String group = 'GOODS',
  String profile = 'PHONE',
  Map<String, dynamic>? common,
  List<String> intents = const [],
  required List<Map<String, dynamic>> fields,
}) =>
    {
      'category': {
        'code': code,
        'name': 'Android Phones',
        'marketplaceStatus': 'ALLOWED',
        'path': [
          {'code': 'L1-M', 'name': 'Mobiles & Tablets', 'level': 1},
          {'code': 'L2-S', 'name': 'Smartphones', 'level': 2},
          {'code': code, 'name': 'Android Phones', 'level': 3},
        ],
      },
      'profileCode': profile,
      'group': group,
      'common': common ??
          {
            'conditionVisible': true,
            'quantityVisible': true,
            'negotiableVisible': true,
            'priceDerived': false,
          },
      'transactionIntents': intents,
      'fields': fields,
    };

final phoneSchema = ListingSchema.fromJson(schemaJson(fields: [
  field('brand', 'TEXT', required: true, validation: {'maxLength': 10}),
  field('storage_gb', 'OPTION', required: true, options: [
    {'code': '64_GB', 'label': '64 GB'},
    {'code': '128_GB', 'label': '128 GB'},
  ]),
  field('battery_health_pct', 'DECIMAL',
      unit: '%', validation: {'min': 0, 'max': 100, 'maxDecimals': 2}),
  field('age_months', 'INTEGER', section: 'MORE', validation: {'min': 0, 'max': 1200}),
  field('pincode', 'TEXT', validation: {'pattern': r'^[1-9][0-9]{5}$'}),
]));

final homeSchema = ListingSchema.fromJson(schemaJson(
  code: 'CAT-9',
  group: 'REAL_ESTATE',
  profile: 'PROP_HOME',
  common: {
    'conditionVisible': false,
    'quantityVisible': false,
    'negotiableVisible': true,
    'priceDerived': true,
  },
  intents: ['SALE', 'RENT'],
  fields: [
    field('transaction_intent', 'OPTION', required: true, options: [
      {'code': 'SALE', 'label': 'Sale'},
      {'code': 'RENT', 'label': 'Rent'},
    ]),
    field('sale_price', 'DECIMAL', unit: 'INR', requiredWhen: {
      'key': 'transaction_intent',
      'values': ['SALE']
    }),
    field('monthly_rent', 'DECIMAL', unit: 'INR', requiredWhen: {
      'key': 'transaction_intent',
      'values': ['RENT']
    }),
  ],
));

const complete = ListingDetailsDraft(
  title: 'Sony headphones',
  categoryCode: 'CAT-1',
  condition: ListingCondition.good,
  conditionNotes: 'Small scratch',
  description: 'Barely used',
  price: '1,299.50',
  negotiable: true,
  quantity: '2',
  attributes: {'brand': 'Sony', 'storage_gb': '64_GB'},
);
