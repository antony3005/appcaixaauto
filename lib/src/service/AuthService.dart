import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../model/UserPreferences.dart';
import '../model/user_model.dart';

class AuthService {
  final URL = dotenv.env['API_URL'];

  Future<void> login(String cpf, String senha) async {
    try {
      final response = await http.post(
        Uri.parse("$URL/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"cpf": cpf, "senha": senha}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        UserModel user = UserModel.fromJson(data["user"]);

        user.token = data["token"];

        await UserPreferences.saveUser(user);

        return;
      }

      throw Exception(data["message"] ?? "Erro ao realizar login");
    } on SocketException {
      throw Exception("Sem conexão com a internet");
    } on FormatException {
      throw Exception("Resposta inválida do servidor");
    } catch (e) {
      rethrow;
    }
  }

  Future<void> genareteCode(String cpf) async {
    try {
      final response = await http.post(
        Uri.parse("$URL/user/recuperar"),
        headers: {"Content-Type": "application/json"},

        body: jsonEncode({"cpf": cpf}),
      );

      if (response.statusCode == 200) {
        return;
      }
      throw Exception("Erro");
    } on SocketException {
      throw Exception("Sem conexão com a internet");
    } on FormatException {
      throw Exception("Resposta inválida do servidor");
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> cadastrar({
    required String nome,
    required String sobrenome,
    required String email,
    required String senha,
    required String cpf,
    required String telefone,
    required String dataNascimento,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$URL/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nome": nome.trim(),
          "sobrenome": sobrenome.trim(),
          "email": email.trim(),
          "senha": senha,
          "cpf": cpf.replaceAll(RegExp(r'\D'), ''),
          "telefone": telefone,
          "dataNascimento": dataNascimento,
        }),
      );

      if (response.statusCode == 200) {
        return null; // sucesso
      }

      return response.body; // erro da API
    } catch (e) {
      return e.toString();
    }
  }
  Future<String> verifyCode(String cpf, String code) async {
    try {
      final response = await http.post(
        Uri.parse("$URL/user/validar"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"cpf": cpf, "code": code}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data["token"];
      }

      throw Exception(data["message"] ?? "Código inválido");
    } on SocketException {
      throw Exception("Sem conexão com a internet");
    } on FormatException {
      throw Exception("Resposta inválida do servidor");
    }
  }

  Future<void> alterarSenha(String cpf, String token, String senha) async {
    try {
      final response = await http.post(
        Uri.parse("$URL/user/redefinir-senha"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"cpf": cpf, "token": token, "novaSenha": senha}),
      );

      if (response.statusCode == 200) {
        return;
      }
      throw Exception("Código inválido");
    } on SocketException {
      throw Exception("Sem conexão com a internet");
    } on FormatException {
      throw Exception("Resposta inválida do servidor");
    }
  }

  Future<bool> enviarCodigoEmail(String email, String nome) async {
    try {
      final response = await http.post(
        Uri.parse("$URL/auth/send-code"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "nome": nome}),
      );
      print(response.body);
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> validarCodigoEmail(
    String email,
    String code,
    String nome,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$URL/auth/validate-code"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "code": code, "nome": nome}),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
