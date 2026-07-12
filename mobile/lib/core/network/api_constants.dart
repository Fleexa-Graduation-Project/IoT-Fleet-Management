enum AppEnvironment { mock, dev, prod }

class ApiConstants {
  static const AppEnvironment currentEnv = AppEnvironment.dev;

  static String get baseUrl {
    switch (currentEnv) {
      case AppEnvironment.mock:
        return 'https://a942c4cd-805c-44de-af59-f61d99e769ac.mock.pstmn.io/api/v1';
      case AppEnvironment.dev:
        return 'https://9qqg9f27h7.execute-api.us-east-1.amazonaws.com/api/v1';
      case AppEnvironment.prod:
        return 'https://api.fleexa.com/api/v1';
    }
  }

  // AWS API Key (If DevOps requires it)
  static const String awsApiKey = 'YOUR_AWS_API_KEY_HERE';

  // System & Device Endpoints
  static const String systemOverview = "/system/overview";
  static const String devices = "/devices";
  static const String allAlerts = "/alerts";
  static String deviceDetails(String id) => "/devices/$id";
  static String deviceTelemetry(String id) => "/devices/$id/telemetry";
  static String deviceAlerts(String id) => "/devices/$id/alerts";
  static String deviceCommands(String id) => "/devices/$id/commands";
  static const String markAlertRead = "/alerts/read";

  // Authentication Endpoints
  static const String signIn = "/auth/signin";
  static const String signUp = "/auth/signup";
  static const String forgotPassword = "/auth/forgot-password";
  static const String resetPassword = "/auth/reset-password";
  static const String changePassword = "/auth/change-password";
  static const String profile = "/auth/profile";

  // Preferences Endpoint
  static const String userPreferences = "/users/preferences";
  static String devicePreferences(String id) => "/devices/$id/preferences";
}
