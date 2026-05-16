import 'package:flutter/material.dart';

class CarrinhoCompra extends StatelessWidget {
  final String? session;

  const CarrinhoCompra({super.key, this.session});

  // 1. O componente do item foi corrigido para usar as variáveis passadas por parâmetro
  Widget carItem(String nome, String preco, String imagemUrl) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  // Usando a variável dinâmica da imagem aqui
                  image: NetworkImage(imagemUrl.isNotEmpty ? imagemUrl : "https://via.placeholder.com/80"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Usando a variável dinâmica do nome aqui
                  Text(
                    nome,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  // Usando a variável dinâmica do preço aqui
                  Text(
                    "R\$ $preco",
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                const Text("1"),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mn, vai substituir essa parte aqui pela parte do banco
    final List<Map<String, String>> itensDoCarrinho = [
      {
        "nome": "Notebook Gamer",
        "preco": "4.500,00",
        "imagem": "https://images.unsplash.com/photo-1603302576837-37561b2e2302?w=150"
      },
      {
        "nome": "Mouse Sem Fio",
        "preco": "150,00",
        "imagem": "https://images.unsplash.com/photo-1615663245857-ac93bb7c39e7?w=150"
      },
      {
        "nome": "Teclado Mecânico",
        "preco": "350,00",
        "imagem": "https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=150"
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seu Carrinho', style: TextStyle(color: Colors.black)),
        backgroundColor: const Color(0xFF22D3EE),
      ),
      backgroundColor: const Color(0xFF0F172A),
      // 2. Trocamos o SingleChildScrollView por um ListView.builder para renderizar a lista
      body: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: ListView.builder(
          itemCount: itensDoCarrinho.length,
          itemBuilder: (context, index) {
            final item = itensDoCarrinho[index];
            // 3. Aqui chamamos a sua função passando os dados de cada item
            return carItem(
              item["nome"]!,
              item["preco"]!,
              item["imagem"]!,
            );
          },
        ),
      ),

      bottomNavigationBar: Container(
        color: const Color(0xFF0F172A),
        height: 80,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Finalizar compra'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Continuar Comprando'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}