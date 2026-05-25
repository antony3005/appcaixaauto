import 'package:appcaixaauto/src/model/UserPreferences.dart';
import 'package:appcaixaauto/src/model/user_model.dart';
import 'package:flutter/material.dart';

class AppBarApp extends StatefulWidget implements PreferredSizeWidget {
  const AppBarApp({super.key});

  @override
  State<AppBarApp> createState() => _AppBarAppState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AppBarAppState extends State<AppBarApp> {
  UserModel? userModel;

  @override
  void initState() {
    super.initState();
    carregarUsuario();
  }

  Future<void> carregarUsuario() async {
    final user = await UserPreferences.getUser();

    setState(() {
      userModel = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0F172A),
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF22D3EE)),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF22D3EE),
            backgroundImage: userModel!.foto.isNotEmpty
                ? NetworkImage(userModel!.foto)
                : null,
            child: userModel!.foto.isEmpty
                ? const Icon(Icons.person, color: Colors.black)
                : null,
          ),
          const SizedBox(width: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Olá,",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(userModel!.nome,
                style: const TextStyle(
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
}
