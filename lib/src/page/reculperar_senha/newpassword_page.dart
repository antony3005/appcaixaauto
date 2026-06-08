import 'package:flutter/material.dart';

import '../../service/AuthService.dart';
import '../login.dart';

class NewPasswordPage extends StatefulWidget {
  final String cpf;
  final String token;

  const NewPasswordPage({super.key, required this.cpf, required this.token});

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final senhaController = TextEditingController();
  final confirmarController = TextEditingController();

  bool obscureSenha = true;
  bool obscureConfirmar = true;

  Widget campoSenha({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),

        filled: true,
        fillColor: const Color(0xFF1E293B),

        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF22D3EE)),

        suffixIcon: IconButton(
          onPressed: toggle,
          icon: Icon(
            obscure ? Icons.visibility : Icons.visibility_off,
            color: Colors.white54,
          ),
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF22D3EE)),
        ),
      ),
    );
  }

  Future<void> alterarSenha() async {
    try {
      await AuthService().alterarSenha(
        widget.cpf,
        widget.token,
        senhaController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Senha alterada com sucesso")),
      );

      Navigator.push(context, MaterialPageRoute(builder: (_) => LoginPage()));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Center(
                child: Icon(
                  Icons.lock_reset,
                  size: 90,
                  color: Color(0xFF22D3EE),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Nova Senha",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Defina uma nova senha para sua conta.",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),

              const SizedBox(height: 40),

              campoSenha(
                controller: senhaController,
                label: "Nova senha",
                obscure: obscureSenha,
                toggle: () {
                  setState(() {
                    obscureSenha = !obscureSenha;
                  });
                },
              ),

              const SizedBox(height: 20),

              campoSenha(
                controller: confirmarController,
                label: "Confirmar senha",
                obscure: obscureConfirmar,
                toggle: () {
                  setState(() {
                    obscureConfirmar = !obscureConfirmar;
                  });
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  onPressed: alterarSenha,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22D3EE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),

                  child: const Text(
                    "Salvar Nova Senha",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
