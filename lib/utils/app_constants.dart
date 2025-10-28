class AppConstants {
  // API Base URL - Flask sunucunuzun adresi
  //static const String baseUrl = 'http://192.168.74.15:1519/'; // Geliştirme için
  static const String baseUrl = 'https://reevpoints.tr/'; // Production için

  // API Endpoints
  static const String loginEndpoint = '/api/login';
  static const String registerEndpoint = '/api/register';
  static const String dashboardEndpoint = '/api/dashboard';
  static const String campaignsEndpoint = '/api/campaigns';
  static const String redeemEndpoint = '/api/redeem';
  static const String approveProductEndpoint = '/api/approve-product';
  static const String generateQrEndpoint = '/api/generate-qr';
  static const String scanQrEndpoint = '/api/scan-qr';
  static const String saveCustomerQrEndpoint = '/api/save-customer-qr';
  static const String profileEndpoint = '/api/profile';
  static const String messagesEndpoint = '/api/messages';
  static const String transactionHistoryEndpoint = '/api/transaction-history';
  static const String purchaseHistoryEndpoint = '/api/purchase-history';
  static const String rateProductEndpoint = '/api/rate-product';
  static const String splashImageEndpoint = '/api/splash-image';
  static const String changePasswordEndpoint = '/api/change-password';
  static const String activeSurveysEndpoint = '/api/surveys/active';
  static const String submitSurveyEndpoint = '/api/surveys';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String languageKey = 'selected_language';
  static const String favoriteProductKey = 'favorite_product';

  // App Info
  static const String appName = 'REEV POINTS';
  static const String appVersion = '1.0.0';

  // QR Code Settings
  static const int qrCodeSize = 200;
  static const Duration qrCodeExpiry = Duration(minutes: 5);

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 300);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration longAnimation = Duration(milliseconds: 800);

  // Supported Languages
  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
  ];
}
