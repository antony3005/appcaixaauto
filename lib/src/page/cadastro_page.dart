import 'dart:convert';

import 'package:appcaixaauto/src/Widget/app_bar_app.dart';
import 'package:appcaixaauto/src/Widget/drawer_app.dart';
import 'package:appcaixaauto/src/page/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/masked_input_formatter.dart';
import 'package:http/http.dart' as http;

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final nomeController = TextEditingController();
  final sobrenomeController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final cpfController = TextEditingController();
  final telefoneController = TextEditingController();
  final dataNascimentoController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
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
      int digito2 = calcularDigito(
        cpf.substring(0, 9) + digito1.toString(),
        11,
      );

      return cpf.endsWith('$digito1$digito2');
    }

    Future<void> cadastrar() async {
      try {
        final response = await http.post(
          Uri.parse("http://192.168.86.7:8080/auth/register"),
          headers: {"Content-Type": "application/json"},

          body: jsonEncode({
            "nome": nomeController.text,
            "sobrenome": sobrenomeController.text,
            "email": emailController.text,
            "senha": senhaController.text,
            "cpf": cpfController.text,
            "telefone": telefoneController.text,
            "dataNascimento": dataNascimentoController.text,
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cadastro realizado com sucesso")),
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        } else {
          print(response.body);

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(response.body)));
        }
      } catch (e) {
        print(e);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),

          child: Form(
            key: formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),

                const Text(
                  "Cadastro",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Crie sua conta para continuar",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),

                const SizedBox(height: 40),

                _buildTextField(
                  label: "NOME",
                  hint: "Digite seu nome",
                  controller: nomeController,
                  icon: Icons.person_outline,
                ),

                const SizedBox(height: 15),

                _buildTextField(
                  label: "SOBRENOME",
                  hint: "Digite seu sobrenome",
                  controller: sobrenomeController,
                  icon: Icons.badge_outlined,
                ),

                const SizedBox(height: 15),

                _buildTextField(
                  label: "EMAIL",
                  hint: "email@email.com",
                  controller: emailController,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 15),

                _buildTextField(
                  label: "SENHA",
                  hint: "********",
                  controller: senhaController,
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),

                const SizedBox(height: 15),

                _buildTextField(
                  label: "CPF",
                  hint: "000.000.000-00",
                  controller: cpfController,
                  icon: Icons.credit_card,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 15),

                _buildTextField(
                  label: "TELEFONE",
                  hint: "(75) 99999-9999",
                  controller: telefoneController,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 15),

                _buildTextField(
                  label: "DATA DE NASCIMENTO",
                  hint: "13/05/2008",
                  controller: dataNascimentoController,
                  icon: Icons.calendar_month_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [MaskedInputFormatter('00/00/0000')],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    cadastrar();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22D3EE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "Cadastrar",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Já possui uma conta? Entrar",
                style: TextStyle(
                  color: Color(0xFF22D3EE),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

        TextFormField(
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
