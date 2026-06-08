import 'dart:convert';
import 'package:appcaixaauto/src/Widget/app_bar_app.dart';
import 'package:appcaixaauto/src/Widget/drawer_app.dart';
import 'package:appcaixaauto/src/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../model/UserPreferences.dart';
import '../model/order_model.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  UserModel? user;
  List<OrderModel> orders = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getUser();
    getOrders();
  }

  Future<void> getUser() async {
    UserModel? user = await UserPreferences.getUser();
    setState(() {
      this.user = user;
    });
  }

  Future<void> getOrders() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.86.7:8080/users/${user!.userId}/orders'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List orderJson = data["content"];

        setState(() {
          orders = orderJson.map((e) => OrderModel.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print("Erro ao buscar orders: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Erro ao buscar order: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBarApp(),
      drawer: DrawerApp(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Nenhum pedido encontrado",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];

                return Card(
                  color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      "Pedido #${order.orderId.substring(0, 8)}",
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      "Total: R\$ ${order.total}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Text(
                      order.status,
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
