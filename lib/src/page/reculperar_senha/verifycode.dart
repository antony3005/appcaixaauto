import 'dart:convert';

import 'package:appcaixaauto/src/page/reculperar_senha/newpassword_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../service/AuthService.dart';

class VerifyCodePage extends StatefulWidget {
  final String cpf;

  const VerifyCodePage({super.key, required this.cpf});

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  final codeController = TextEditingController();

  Future<void> verifyCode() async {
    try {
      final token = await AuthService().verifyCode(
        widget.cpf,
        codeController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Código válido")));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NewPasswordPage(cpf: widget.cpf, token: token),
        ),
      );
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
                  Icons.mark_email_read_outlined,
                  size: 90,
                  color: Color(0xFF22D3EE),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Verificar Código",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Digite o código enviado para seu e-mail.",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,

                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  letterSpacing: 8,
                ),

                textAlign: TextAlign.center,

                decoration: InputDecoration(
                  hintText: "000000",
                  hintStyle: const TextStyle(
                    color: Colors.white30,
                    letterSpacing: 8,
                  ),

                  filled: true,
                  fillColor: const Color(0xFF1E293B),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFF22D3EE)),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  onPressed: verifyCode,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22D3EE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),

                  child: const Text(
                    "Verificar",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
