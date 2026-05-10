import 'package:flutter/material.dart';

class CarrinhoCompra extends StatelessWidget {
  final String? session;

  const CarrinhoCompra({super.key, this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Seu Carrinho ')),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: SingleChildScrollView(child: Column(children: [Text("hi!!!")])),
      ),
      bottomSheet: Container(
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
