import 'dart:convert';

import 'package:appcaixaauto/src/page/login.dart';
import 'package:appcaixaauto/src/service/AuthService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  // ── Controllers ─────────────────────────────────────────
  final nomeController = TextEditingController();
  final sobrenomeController = TextEditingController(); // ✅ adicionado
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final cpfController = TextEditingController();
  final telefoneController = TextEditingController();
  final dataNascimentoController = TextEditingController(); // ✅ adicionado
  final codigoController = TextEditingController();

  bool codigoEnviado = false;
  bool validandoCodigo = false;

  final formKey = GlobalKey<FormState>();
  int currentStep = 0;

  static const _cyan = Color(0xFF22D3EE);
  static const _bg = Color(0xFF0F172A);
  static const _card = Color(0xFF1E293B);

  final _steps = const [
    {'label': 'Dados', 'icon': Icons.person_outline},
    {'label': 'Contato', 'icon': Icons.mail_outline},
    {'label': 'Verificação', 'icon': Icons.mark_email_read_outlined},
    {'label': 'Segurança', 'icon': Icons.lock_outline},
  ];

  // ── Validações ───────────────────────────────────────────
  bool validarCpf(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (cpf.length != 11) return false;
    if (RegExp(r'^(\d)\1*$').hasMatch(cpf)) return false;

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

  bool validarEtapaAtual() {
    void snack(String msg) => ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg)));

    switch (currentStep) {
      case 0:
        if (nomeController.text.trim().isEmpty) {
          snack("Informe seu nome");
          return false;
        }
        if (sobrenomeController.text.trim().isEmpty) {
          snack("Informe seu sobrenome");
          return false;
        }
        if (!validarCpf(cpfController.text)) {
          snack("CPF inválido");
          return false;
        }
        // ✅ Valida data de nascimento
        if (dataNascimentoController.text.trim().isEmpty) {
          snack("Informe sua data de nascimento");
          return false;
        }
        final partes = dataNascimentoController.text.split('/');
        if (partes.length != 3) {
          snack("Data inválida, use dd/MM/yyyy");
          return false;
        }
        try {
          final data = DateTime(
            int.parse(partes[2]),
            int.parse(partes[1]),
            int.parse(partes[0]),
          );
          if (data.isAfter(DateTime.now())) {
            snack("Data de nascimento inválida");
            return false;
          }
        } catch (_) {
          snack("Data inválida");
          return false;
        }
        return true;

      case 1:
        if (!RegExp(
          r'^[\w.-]+@[\w.-]+\.\w+$',
        ).hasMatch(emailController.text.trim())) {
          snack("E-mail inválido");
          return false;
        }
        if (telefoneController.text.replaceAll(RegExp(r'\D'), '').length < 10) {
          snack("Telefone inválido");
          return false;
        }
        return true;

      case 2:
        if (codigoController.text.isEmpty) {
          snack("Digite o código enviado para o e-mail");
          return false;
        }
        return true;

      case 3:
        if (senhaController.text.length < 6) {
          snack("A senha deve ter no mínimo 6 caracteres");
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  // ── Cadastro ─────────────────────────────────────────────

  // ── Navegação ─────────────────────────────────────────────
  Future<void> nextStep() async {
    if (!validarEtapaAtual()) return;

    if (currentStep == 1) {
      setState(() => validandoCodigo = true);
      try {
        await AuthService()
            .enviarCodigoEmail(emailController.text, nomeController.text)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () =>
                  throw Exception("Tempo esgotado. Verifique sua conexão."),
            );
        setState(() {
          codigoEnviado = true;
          validandoCodigo = false;
          currentStep++;
        });
      } catch (e) {
        setState(() => validandoCodigo = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
        );
      }
      return;
    }

    if (currentStep == 2) {
      setState(() => validandoCodigo = true);
      try {
        final valido = await AuthService()
            .validarCodigoEmail(
              emailController.text,
              codigoController.text,
              nomeController.text,
            )
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () =>
                  throw Exception("Tempo esgotado. Verifique sua conexão."),
            );
        setState(() => validandoCodigo = false);

        if (!valido) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Código inválido")));
          return;
        }
      } catch (e) {
        setState(() => validandoCodigo = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
        );
        return;
      }
    }

    if (currentStep < 3) {
      setState(() => currentStep++);
    } else {
      final erro = await AuthService().cadastrar(
        nome: nomeController.text,
        sobrenome: sobrenomeController.text,
        email: emailController.text,
        senha: senhaController.text,
        cpf: cpfController.text,
        telefone: telefoneController.text,
        dataNascimento: dataNascimentoController.text,
      );

      if (erro == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cadastro realizado com sucesso!")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(erro)));
      }
    }
  }

  void previousStep() {
    if (currentStep > 0) setState(() => currentStep--);
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Criar conta",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Etapa ${currentStep + 1} de 4 · ${_steps[currentStep]['label']}",
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stepper horizontal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: List.generate(_steps.length * 2 - 1, (i) {
                  if (i.isOdd) {
                    final stepIndex = i ~/ 2;
                    final done = currentStep > stepIndex;
                    return Expanded(
                      child: Container(
                        height: 2,
                        color: done ? _cyan : Colors.white12,
                      ),
                    );
                  }

                  final stepIndex = i ~/ 2;
                  final done = currentStep > stepIndex;
                  final active = currentStep == stepIndex;
                  final icon = _steps[stepIndex]['icon'] as IconData;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done
                          ? _cyan
                          : active
                          ? _cyan.withOpacity(0.15)
                          : _card,
                      border: Border.all(
                        color: done || active ? _cyan : Colors.white12,
                        width: active ? 2 : 1.5,
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: _cyan.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: done
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.black,
                              size: 18,
                            )
                          : Icon(
                              icon,
                              color: active ? _cyan : Colors.white30,
                              size: 18,
                            ),
                    ),
                  );
                }),
              ),
            ),

            // Labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_steps.length, (i) {
                  final active = currentStep == i;
                  final done = currentStep > i;
                  return Text(
                    _steps[i]['label'] as String,
                    style: TextStyle(
                      color: done || active ? _cyan : Colors.white30,
                      fontSize: 11,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }),
              ),
            ),

            // Conteúdo
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Form(
                  key: formKey,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) => SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: _buildStepContent(currentStep),
                  ),
                ),
              ),
            ),

            // Botões
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Row(
                children: [
                  if (currentStep > 0) ...[
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: previousStep,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _cyan),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Voltar",
                            style: TextStyle(color: _cyan),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: validandoCodigo
                            ? null
                            : () async => await nextStep(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _cyan,
                          disabledBackgroundColor: _cyan.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: validandoCodigo
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                currentStep == 3 ? "Cadastrar" : "Próximo",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        color: _bg,
        child: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "Já possui uma conta? Entrar",
            style: TextStyle(
              color: _cyan,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ── Step content ──────────────────────────────────────────
  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return Column(
          key: const ValueKey(0),
          children: [
            _buildTextField(
              label: "NOME",
              hint: "Primeiro nome",
              controller: nomeController,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: "SOBRENOME",
              hint: "Sobrenome",
              controller: sobrenomeController,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: "CPF",
              hint: "00000000000",
              controller: cpfController,
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              // ✅ Só dígitos — backend exige \d{11}
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: "DATA DE NASCIMENTO",
              hint: "dd/MM/yyyy",
              controller: dataNascimentoController,
              icon: Icons.cake_outlined,
              keyboardType: TextInputType.datetime,
              // ✅ Máscara manual simples dd/MM/yyyy
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
                _DateInputFormatter(),
              ],
            ),
          ],
        );

      case 1:
        return Column(
          key: const ValueKey(1),
          children: [
            _buildTextField(
              label: "E-MAIL",
              hint: "email@email.com",
              controller: emailController,
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: "TELEFONE",
              hint: "(75) 99999-9999",
              controller: telefoneController,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
          ],
        );

      case 2:
        return Column(
          key: const ValueKey(2),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _cyan.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mark_email_read_outlined, color: _cyan),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Enviamos um código para ${emailController.text}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: "CÓDIGO DE VERIFICAÇÃO",
              hint: "Digite o código recebido",
              controller: codigoController,
              icon: Icons.pin_outlined,
              keyboardType: TextInputType.number,
            ),
          ],
        );

      case 3:
        return Column(
          key: const ValueKey(3),
          children: [
            _buildTextField(
              label: "SENHA",
              hint: "Mínimo 6 caracteres",
              controller: senhaController,
              icon: Icons.lock_outline,
              isPassword: true,
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
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
            color: Colors.white54,
            fontWeight: FontWeight.w600,
            fontSize: 11,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: _card,
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            prefixIcon: Icon(icon, color: _cyan, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white10, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _cyan, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}

// ✅ Formatter para máscara dd/MM/yyyy
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(digits[i]);
    }

    final str = buffer.toString();
    return newValue.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}
