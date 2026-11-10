/// What a Real Estate buyer wants to do: buy, rent or lease. [apiValue] is the server's code.
enum TransactionIntent {
  sale('SALE'),
  rent('RENT'),
  lease('LEASE');

  final String apiValue;

  const TransactionIntent(this.apiValue);

  static TransactionIntent? fromApi(String? value) {
    for (final intent in values) {
      if (intent.apiValue == value) return intent;
    }
    return null;
  }
}
