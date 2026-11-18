/// Compile-time configuration.
///
/// Override the API base URL with:
/// `flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1`
class AppConfig {
  const AppConfig._();

  /// Defaults to the Android emulator alias for the host machine.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api/v1',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
