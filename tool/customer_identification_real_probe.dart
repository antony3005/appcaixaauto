import 'dart:io';

import 'package:appcaixaauto/src/core/config/app_config.dart';
import 'package:appcaixaauto/src/data/client_api_repository.dart';

Future<void> main() async {
  final apiUrl = Platform.environment['APP247_E2E_API_URL'];
  final cpf = Platform.environment['APP247_E2E_CPF'];
  final password = Platform.environment['APP247_E2E_PASSWORD'];
  if (apiUrl == null || cpf == null || password == null) {
    stderr.writeln('Variáveis APP247_E2E_* obrigatórias não configuradas.');
    exitCode = 2;
    return;
  }

  final repository = ClientApiRepository(config: AppConfig(apiBaseUrl: apiUrl));
  final session = await repository.login(cpf: cpf, password: password);
  stdout.writeln('[APP-QR-E2E] login JWT: OK');
  final bootstrap = await repository.loadBootstrap(session);
  if (!bootstrap.capabilities.identificationQr ||
      bootstrap.condominium == null) {
    throw StateError('Bootstrap não habilitou Meu QR');
  }
  stdout.writeln('[APP-QR-E2E] bootstrap habilita Meu QR: OK');
  final token = await repository.createIdentificationToken(session);
  if (!token.qrPayload.startsWith('app247://customer-link/') ||
      !token.expiresAt.isAfter(token.serverTime)) {
    throw StateError('Contrato do QR inválido');
  }
  stdout.writeln('[APP-QR-E2E] POST identification token: OK');
  stdout.writeln('[APP-QR-E2E] payload opaco e expiração válida: OK');
}
