/// Centralised environment configuration.
///
/// Override at build / run time with --dart-define:
///   flutter run \
///     --dart-define=API_BASE_URL=https://pps.macsoftautomations.in/api \
///     --dart-define=WS_BASE_URL=wss://pps.macsoftautomations.in
///
/// Defaults target the Android emulator loopback alias (10.0.2.2).
/// For a physical device replace 10.0.2.2 with your machine's LAN IP.

class Env {
  Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://192.168.1.61/api',
  );

  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'wss://192.168.1.61',
  );
}
