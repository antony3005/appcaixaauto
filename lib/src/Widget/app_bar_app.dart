import 'package:flutter/material.dart';

class AppBarApp extends StatelessWidget implements PreferredSizeWidget {
  const AppBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0F172A),
      elevation: 0,

      title: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF22D3EE),
            child: Icon(Icons.person, color: Colors.black),
          ),
          const SizedBox(width: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Olá,",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                "Dev Flutter",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),

      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.white70),
          onPressed: () {},
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}