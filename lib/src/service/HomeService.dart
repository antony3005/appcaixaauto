import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../model/produto_model.dart';

class HomeService {
  final URL = dotenv.env['API_URL'];

  Future<List<ProdutoModel>> getDestaques() async {
    try {
      final response = await http.get(
        Uri.parse('$URL/produtos/home'),
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
