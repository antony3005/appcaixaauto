import 'dart:convert';

import 'package:appcaixaauto/src/Widget/app_bar_app.dart';
import 'package:appcaixaauto/src/Widget/drawer_app.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../model/order_model.dart';

class ResponsePayment extends StatefulWidget {
  final String link;
  final String idOrder;

  const ResponsePayment({super.key, required this.link, required this.idOrder});

  @override
  State<ResponsePayment> createState() => _ResponsePaymentState();
}

class _ResponsePaymentState extends State<ResponsePayment> {
  late String link = widget.link;
  late String idOrder = widget.idOrder;
  OrderModel? order;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getOrder();
  }

  Future<void> getOrder() async {
    try {
      final response = await http.get(
        Uri.parse("http://192.168.86.7:8080/order?carrinho_id=$idOrder"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          order = OrderModel.fromJson(data);
        });
      } else {
        throw Exception("Erro ao buscar produtos");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarApp(),
      drawer: DrawerApp(),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Column(children: [Text('Seu pedido Nº #')]),
        ),
      ),
      // body: link == "success"
      //     ? const Center(child: Text("Pagamento aprovado"))
      //     : const Center(child: Text("Aguardando pagamento")),
    );
  }

  Widget _success() {
    return Card();
  }

  Widget failure() {
    return Card();
  }
}
