import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  factory AppConfig.fromEnvironment() {
    final configured = dotenv.get('API_BASE_URL', fallback: '');

    if (configured.trim().isEmpty) {
      throw StateError('API_BASE_URL não configurada no arquivo .env.');
    }

    return AppConfig(apiBaseUrl: configured.trim());
  }

  final String apiBaseUrl;
}
