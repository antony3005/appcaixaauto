import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/produto_model.dart';

class HomeService {
  final String URL = "http://192.168.86.9:8080/produtos";

  Future<List<ProdutoModel>> getDestaques() async {
    try {
      final response = await http.get(
        Uri.parse('$URL/home'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List produtosJson = data["destaques"];

        return produtosJson.map((e) => ProdutoModel.fromJson(e)).toList();
      } else {
        throw Exception("Erro ao buscar produtos");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
