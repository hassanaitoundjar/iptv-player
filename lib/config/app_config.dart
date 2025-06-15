class AppConfig {
  // Base URL for the web portal
  static const String webBaseUrl = 'http://localhost:8000';

  // Base URL for the API
  // Change this to your production URL when deploying
  static const String apiBaseUrl = 'http://localhost:8000';

  // For local development, uncomment this line and comment the line above
  // static const String apiBaseUrl = 'http://localhost:8000';

  // App name
  static const String appName = 'IPTV Player';

  // App version
  static const String appVersion = '1.0.7';

  // Polling interval for checking activation status (in seconds)
  static const int activationPollingInterval = 5;
}
