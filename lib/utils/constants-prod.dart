class Constants {
  // App Configuration
  static const String appId = 'SPDN';
  static const String apiKey = 'sk_spdn_7f8d9e2b4a1c3f6e9d8b5a2c4f7e9d8b';
  static const String middlewareUrl = 'https://login.singpost.com/one-login/api/auth';

  // Web Auth URLs - using localhost:4200
  static const String webAuthUrl = 'https://login.singpost.com/auth';
  static const String webCallbackUrl = 'spdn://auth/callback';
  static const String cleanUrl = '';
  
  // Google OAuth URLs (keeping for reference)
  static const String googleAuthUrl = '$middlewareUrl/auth/google';
  static const String googleCallbackUrl = '$middlewareUrl/auth/google/callback';
  
  // Encryption
  static const String secretKey = 'SPDN_SECRET_KEY_2024';
  
  // API URLs SPDN BACKEND
  // static const String backendUrl = 'http://localhost:3000';
  static const String backendUrl = 'https://aksmobile.singpost.com/miniapp/spdn-qc-api';
}
