import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/user_model.dart';

class UserPreferences {

  static const String userKey = "USER_DATA";

  static Future<void> saveUser(UserModel user) async {

    final prefs = await SharedPreferences.getInstance();

    String userJson = jsonEncode(user.toJson());

    await prefs.setString(userKey, userJson);
  }

  // PEGAR USUÁRIO
  static Future<UserModel?> getUser() async {

    final prefs = await SharedPreferences.getInstance();

    String? userJson = prefs.getString(userKey);

    if (userJson == null) {
      return null;
    }

    Map<String, dynamic> userMap = jsonDecode(userJson);

    return UserModel.fromJson(userMap);
  }

  // REMOVER USUÁRIO
  static Future<void> removeUser() async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(userKey);
  }

  // VERIFICAR SE ESTÁ LOGADO
  static Future<bool> isLogged() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.containsKey(userKey);
  }
}