/// Backend envelope `{ success, data, error{code,message,details?}, metadata }`.
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? errorCode;
  final String? errorMessage;
  final Map<String, String> errorDetails;

  const ApiResponse({
    required this.success,
    this.data,
    this.errorCode,
    this.errorMessage,
    this.errorDetails = const {},
  });

  /// Returns null when [json] is not an envelope.
  static ApiResponse<T>? tryParse<T>(Object? json, {T Function(Object? data)? parse}) {
    if (json is! Map<String, dynamic> || json['success'] is! bool) return null;

    final success = json['success'] as bool;
    if (success) {
      final raw = json['data'];
      return ApiResponse<T>(
        success: true,
        data: parse != null ? parse(raw) : raw as T?,
      );
    }

    final error = json['error'];
    final details = <String, String>{};
    if (error is Map<String, dynamic> && error['details'] is Map) {
      (error['details'] as Map).forEach((key, value) {
        details['$key'] = '$value';
      });
    }
    return ApiResponse<T>(
      success: false,
      errorCode: error is Map<String, dynamic> ? error['code'] as String? : null,
      errorMessage: error is Map<String, dynamic> ? error['message'] as String? : null,
      errorDetails: details,
    );
  }
}
