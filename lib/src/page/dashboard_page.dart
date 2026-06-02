import 'package:appcaixaauto/src/Widget/app_bar_app.dart';
import 'package:appcaixaauto/src/Widget/drawer_app.dart';
import 'package:appcaixaauto/src/model/produto_model.dart';
import 'package:appcaixaauto/src/service/HomeService.dart';
import 'package:flutter/material.dart';

import '../service/ScannerPage.dart';
import 'carrinho_compra.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<List<ProdutoModel>> _produtosFuture;
  int _categoriaAtiva = 0;

  final List<Map<String, dynamic>> _categorias = [
    {'label': 'Todos', 'icon': Icons.grid_view_rounded},
    {'label': 'Mercado', 'icon': Icons.store_rounded},
    {'label': 'Bebidas', 'icon': Icons.local_drink_rounded},
    {'label': 'Carnes', 'icon': Icons.set_meal_rounded},
    {'label': 'Limpeza', 'icon': Icons.cleaning_services_rounded},
    {'label': 'Padaria', 'icon': Icons.bakery_dining_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _produtosFuture = HomeService().getDestaques();
  }

  Future<void> _refresh() async {
    setState(() => _produtosFuture = HomeService().getDestaques());
    await _produtosFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBarApp(),
      drawer: DrawerApp(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF22D3EE),
        onPressed: () async {
          final result = await Navigator.push<String>(
            context,
            MaterialPageRoute(builder: (_) => ScannerPage()),
          );

          if (result != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CarrinhoCompra(session: result),
              ),
            );
          }
        },
        child: Icon(Icons.qr_code_scanner_sharp, color: Colors.black, size: 24),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF22D3EE),
        backgroundColor: const Color(0xFF1E293B),
        onRefresh: _refresh,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(),
                const SizedBox(height: 20),
                _buildSearch(),
                const SizedBox(height: 24),
                _buildSectionTitle('Categorias'),
                const SizedBox(height: 12),
                _buildCategories(),
                const SizedBox(height: 24),
                _buildSectionTitle('Destaques'),
                const SizedBox(height: 12),
                _buildProducts(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // WELCOME CARD
  // ─────────────────────────────────────────────
  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0891B2), Color(0xFF164E63)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bom dia,',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 13,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bem-vindo de volta 👋',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text(
                'JF',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SEARCH
  // ─────────────────────────────────────────────
  Widget _buildSearch() {
    return TextField(
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Buscar produtos...',
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.35),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: Colors.white.withOpacity(0.4),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF22D3EE), width: 1),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SECTION TITLE
  // ─────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CATEGORIES — scroll horizontal com ícone + label
  // ─────────────────────────────────────────────
  Widget _buildCategories() {
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categorias.length,
        itemBuilder: (_, index) {
          final bool ativo = _categoriaAtiva == index;
          return GestureDetector(
            onTap: () => setState(() => _categoriaAtiva = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: ativo
                    ? const Color(0xFF22D3EE)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ativo
                      ? const Color(0xFF22D3EE)
                      : Colors.white.withOpacity(0.09),
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _categorias[index]['icon'] as IconData,
                    color: ativo ? const Color(0xFF0A1628) : Colors.white54,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _categorias[index]['label'] as String,
                    style: TextStyle(
                      color: ativo ? const Color(0xFF0A1628) : Colors.white54,
                      fontSize: 11,
                      fontWeight: ativo ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PRODUCTS — grid 2 colunas
  // ─────────────────────────────────────────────
  Widget _buildProducts() {
    return FutureBuilder<List<ProdutoModel>>(
      future: _produtosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: Color(0xFF22D3EE)),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final produtos = snapshot.data!;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.78, // ajuste conforme o conteúdo do seu card
          ),
          itemCount: produtos.length,
          itemBuilder: (context, index) {
            return _buildProductCard(produtos[index]);
          },
        );
      },
    );
  }

  Widget _buildProductCard(ProdutoModel produto) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: produto.foto != null && produto.foto!.isNotEmpty
                  ? Image.network(
                      "http://192.168.86.9:8080/files/${produto.foto}",
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => _productPlaceholder(),
                    )
                  : _productPlaceholder(),
            ),
          ),

          // Informações
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produto.nome ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (produto.categoria != null)
                  Text(
                    produto.categoria!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'R\$ ${produto.preco?.toStringAsFixed(2) ?? '0,00'}',
                      style: const TextStyle(
                        color: Color(0xFF22D3EE),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _productPlaceholder() {
    return Container(
      color: Colors.white.withOpacity(0.06),
      child: const Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          color: Colors.white24,
          size: 36,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_rounded,
              color: Colors.white.withOpacity(0.2),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhum produto encontrado',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFEF4444),
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
