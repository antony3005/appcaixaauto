import 'package:flutter/material.dart';

  // ignore: non_constant_identifier_names
  Widget CarItem(String nome, String preco, String imagemUrl) {
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
                  image: NetworkImage(""),
                  fit: BoxFit.cover,
                  )
              ),
            ),
            const SizedBox( width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("nome", style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold
                    ),
                    ),
                    const SizedBox(height: 5,),
                    Text("R\$ preço", style: const TextStyle(color: Colors.green),)
                ],
              ),
            ),
            Row(
              children: [
                IconButton(onPressed: (){}, icon: const Icon(Icons.remove_circle_outline)),
                Text("1"),
                IconButton(onPressed: () {}, icon: const Icon(Icons.add_circle_outline, color: Colors.blue)),
              ],
              )
          ],  
        )
        ),

    );
  }