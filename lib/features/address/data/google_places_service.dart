import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/address_details.dart';
import '../domain/address_search_service.dart';
import '../domain/address_suggestion.dart';
import '../domain/indian_state_names.dart';

/// Google Places API (New): autocomplete restricted to India, then the place's components.
class GooglePlacesService implements AddressSearchService {
  static const _host = 'https://places.googleapis.com/v1';

  final Dio _dio;

  GooglePlacesService({
    required String apiKey,
    String androidCert = '',
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = _host
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 10)
      ..headers['X-Goog-Api-Key'] = apiKey
      ..headers.addAll(_appRestrictionHeaders(androidCert));
  }

  /// A key restricted to this app is only accepted when the call says which app it comes from.
  static Map<String, String> _appRestrictionHeaders(String androidCert) {
    if (kIsWeb) return const {};
    if (Platform.isIOS) return {'X-Ios-Bundle-Identifier': AppConstants.iosBundleId};
    if (Platform.isAndroid) {
      return {
        'X-Android-Package': AppConstants.androidPackage,
        if (androidCert.isNotEmpty) 'X-Android-Cert': androidCert,
      };
    }
    return const {};
  }

  @override
  Future<List<AddressSuggestion>> suggest(String query, {required String sessionToken}) async {
    final json = await _call(
      () => _dio.post<Map<String, dynamic>>(
        '/places:autocomplete',
        data: {
          'input': query,
          'sessionToken': sessionToken,
          'includedRegionCodes': ['in'],
          'languageCode': 'en',
        },
      ),
    );
    return parseSuggestions(json);
  }

  @override
  Future<AddressDetails> details(String placeId, {required String sessionToken}) async {
    final json = await _call(
      () => _dio.get<Map<String, dynamic>>(
        '/places/$placeId',
        queryParameters: {'sessionToken': sessionToken, 'languageCode': 'en'},
        options: Options(
          headers: {'X-Goog-FieldMask': 'id,displayName,formattedAddress,addressComponents'},
        ),
      ),
    );
    return parseDetails(json);
  }

  Future<Map<String, dynamic>> _call(Future<Response<Map<String, dynamic>>> Function() send) async {
    try {
      return (await send()).data ?? const {};
    } on DioException catch (e) {
      throw AddressSearchUnavailable('Places request failed (${e.response?.statusCode})');
    }
  }

  static List<AddressSuggestion> parseSuggestions(Map<String, dynamic> json) {
    final suggestions = json['suggestions'];
    if (suggestions is! List) return const [];
    final result = <AddressSuggestion>[];
    for (final item in suggestions) {
      final prediction = (item as Map<String, dynamic>)['placePrediction'];
      if (prediction is! Map<String, dynamic>) continue;
      final placeId = prediction['placeId'] as String?;
      final structured = prediction['structuredFormat'] as Map<String, dynamic>?;
      final main = (structured?['mainText'] as Map<String, dynamic>?)?['text'] as String?;
      final secondary = (structured?['secondaryText'] as Map<String, dynamic>?)?['text'] as String?;
      final full = (prediction['text'] as Map<String, dynamic>?)?['text'] as String?;
      if (placeId == null || (main ?? full) == null) continue;
      result.add(
        AddressSuggestion(
          placeId: placeId,
          primaryText: main ?? full!,
          secondaryText: secondary ?? '',
        ),
      );
    }
    return result;
  }

  static AddressDetails parseDetails(Map<String, dynamic> json) {
    final components = <String, String>{};
    for (final item in (json['addressComponents'] as List<dynamic>? ?? const [])) {
      final map = item as Map<String, dynamic>;
      final text = map['longText'] as String?;
      if (text == null || text.isEmpty) continue;
      for (final type in (map['types'] as List<dynamic>? ?? const [])) {
        components.putIfAbsent(type as String, () => text);
      }
    }

    String? first(List<String> types) {
      for (final type in types) {
        final value = components[type];
        if (value != null) return value;
      }
      return null;
    }

    final lineParts = <String>[];
    for (final type in const [
      'subpremise',
      'premise',
      'street_number',
      'route',
      'sublocality_level_3',
      'sublocality_level_2',
      'sublocality_level_1',
    ]) {
      final value = components[type];
      if (value != null && !lineParts.contains(value)) lineParts.add(value);
    }
    final formatted = json['formattedAddress'] as String? ?? '';
    final line1 =
        lineParts.isNotEmpty ? lineParts.join(', ') : formatted.split(',').take(2).join(',').trim();

    return AddressDetails(
      line1: line1,
      area: first(['sublocality_level_1', 'neighborhood', 'sublocality']),
      city: first(['locality', 'administrative_area_level_3', 'administrative_area_level_2']) ?? '',
      state: normalizeIndianState(components['administrative_area_level_1']),
      pincode: components['postal_code']?.replaceAll(RegExp(r'\s'), '') ?? '',
      placeId: json['id'] as String? ?? '',
    );
  }
}
