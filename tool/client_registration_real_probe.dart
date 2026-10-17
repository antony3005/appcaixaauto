import 'dart:io';

import 'package:appcaixaauto/src/core/config/app_config.dart';
import 'package:appcaixaauto/src/data/client_api_repository.dart';
import 'package:appcaixaauto/src/domain/client_registration.dart';
import 'package:appcaixaauto/src/domain/models.dart';

Future<void> main(List<String> args) async {
  if (args.length != 5) {
    throw ArgumentError(
      'Uso: <api-url> <cpf-principal> <cpf-secundario> <email> <senha>',
    );
  }
  final repository = ClientApiRepository(
    config: AppConfig(apiBaseUrl: args[0]),
  );
  final request = ClientRegistrationRequest(
    firstName: 'Cliente',
    lastName: 'E2E',
    cpf: args[1],
    email: args[3],
    phone: '',
    password: args[4],
  );

  await repository.registerClient(request);
  stdout.writeln('REGISTER: PASS');

  final session = await repository.login(cpf: args[1], password: args[4]);
  stdout.writeln('LOGIN: PASS');

  try {
    await repository.loadBootstrap(session);
    throw StateError('Bootstrap aceitou conta global sem tenant');
  } on AppException catch (error) {
    if (error.code != 'TENANT_LINK_REQUIRED') rethrow;
    stdout.writeln('ACCOUNT_WITHOUT_TENANT: PASS');
  }

  try {
    await repository.registerClient(request);
    throw StateError('CPF duplicado foi aceito');
  } on RegistrationException catch (error) {
    if (error.code != 'CPF_ALREADY_REGISTERED') rethrow;
    stdout.writeln('DUPLICATE_CPF: PASS');
  }

  try {
    await repository.registerClient(
      ClientRegistrationRequest(
        firstName: 'Outro',
        lastName: 'Cliente',
        cpf: args[2],
        email: args[3],
        phone: '',
        password: args[4],
      ),
    );
    throw StateError('E-mail duplicado foi aceito');
  } on RegistrationException catch (error) {
    if (error.code != 'EMAIL_ALREADY_REGISTERED') rethrow;
    stdout.writeln('DUPLICATE_EMAIL: PASS');
  }
}
