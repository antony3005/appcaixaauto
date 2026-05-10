import 'package:appcaixaauto/src/page/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necessário para os formatadores
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 1. Controlador para o CPF
  final TextEditingController _cpfController = TextEditingController();

  // 2. Definição da Máscara
  final cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void dispose() {
    _cpfController.dispose(); // Boa prática: libera memória ao fechar a tela
    super.dispose();
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

              // Campo de CPF configurado corretamente
              _buildTextField(
                label: "CPF",
                hint: "000.000.000-00",
                controller: _cpfController,
                icon: Icons.badge,
                isPassword: false,
                keyboardType: TextInputType.number,
                // Abre teclado numérico
                inputFormatters: [cpfMask], // Aplica a máscara visual
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    String cpfLimpo = cpfMask.getUnmaskedText();

                    if (validarCpf(cpfLimpo)) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DashboardPage(),
                        ),
                      );
                    }
                    print("CPF digitado: ${_cpfController.text}");
                    print("CPF para enviar à API: $cpfLimpo");
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
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Não possui conta?",
                    style: TextStyle(color: Color(0xFF22D3EE), fontSize: 16),
                  ),
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
          // Aplica os formatadores aqui
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
