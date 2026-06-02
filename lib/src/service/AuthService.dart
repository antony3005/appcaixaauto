import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../model/UserPreferences.dart';
import '../model/user_model.dart';

class AuthService {
  final String URL = "http://192.168.86.9:8080";

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
        Uri.parse("http://192.168.86.9:8080/user/recuperar"),
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
        Uri.parse("http://192.168.86.9:8080/user/redefinir-senha"),
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
}
