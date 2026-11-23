class RouteNames {
  RouteNames._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String createAccount = '/create-account';
  static const String signIn = '/sign-in';
  static const String signInVerify = '/sign-in/verify';
  static const String googleMobile = '/google/mobile';
  static const String googleVerify = '/google/verify';
  static const String signupMobile = '/signup/mobile';
  static const String signupMobileVerify = '/signup/mobile/verify';
  static const String signupEmail = '/signup/email';
  static const String signupEmailVerify = '/signup/email/verify';
  static const String signupAadhaar = '/signup/aadhaar';
  static const String devAadhaarOtp = '/dev/aadhaar-otp';
  static const String signupProfile = '/signup/profile';
  static const String terms = '/terms';
  static const String accountBlocked = '/account-blocked';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String profileDetails = '/profile/details';
  static const String myListings = '/profile/listings';
  static const String accountSecurity = '/profile/security';
  static const String language = '/profile/language';
  static const String changeMobile = '/profile/security/mobile';
  static const String changeEmail = '/profile/security/email';
  static const String categories = '/home/categories';
  static const String search = '/search';
  static const String searchCategories = '/search/categories';
  static const String savedSearches = '/search/saved';

  /// One saved search's results: what the daily alert and a tap on a saved search open.
  static String savedSearch(String id) =>
      Uri(path: savedSearches, queryParameters: {'id': id}).toString();
  static const String savedItems = '/saved-items';

  /// Offers received and sent (US-076).
  static const String offers = '/offers';

  /// The buyer's cart (US-019).
  static const String cart = '/cart';

  /// Choosing how a cart line is received (US-020).
  static const String cartItemsBase = '/cart/items';
  static String cartDelivery(String itemId) => '$cartItemsBase/$itemId/delivery';
  static const String cartDeliveryPattern = '$cartItemsBase/:itemId/delivery';
  static const String blockedUsers = '/profile/blocked-users';

  /// The Chats tab and one conversation (US-013).
  static const String chats = '/chats';
  static const String chatThreadBase = '/chats';
  static String chatThread(String threadId) => '$chatThreadBase/$threadId';
  static const String chatThreadPattern = '$chatThreadBase/:threadId';

  /// One price negotiation (US-017).
  static const String negotiationBase = '/negotiations';
  static String negotiation(String negotiationId) => '$negotiationBase/$negotiationId';
  static const String negotiationPattern = '$negotiationBase/:negotiationId';

  /// One voice or video call (US-014, US-015): the ringing, in-call and ended screens in one route.
  static const String callBase = '/call';
  static String call(String callId) => '$callBase/$callId';
  static const String callPattern = '$callBase/:callId';
  static const String listingViewBase = '/listing';
  static String listingView(String listingId) => '$listingViewBase/$listingId';
  static const String listingViewPattern = '$listingViewBase/:listingId';
  static const String sellerProfileBase = '/seller';
  static String sellerProfile(String sellerId) => '$sellerProfileBase/$sellerId';
  static const String sellerProfilePattern = '$sellerProfileBase/:sellerId';
  static const String notifications = '/notifications';
  static const String sell = '/sell';
  static const String sellDetails = '/sell/details';
  static const String sellPlan = '/sell/plan';
  static const String sellReview = '/sell/review';
  static const String sellSubmitted = '/sell/submitted';
}
