class AppConfig {
  static const String apiBase = 'https://medika-ffqkww.v2.appdeploy.ai';
  static const String companyName = 'MEDIKA';
  static const String supportPhone = '+992880000086';

  static Uri endpoint(String path) => Uri.parse('$apiBase$path');
}
