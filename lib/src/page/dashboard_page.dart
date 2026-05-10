import 'package:appcaixaauto/src/Widget/drawer_app.dart';
import 'package:flutter/material.dart';

import '../Widget/app_bar_app.dart';

class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarApp(),
      drawer: DrawerApp(),
      backgroundColor: Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

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
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
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
          height: 60,
          width: 60,
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
        Text(
          "Atividade Recente",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
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
          Text(
            value,
            style: TextStyle(color: valueColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
