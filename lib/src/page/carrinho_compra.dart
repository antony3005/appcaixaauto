import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../Widget/car_item.dart';
import '../model/carrinho_model.dart';

class CarrinhoCompra extends StatefulWidget {
  final String? session;

  const CarrinhoCompra({super.key, this.session});

  @override
  State<CarrinhoCompra> createState() => _CarrinhoCompraState();
}

class _CarrinhoCompraState extends State<CarrinhoCompra> {
  Carrinho? carrinho;
  late String? session = widget.session;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (session != null) {
      getCarrinho();
    }
  }

  Future<void> getCarrinho() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.86.7:8080/checkout/session?idSession=$session'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          carrinho = Carrinho.fromJson(data);
        });
      }

      print('Erro: ${response.statusCode}');
    } catch (e) {
      print('Erro ao buscar carrinho: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seu Carrinho '),
        backgroundColor: Color(0xFF22D3EE),
      ),
      backgroundColor: Color(0xFF0F172A),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: carrinho != null
            ? ListView.builder(
                itemCount: carrinho!.items.length,
                itemBuilder: (context, index) {
                  final item = carrinho!.items[index];

                  return carItem(item);
                },
              )
            : const Center(child: CircularProgressIndicator()),
      ),

      // 1. Trocamos bottomSheet por bottomNavigationBar
      bottomNavigationBar: Container(
        // 2. Adicionamos a MESMA cor do Scaffold para camuflar o Container
        color: Color(0xFF0F172A),
        height: 80,
        width: double.infinity,
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                child: Text('Finalizar compra'),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(onPressed: () {}, child: Text('compra')),
            ),
          ],
        ),
      ),
    );
  }
}
