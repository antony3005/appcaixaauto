import 'dart:convert';

import 'package:appcaixaauto/src/Widget/app_bar_app.dart';
import 'package:appcaixaauto/src/Widget/drawer_app.dart';
import 'package:appcaixaauto/src/Widget/product_card.dart';
import 'package:appcaixaauto/src/model/carrinho_model.dart';
import 'package:appcaixaauto/src/model/produto_model.dart';
import 'package:appcaixaauto/src/page/carrinho_compra.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  /// LISTA DE PRODUTOS
  List<Item> products = [
    Item(
      itemId: "1",
      carrinhoId: "10",
      productId: 1001,
      barcode: "789123456",
      name: "iPhone 15 Pro Max",
      foto: "iphone.jpg",
      unitPrice: 7999.90,
      quantity: 1,
      requiresWeight: false,
      expectedWeight: null,
      receivedWeight: null,
      status: ItemStatus.PENDING,
    ),

    Item(
      itemId: "2",
      carrinhoId: "10",
      productId: 1002,
      barcode: "789123457",
      name: "Notebook Gamer RTX",
      foto: "notebook.jpg",
      unitPrice: 5499.90,
      quantity: 1,
      requiresWeight: false,
      expectedWeight: null,
      receivedWeight: null,
      status: ItemStatus.VALIDATED,
    ),

    Item(
      itemId: "3",
      carrinhoId: "10",
      productId: 1003,
      barcode: "789123458",
      name: "Headset Gamer RGB",
      foto: "headset.jpg",
      unitPrice: 299.90,
      quantity: 1,
      requiresWeight: false,
      expectedWeight: null,
      receivedWeight: null,
      status: ItemStatus.CANCELED,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarApp(),

      drawer: DrawerApp(),

      backgroundColor: const Color(0xFF0F172A),

      floatingActionButton: Padding(
        padding: const EdgeInsets.all(10),

        child: FloatingActionButton(
          backgroundColor: const Color(0xFF22D3EE),

          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CarrinhoCompra()),
            );
          },

          child: const Icon(
            Icons.shopping_cart,
            color: Color.fromARGB(255, 1, 14, 58),
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              /// ESPAÇO
              const SizedBox(height: 20),

              /// CARD SALDO
              _buildBalanceCard(),

              const SizedBox(height: 30),

              /// AÇÕES RÁPIDAS
              _buildQuickActions(),

              const SizedBox(height: 35),

              /// PRODUTOS
              _buildProducts(),
            ],
          ),
        ),
      ),
    );
  }

  /// =========================
  /// CARD DE SALDO
  /// =========================
  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            "Saldo disponível",
            style: TextStyle(color: Colors.white70),
          ),

          const SizedBox(height: 8),

          const Text(
            "BRL 12.450,00",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// =========================
  /// AÇÕES RÁPIDAS
  /// =========================
  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [
        _actionItem(Icons.bolt, "Pix"),

        _actionItem(Icons.qr_code_scanner, "Pagar"),

        _actionItem(Icons.outbox, "Enviar"),

        _actionItem(Icons.add, "Depositar"),
      ],
    );
  }

  Widget _actionItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          height: 60,
          width: 60,

          decoration: BoxDecoration(
            color: const Color(0xFF22D3EE),
            borderRadius: BorderRadius.circular(15),
          ),

          child: Icon(icon, color: Colors.black),
        ),

        const SizedBox(height: 8),

        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Future<List<ProdutoModel>> getDestaques() async {
    try {
      final response = await http.get(
        Uri.parse("http://192.168.86.7:8080/produtos/home"),
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

  Widget _buildProducts() {
    return FutureBuilder<List<ProdutoModel>>(
      future: getDestaques(),

      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              snapshot.error.toString(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "Nenhum produto encontrado",
            ),
          );
        }

        final produtos = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: produtos.length,

          itemBuilder: (context, index) {
            return productCard(produtos[index]);
          },
        );
      },
    );
  }}
