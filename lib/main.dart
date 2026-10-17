import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/core/config/app_config.dart';
import 'src/data/client_api_repository.dart';
import 'src/data/session_store.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');

  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  runApp(
    App247Client(
      repository: ClientApiRepository(config: config),
      sessionStore: SecureSessionStore(),
    ),
  );
}
