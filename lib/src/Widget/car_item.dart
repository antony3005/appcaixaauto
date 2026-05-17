import 'package:flutter/material.dart';

import '../model/carrinho_model.dart';

Widget carItem(Item item, {VoidCallback? onAdd, VoidCallback? onRemove}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF1E1E1E),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          /// IMAGEM
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              'http://192.168.86.7:8080/files/${item.foto}',
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  width: 90,
                  height: 90,
                  color: Colors.grey.shade800,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.white54,
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 14),

          /// INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'R\$ ${item.unitPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                if (item.requiresWeight)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '${item.receivedWeight ?? 0} kg',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          /// CONTROLES
          Column(
            children: [
              IconButton(
                onPressed: onAdd,
                icon: const Icon(
                  Icons.add_circle,
                  color: Colors.greenAccent,
                  size: 30,
                ),
              ),

              Text(
                item.quantity.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              IconButton(
                onPressed: onRemove,
                icon: const Icon(
                  Icons.remove_circle,
                  color: Colors.redAccent,
                  size: 30,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
