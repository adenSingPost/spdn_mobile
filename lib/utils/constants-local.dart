class Constants {
  // App Configuration
  static const String appId = 'SPDN';
  static const String apiKey = 'sk_spdn_7f8d9e2b4a1c3f6e9d8b5a2c4f7e9d8b';
  static const String middlewareUrl = 'https://7b779fa86014.ngrok-free.app';

  // Web Auth URLs - using localhost:4200
  static const String webAuthUrl = 'http://localhost:4200/auth';
  static const String webCallbackUrl = 'http://localhost:49514/auth/callback';
  static const String cleanUrl = 'http://localhost:49514/';
  
  // Google OAuth URLs (keeping for reference)
  static const String googleAuthUrl = '$middlewareUrl/auth/google';
  static const String googleCallbackUrl = '$middlewareUrl/auth/google/callback';
  
  // Encryption
  static const String secretKey = 'SPDN_SECRET_KEY_2024';
  static const String jwtSecret = 'ab5ee8974ca4dcefd7f55554102ac2e79e319be9f1c1e60330b4ac49f8759407b0ee458fefb0d26ec70b91021bbee742611c4dc45f55e3ee1541c029d430ec2b';
  
  // API URLs SPDN BACKEND
  static const String backendUrl = 'http://localhost:3000';
  // static const String backendUrl = 'https://uat.aksmobile.singpost.com/miniapp/spdn-qc-api';
}
