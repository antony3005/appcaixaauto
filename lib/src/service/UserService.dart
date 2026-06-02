import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../model/UserPreferences.dart';
import '../model/user_model.dart';

class UserService {
  final String url = "http://192.168.86.9:8080";

  Future<UserModel?> getCurrentUser() async {
    return await UserPreferences.getUser();
  }

  Future<String?> getProfilePhoto() async {
    final user = await UserPreferences.getUser();

    if (user == null || user.foto.isEmpty) {
      return null;
    }

    return '$url/files/${user.foto}';
  }

  Future<void> enviarFoto({required String userId, required File file}) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$url/user/foto?id=$userId'),
    );

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('Erro ao enviar foto (${response.statusCode})');
    }

    await atualizarUsuarioLocal();
  }

  Future<void> atualizarUsuario({
    required String userId,
    required String nome,
    required String sobrenome,
    required String email,
    required String telefone,
  }) async {
    final response = await http.put(
      Uri.parse('$url/user/$userId'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nome": nome,
        "sobrenome": sobrenome,
        "email": email,
        "telefone": telefone,
        "ativo": true,
        "condominioId": null,
      }),
    );

    if (response.statusCode != 200) {
      print(response.body);
      throw Exception("Erro ao atualizar usuário");
    }
  }

  Future<void> atualizarUsuarioLocal() async {
    final user = await UserPreferences.getUser();

    if (user == null) {
      throw Exception("Usuário não encontrado");
    }

    final response = await http.get(Uri.parse('$url/user?id=${user.userId}'));

    if (response.statusCode != 200) {
      throw Exception("Erro ao atualizar usuário");
    }

    final updatedUser = UserModel.fromJson(jsonDecode(response.body));

    updatedUser.token = user.token;

    await UserPreferences.saveUser(updatedUser);
  }
}
