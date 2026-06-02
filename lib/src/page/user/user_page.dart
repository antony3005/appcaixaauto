import 'package:appcaixaauto/src/model/user_model.dart';
import 'package:appcaixaauto/src/service/UserService.dart';
import 'package:flutter/material.dart';

import '../../model/UserPreferences.dart';
import 'EditarPerfil.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  UserModel? user;

  Future<void> getUser() async {
    final a = await UserService().getCurrentUser();
    setState(() {
      user = a;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Meu Perfil"),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                'http://192.168.86.9:8080/files/${user!.foto}',
              ),
            ),

            const SizedBox(height: 16),

            Text(
              user!.nome,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(user!.email, style: TextStyle(color: Colors.grey.shade400)),

            const SizedBox(height: 30),

            _buildOption(Icons.person_outline, "Editar Perfil", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditarPerfil(
                    idUser: user!.userId,
                    fotoAtual: user!.foto,
                    nome: user!.nome,
                    sobrenome: user!.nomeCompleto,
                    email: user!.email,
                    telefone: user!.telefone,
                  ),
                ),
              );
            }),

            _buildOption(Icons.lock_outline, "Alterar Senha", () {}),

            _buildOption(Icons.history, "Histórico", () {}),

            _buildOption(Icons.location_on_outlined, "Endereços", () {}),

            _buildOption(Icons.notifications_outlined, "Notificações", () {}),

            _buildOption(Icons.help_outline, "Ajuda", () {}),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // logout
                },
                icon: const Icon(Icons.logout),
                label: const Text("Sair"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(IconData icon, String title, VoidCallback onTap) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}
