import 'package:flutter/material.dart';
import '../model/carrinho_model.dart';

Widget productCard(Item item){
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
          borderRadius: BorderRadiusGeometry.vertical(
            top: Radius.circular(20),
          ),
          child: Image.network(
            'http://10.0.2.2:8080/files/${item.foto}',
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,

            errorBuilder: (_, _, _){
              return Container(
                height: 180,
                color: Colors.grey.shade800,
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.white54,
                    size: 40,
                  ),
                )
              );
            },
          ),
        ),
        Padding(padding: const EdgeInsets.all(14),
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
                fontWeight: FontWeight.w600,
              ),
            )
          ],
          ),
        )
      ],
    )
  );
}