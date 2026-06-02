import 'package:appcaixaauto/src/model/UserPreferences.dart';
import 'package:appcaixaauto/src/page/carrinho_compra.dart';
import 'package:appcaixaauto/src/page/dashboard_page.dart';
import 'package:appcaixaauto/src/page/login.dart';
import 'package:appcaixaauto/src/page/order_card.dart';
import 'package:flutter/material.dart';

import '../page/user/user_page.dart';

class DrawerApp extends StatefulWidget {
  const DrawerApp({super.key});

  @override
  State<DrawerApp> createState() => _DrawerAppState();
}

class _DrawerAppState extends State<DrawerApp> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            child: Column(
              children: [
                Expanded(
                  child: Image.asset(
                    'lib/src/content/app_logo.png',
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),

          _listTile(Icons.house_outlined, 'Home', DashboardPage()),
          _listTile(Icons.shopping_cart_outlined, 'Carrinho', CarrinhoCompra()),
          _listTile(Icons.shopping_bag, 'Meus pedidos', OrderPage()),
          _listTile(Icons.person, 'Meu perfil', UserPage()),

          Card(
            elevation: 0,
            color: Colors.grey.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.exit_to_app, color: Colors.white, size: 20),
              ),

              title: Text(
                'Sair',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),

              trailing: const Icon(Icons.arrow_forward_ios, size: 14),

              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage()),
                  (route) => false,
                );
                UserPreferences.removeUser();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _listTile(IconData icon, String nome, Widget page) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),

        title: Text(nome, style: const TextStyle(fontWeight: FontWeight.w600)),

        trailing: const Icon(Icons.arrow_forward_ios, size: 14),

        onTap: () {
          Navigator.pop(context);

          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        },
      ),
    );
  }
}
