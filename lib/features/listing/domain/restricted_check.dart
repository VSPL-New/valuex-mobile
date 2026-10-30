/// What the restricted-item check found (US-007).
enum RestrictedResult {
  safe,
  complianceRequired,
  unclear,
  restricted,
  severeViolation;

  static RestrictedResult parse(String? value) => switch (value) {
        'SAFE' => safe,
        'COMPLIANCE_REQUIRED' => complianceRequired,
        'RESTRICTED' => restricted,
        'SEVERE_VIOLATION' => severeViolation,
        _ => unclear,
      };

  /// The listing cannot go on; the seller may appeal.
  bool get isBlocked => this == restricted || this == severeViolation;
}

/// One row of the Restrictions policy as the server sends it, in English and Hindi.
class RestrictionPolicy {
  final String code;
  final String title;
  final String? titleHi;
  final String message;
  final String? messageHi;

  const RestrictionPolicy({
    required this.code,
    required this.title,
    required this.message,
    this.titleHi,
    this.messageHi,
  });

  factory RestrictionPolicy.fromJson(Map<String, dynamic> json) => RestrictionPolicy(
        code: json['code'] as String,
        title: json['title'] as String? ?? '',
        titleHi: json['titleHi'] as String?,
        message: json['message'] as String? ?? '',
        messageHi: json['messageHi'] as String?,
      );

  /// The title in the seller's language; English when there is no Hindi text.
  String titleIn(String languageCode) => _pick(languageCode, title, titleHi);

  String messageIn(String languageCode) => _pick(languageCode, message, messageHi);

  static String _pick(String languageCode, String english, String? hindi) =>
      languageCode == 'hi' && hindi != null && hindi.isNotEmpty ? hindi : english;
}

/// The answer of POST /listings/{id}/restricted-check. A blocked item comes back as an error
/// response that still carries this body.
class RestrictedCheck {
  final String checkId;
  final RestrictedResult result;
  final List<RestrictionPolicy> policies;

  const RestrictedCheck({
    required this.checkId,
    required this.result,
    this.policies = const [],
  });

  factory RestrictedCheck.fromJson(Map<String, dynamic> json) => RestrictedCheck(
        checkId: json['checkId'] as String,
        result: RestrictedResult.parse(json['result'] as String?),
        policies: [
          for (final item in json['policies'] as List<dynamic>? ?? const [])
            RestrictionPolicy.fromJson(item as Map<String, dynamic>),
        ],
      );

  List<String> get policyCodes => [for (final policy in policies) policy.code];
}
