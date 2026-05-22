import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          Uri.parse("http://10.0.2.2:8080/auth/register"),
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
      appBar: AppBar(title: const Text("Cadastro")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Form(
          key: formKey,

          child: Column(
            children: [
              TextFormField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: "Nome",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Informe o nome";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: sobrenomeController,
                decoration: const InputDecoration(
                  labelText: "Sobrenome",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Informe o sobrenome";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Informe o email";
                  }

                  if (!value.contains("@")) {
                    return "Email inválido";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: senhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Senha",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Informe a senha";
                  }

                  if (value.length < 6) {
                    return "Senha deve ter no mínimo 6 caracteres";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: cpfController,
                keyboardType: TextInputType.number,
                maxLength: 11,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: "CPF",
                  border: OutlineInputBorder(),
                  counterText: "",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Informe o CPF";
                  }

                  if (value.length != 11) {
                    return "CPF deve conter 11 dígitos";
                  }
                  if (!validarCpf(cpfController.text)) {
                    return "Cpf precisa ser valido";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: telefoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Telefone",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: dataNascimentoController,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: "Data de nascimento",
                  hintText: "dd/MM/yyyy",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,

                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      cadastrar();
                    }
                  },

                  child: const Text("Cadastrar"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
