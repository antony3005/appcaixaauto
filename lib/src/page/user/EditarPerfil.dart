import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../service/UserService.dart';

class EditarPerfil extends StatefulWidget {
  final String idUser;
  final String? fotoAtual;
  final String nome;
  final String sobrenome;
  final String email;
  final String telefone;

  const EditarPerfil({
    super.key,
    required this.idUser,
    this.fotoAtual,
    required this.nome,
    required this.sobrenome,
    required this.email,
    required this.telefone,
  });

  @override
  State<EditarPerfil> createState() => _EditarPerfilState();
}

class _EditarPerfilState extends State<EditarPerfil> {
  final ImagePicker picker = ImagePicker();

  late TextEditingController nomeController;
  late TextEditingController sobrenomeController;
  late TextEditingController emailController;
  late TextEditingController telefoneController;

  File? fotoSelecionada;
  bool carregando = false;

  @override
  void initState() {
    super.initState();

    nomeController = TextEditingController(text: widget.nome);
    sobrenomeController = TextEditingController(text: widget.sobrenome);
    emailController = TextEditingController(text: widget.email);
    telefoneController = TextEditingController(text: widget.telefone);
  }

  @override
  void dispose() {
    nomeController.dispose();
    sobrenomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    super.dispose();
  }

  Future<void> selecionarFoto() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        fotoSelecionada = File(image.path);
      });
    }
  }

  Future<void> salvarPerfil() async {
    if (nomeController.text.trim().isEmpty) {
      throw Exception("Informe o nome");
    }

    if (emailController.text.trim().isEmpty) {
      throw Exception("Informe o email");
    }

    setState(() {
      carregando = true;
    });

    try {
      if (fotoSelecionada != null) {
        await UserService().enviarFoto(
          userId: widget.idUser,
          file: fotoSelecionada!,
        );
      }

      await UserService().atualizarUsuario(
        userId: widget.idUser,
        nome: nomeController.text.trim(),
        sobrenome: sobrenomeController.text.trim(),
        email: emailController.text.trim(),
        telefone: telefoneController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Perfil atualizado com sucesso")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imagem;

    if (fotoSelecionada != null) {
      imagem = FileImage(fotoSelecionada!);
    } else if (widget.fotoAtual != null && widget.fotoAtual!.isNotEmpty) {
      imagem = NetworkImage(
        'http://192.168.86.9:8080/files/${widget.fotoAtual}',
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Editar Perfil")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: imagem,
                  child: imagem == null
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: selecionarFoto,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            TextField(
              controller: nomeController,
              decoration: const InputDecoration(
                labelText: "Nome",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: sobrenomeController,
              decoration: const InputDecoration(
                labelText: "Sobrenome",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: telefoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Telefone",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: carregando ? null : salvarPerfil,
                child: carregando
                    ? const CircularProgressIndicator()
                    : const Text("Salvar Alterações"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
