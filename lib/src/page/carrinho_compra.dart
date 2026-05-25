import 'dart:convert';
import 'package:appcaixaauto/src/model/UserPreferences.dart';
import 'package:appcaixaauto/src/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../Widget/car_item.dart';
import '../model/carrinho_model.dart';

class CarrinhoCompra extends StatefulWidget {
  final String? session;

  const CarrinhoCompra({super.key, this.session});

  @override
  State<CarrinhoCompra> createState() => _CarrinhoCompraState();
}

class _CarrinhoCompraState extends State<CarrinhoCompra> {
  Carrinho? carrinho;
  String? order_id;
  UserModel? user;
  late String? session = widget.session;

  // Variáveis de controle de estado
  bool isLoading = true;
  String? erroMensagem;

  @override
  void initState() {
    super.initState();
    getUser();
    if (session != null) {
      getCarrinho();
    } else {
      setState(() {
        isLoading = false;
        erroMensagem = "Sessão inválida ou não informada.";
      });
    }
  }

  Future<void> getUser() async {
    try {
      var us = await UserPreferences.getUser();
      setState(() {
        user = us;
      });
    } catch (e) {
      print('Erro ao buscar preferências do usuário: $e');
    }
  }

  Future<void> getOrder() async {
    if (carrinho == null || carrinho!.carrinhoId == null) {
      print("Carrinho inválido");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.86.7:8080/order?carrinho_id=${carrinho!.carrinhoId}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          order_id = data['orderId'];
        });
      } else {
        print("Erro ao criar order: ${response.statusCode}");
      }
    } catch (e) {
      print('Erro ao buscar order: $e');
    }
  }

  Future<void> getCarrinho() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.86.7:8080/checkout/session?idSession=$session',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          carrinho = Carrinho.fromJson(data);
          isLoading = false; // Sucesso: desativa o loading
        });
      } else {
        print('Erro no servidor: ${response.statusCode}');
        setState(() {
          isLoading = false;
          erroMensagem = "Erro ao carregar o carrinho (${response.statusCode})";
        });
      }
    } catch (e) {
      print('Erro ao buscar carrinho: $e');
      setState(() {
        isLoading = false;
        erroMensagem = "Não foi possível conectar ao servidor.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seu Carrinho'),
        backgroundColor: const Color(0xFF22D3EE),
      ),
      backgroundColor: const Color(0xFF0F172A),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              ) // Enquanto carrega a API
            : erroMensagem != null
            ? Center(
                child: Text(
                  erroMensagem!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              )
            : carrinho != null && carrinho!.items.isNotEmpty
            ? ListView.builder(
                itemCount: carrinho!.items.length,
                itemBuilder: (context, index) {
                  final item = carrinho!.items[index];
                  return carItem(item);
                },
              ) // Se carregar com sucesso e tiver itens
            : const Center(
                child: Text(
                  "Nenhum item encontrado no carrinho.",
                  style: TextStyle(color: Colors.white),
                ),
              ), // Se a lista vier vazia
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF0F172A),
        height: 80,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ElevatedButton(
                // Desabilita o botão temporariamente se o usuário ainda não foi carregado
                onPressed: user == null
                    ? null
                    : () async {
                        if (carrinho == null || carrinho!.carrinhoId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Carrinho inválido ou vazio!'),
                            ),
                          );
                          return;
                        }

                        if (user?.userId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Usuário não identificado. Faça login novamente.',
                              ),
                            ),
                          );
                          return;
                        }

                        try {
                          final response = await http.get(
                            Uri.parse(
                              'http://192.168.86.7:8080/pagamento/checkout?carrinho_id=${carrinho!.carrinhoId}&user_id=${user!.userId}',
                            ),
                            headers: {'Content-Type': 'application/json'},
                          );

                          if (response.statusCode == 200) {
                            final data = jsonDecode(response.body);

                            // CORREÇÃO AQUI: Mudado de 'url' para 'init_point'
                            if (data['init_point'] != null) {
                              String urlPagamento = data['init_point'];

                              if (await canLaunchUrl(Uri.parse(urlPagamento))) {
                                await launchUrl(
                                  Uri.parse(urlPagamento),
                                  mode: LaunchMode
                                      .externalApplication, // Abre no navegador padrão do celular
                                );
                              } else {
                                throw 'Não foi possível abrir a URL de pagamento.';
                              }
                            } else {
                              throw 'A resposta do servidor não enviou o campo init_point.';
                            }
                          }
                          if (response.statusCode == 200) {
                            final data = jsonDecode(response.body);

                            if (data['url'] != null) {
                              String urlPagamento = data['url'];

                              if (await canLaunchUrl(Uri.parse(urlPagamento))) {
                                await launchUrl(
                                  Uri.parse(urlPagamento),
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                throw 'Não foi possível abrir a URL de pagamento.';
                              }
                            } else {
                              throw 'A resposta do servidor não enviou uma URL válida.';
                            }
                          } else {
                            print("Erro no checkout: ${response.statusCode}");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Erro no servidor: ${response.statusCode}',
                                ),
                              ),
                            );
                          }
                          if (response.statusCode == 200) {
                            final data = jsonDecode(response.body);

                            if (data['url'] != null) {
                              String urlPagamento = data['url'];

                              if (await canLaunchUrl(Uri.parse(urlPagamento))) {
                                await launchUrl(
                                  Uri.parse(urlPagamento),
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                throw 'Não foi possível abrir a URL de pagamento.';
                              }
                            } else {
                              throw 'A resposta do servidor não enviou uma URL válida.';
                            }
                          } else {
                            print("Erro no checkout: ${response.statusCode}");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Erro no servidor: ${response.statusCode}',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          print('Erro ao gerar checkout: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro ao processar pagamento: $e'),
                            ),
                          );
                        }
                      },
                child: user == null
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black45,
                        ),
                      )
                    : const Text('Finalizar compra'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
