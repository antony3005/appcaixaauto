import 'dart:convert';

import 'package:appcaixaauto/src/model/user_model.dart';
import 'package:appcaixaauto/src/page/cadastro_page.dart';
import 'package:appcaixaauto/src/page/reculperar_senha/recovery_password.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../model/UserPreferences.dart';
import '../service/AuthService.dart';
import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  bool isLogged = false;

  final cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void dispose() {
    _cpfController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    bool i = await UserPreferences.isLogged();

    setState(() {
      isLogged = i;
    });

    if (isLogged) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardPage()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Login",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Faça login com seu CPF para continuar",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 40),

              _buildTextField(
                label: "CPF",
                hint: "000.000.000-00",
                controller: _cpfController,
                icon: Icons.badge,
                isPassword: false,
                keyboardType: TextInputType.number,
                inputFormatters: [cpfMask],
              ),
              const SizedBox(height: 10),
              _buildTextField(
                label: "SENHA",
                hint: "***",
                controller: _senhaController,
                icon: Icons.password,
                isPassword: true,
                keyboardType: TextInputType.visiblePassword,
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                    onPressed: () async {
                      if (_cpfController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Informe o CPF"),
                          ),
                        );
                        return;
                      }

                      if (_senhaController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Informe a senha"),
                          ),
                        );
                        return;
                      }

                      String cpfLimpo = cpfMask.getUnmaskedText();

                      if (!validarCpf(cpfLimpo)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("CPF inválido"),
                          ),
                        );
                        return;
                      }

                      try {
                        await AuthService().login(
                          cpfLimpo,
                          _senhaController.text,
                        );

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DashboardPage(),
                          ),
                        );

                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red.shade700,
                            behavior: SnackBarBehavior.floating,
                            content: Text(
                              e.toString().replaceFirst("Exception: ", ""),
                            ),
                          ),
                        );
                      }
                    },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22D3EE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "Entrar",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecoveryPassword(),
                          ),
                        );
                      },
                      child: const Text(
                        "Esqueceu a sua senha?",
                        style: TextStyle(
                          color: Color(0xFF22D3EE),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CadastroPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "Não possui conta?",
                        style: TextStyle(
                          color: Color(0xFF22D3EE),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool validarCpf(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');

    if (cpf.length != 11) {
      return false;
    }

    if (RegExp(r'^(\d)\1*$').hasMatch(cpf)) {
      return false;
    }

    int calcularDigito(String cpfParcial, int pesoInicial) {
      int soma = 0;

      for (int i = 0; i < cpfParcial.length; i++) {
        soma += int.parse(cpfParcial[i]) * (pesoInicial - i);
      }

      int resto = soma % 11;

      return resto < 2 ? 0 : 11 - resto;
    }

    int digito1 = calcularDigito(cpf.substring(0, 9), 10);
    int digito2 = calcularDigito(cpf.substring(0, 9) + digito1.toString(), 11);

    return cpf.endsWith('$digito1$digito2');
  }


  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1E293B),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30),
            prefixIcon: Icon(icon, color: const Color(0xFF22D3EE)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFF22D3EE), width: 1),
            ),
          ),
        ),
      ],
    );
  }
}
