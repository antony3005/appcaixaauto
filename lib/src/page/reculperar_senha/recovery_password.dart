import 'dart:convert';

import 'package:appcaixaauto/src/page/reculperar_senha/verifycode.dart';
import 'package:appcaixaauto/src/service/AuthService.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RecoveryPassword extends StatefulWidget {
  const RecoveryPassword({super.key});

  @override
  State<RecoveryPassword> createState() => _RecoveryPasswordState();
}

class _RecoveryPasswordState extends State<RecoveryPassword> {
  final cpfController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              const Center(
                child: Icon(
                  Icons.lock_reset_rounded,
                  size: 90,
                  color: Color(0xFF22D3EE),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Recuperar Senha",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Informe seu CPF para receber um código de recuperação.",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),

              const SizedBox(height: 40),

              TextField(
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,

                controller: cpfController,
                decoration: InputDecoration(
                  labelText: "CPF",
                  labelStyle: const TextStyle(color: Colors.white70),

                  hintText: "000.000.000-00",
                  hintStyle: const TextStyle(color: Colors.white30),

                  filled: true,
                  fillColor: const Color(0xFF1E293B),

                  prefixIcon: const Icon(
                    Icons.badge_outlined,
                    color: Color(0xFF22D3EE),
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
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  onPressed: () {
                    try {
                      AuthService().genareteCode(cpfController.text);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Codigo enviado ao seu email"),
                        ),
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              VerifyCodePage(cpf: cpfController.text),
                        ),
                      );
                    } catch (e) {
                      rethrow;
                    }
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22D3EE),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),

                  child: const Text(
                    "Enviar Código",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },

                  child: const Text(
                    "Voltar para o login",
                    style: TextStyle(color: Color(0xFF22D3EE), fontSize: 15),
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
