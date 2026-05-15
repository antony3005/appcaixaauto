import 'package:flutter/material.dart';

class CarrinhoCompra extends StatelessWidget {
  final String? session;

  const CarrinhoCompra({super.key, this.session});

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
        child: SingleChildScrollView(
          child: Column(children: [Text("hi!!!", style: TextStyle(color: Colors.white))])
        ),
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
              child: ElevatedButton(
                onPressed: () {}, 
                child: Text('compra')
              ),
            ),
          ],
        ),
      ),
    );
  }
}