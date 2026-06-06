import 'package:appcaixaauto/src/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../service/UserService.dart';

class AppBarApp extends StatefulWidget implements PreferredSizeWidget {
  const AppBarApp({super.key});

  @override
  State<AppBarApp> createState() => _AppBarAppState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AppBarAppState extends State<AppBarApp> {
  final url = dotenv.env['API_URL'];

  UserModel? userModel;

  @override
  void initState() {
    super.initState();
    carregarUsuario();
  }

  Future<void> carregarUsuario() async {
    final user = await UserService().getCurrentUser();

    if (!mounted) return;

    setState(() {
      userModel = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userModel == null) {
      return AppBar(
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Color(0xFF22D3EE)),
        title: const Text("Carregando..."),
      );
    }

    return AppBar(
      backgroundColor: const Color(0xFF0F172A),
      elevation: 0,
      iconTheme: const IconThemeData(color: Color(0xFF22D3EE)),
      title: Row(
        children: [
          userModel == null
              ? const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF22D3EE),
                  backgroundImage: userModel!.foto.isNotEmpty
                      ? NetworkImage('$url/files/${userModel!.foto}')
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
              Text(
                userModel?.nome ?? "Carregando...",
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
