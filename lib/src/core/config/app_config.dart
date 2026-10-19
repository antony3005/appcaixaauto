import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig({required this.apiBaseUrl, this.enableAllFeatures = false});

  factory AppConfig.fromEnvironment() {
    final configured = dotenv.get('API_BASE_URL', fallback: '');

    if (configured.trim().isEmpty) {
      throw StateError('API_BASE_URL não configurada no arquivo .env.');
    }

    final allFeatures = dotenv.get('APP_ALL_FEATURES', fallback: 'true');
    return AppConfig(
      apiBaseUrl: configured.trim(),
      enableAllFeatures: allFeatures.trim().toLowerCase() != 'false',
    );
  }

  final String apiBaseUrl;

  /// Liga todas as telas mesmo quando o `features` do bootstrap vem
  /// desligado. Use `APP_ALL_FEATURES=false` no `.env` para obedecer só ao
  /// servidor.
  final bool enableAllFeatures;
}
