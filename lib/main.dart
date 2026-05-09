import 'package:appcaixaauto/confirma%C3%A7ao.dart';
import 'package:appcaixaauto/login.dart';
import 'package:flutter/material.dart';
void main() => runApp(MyApp());
class MyApp extends StatelessWidget {
  const MyApp({super.key});

 @override
 Widget build(BuildContext context) {
 return MaterialApp(
 title: 'Flutter Demo',
 theme: ThemeData(primarySwatch: Colors.blue),
 home: LoginPage(),
 );
 }
}

class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F172A), // O tom de azul escuro que vimos
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 25),
              _buildBalanceCard(),
              SizedBox(height: 25),
              _buildQuickActions(),
              SizedBox(height: 30),
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFF22D3EE),
              child: Icon(Icons.person, color: Colors.black),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Olá,", style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text("Dev Flutter", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.white70),
          onPressed: () {}, // Ação ao clicar no sino
        ),
      ],
    );
  }
  Widget _buildBalanceCard() {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Saldo disponível", style: TextStyle(color: Colors.white70)),
        SizedBox(height: 8),
        Text(
          "BRL 12.450,00",
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
  Widget _buildQuickActions() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _actionItem(Icons.bolt, "Pix"),
      _actionItem(Icons.qr_code_scanner, "Pagar"),
      _actionItem(Icons.outbox, "Enviar"),
      _actionItem(Icons.add, "Depositar"),
    ],
  );
}

Widget _actionItem(IconData icon, String label) {
  return Column(
    children: [
      Container(
        height: 60, width: 60,
        decoration: BoxDecoration(
          color: Color(0xFF22D3EE),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, color: Colors.black),
      ),
      SizedBox(height: 8),
      Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
    ],
  );
}
Widget _buildRecentActivity() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text("Atividade Recente", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      SizedBox(height: 15),
      _transactionTile("Supermercado", "- BRL 89,00", Colors.redAccent),
      _transactionTile("Pix Recebido", "+ BRL 250,00", Color(0xFF22D3EE)),
    ],
  );
}

Widget _transactionTile(String title, String value, Color valueColor) {
  return Container(
    margin: EdgeInsets.only(bottom: 12),
    padding: EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.02),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: Colors.white)),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

}