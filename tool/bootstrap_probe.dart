import 'dart:convert';
import 'dart:io';

import 'package:appcaixaauto/src/core/config/app_config.dart';
import 'package:appcaixaauto/src/data/client_api_repository.dart';
import 'package:http/http.dart' as http;

/// Mostra o que o `GET /app-cliente/bootstrap` real devolve, sem dados
/// pessoais: só as chaves do topo e o bloco de recursos.
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
  final base = apiUrl.endsWith('/')
      ? apiUrl.substring(0, apiUrl.length - 1)
      : apiUrl;
  final response = await http.get(
    Uri.parse('$base/app-cliente/bootstrap'),
    headers: {'Authorization': 'Bearer ${session.token}'},
  );
  stdout.writeln('status: ${response.statusCode}');
  final body = jsonDecode(utf8.decode(response.bodyBytes));
  if (body is! Map) {
    stdout.writeln('corpo não é um objeto: ${body.runtimeType}');
    return;
  }
  stdout.writeln('chaves do topo: ${body.keys.toList()}');
  for (final key in body.keys) {
    final value = body[key];
    if (key == 'user' || key == 'condominio') continue;
    stdout.writeln('$key: ${const JsonEncoder.withIndent('  ').convert(value)}');
  }
  final parsed = await repository.loadBootstrap(session);
  final c = parsed.capabilities;
  stdout.writeln(
    'o app entendeu: catalogo=${c.catalog} qr=${c.identificationQr} '
    'fidelidade=${c.loyalty} pontos=${c.points} cashback=${c.cashback} '
    'recompensas=${c.rewards} cupons=${c.coupons} '
    'preferencias=${c.preferences} suporte=${c.purchaseSupport}',
  );
}
