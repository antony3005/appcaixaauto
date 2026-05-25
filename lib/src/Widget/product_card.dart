import 'package:flutter/material.dart';

import '../model/produto_model.dart';

Widget productCard(ProdutoModel produto) {
  return Container(
    margin: const EdgeInsets.only(bottom: 18),
    decoration: BoxDecoration(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(20),
    ),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),

          child: Image.network(
            'http://192.168.86.7:8080/files/${produto.foto}',

            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,

            errorBuilder: (_, _, _) {
              return Container(
                height: 180,
                color: Colors.grey.shade800,

                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.white54,
                    size: 40,
                  ),
                ),
              );
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(14),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                produto.nome,

                maxLines: 2,
                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                produto.descricao,

                maxLines: 2,
                overflow: TextOverflow.ellipsis,

                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  Text(
                    "R\$ ${produto.preco.toStringAsFixed(2)}",

                    style: const TextStyle(
                      color: Color(0xFF22D3EE),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),

                    decoration: BoxDecoration(
                      color: produto.status ? Colors.green : Colors.red,

                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Text(
                      produto.status ? "Disponível" : "Indisponível",

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
