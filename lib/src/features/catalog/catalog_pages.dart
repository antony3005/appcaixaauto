import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/client_repository.dart';
import '../../domain/models.dart';
import '../../shared/app_widgets.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({
    required this.data,
    required this.repository,
    required this.session,
    super.key,
  });
  final ClientBootstrap data;
  final ClientRepository repository;
  final AuthSession session;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final searchController = TextEditingController();
  final scrollController = ScrollController();
  final products = <ProductSummary>[];
  Timer? debounce;
  String? selectedCategory;
  String? error;
  bool loading = true;
  bool loadingMore = false;
  int nextPage = 0;
  bool hasMore = true;

  ClientFeatureRepository? get featureRepository =>
      widget.repository is ClientFeatureRepository
      ? widget.repository as ClientFeatureRepository
      : null;

  @override
  void initState() {
    super.initState();
    products.addAll(widget.data.products);
    scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    debounce?.cancel();
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (scrollController.position.extentAfter < 360 && hasMore) {
      _load();
    }
  }

  void _search(String value) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _load(reset: true);
    });
  }

  Future<void> _load({bool reset = false}) async {
    final repository = featureRepository;
    if (repository == null) {
      setState(() {
        loading = false;
        hasMore = false;
      });
      return;
    }
    if (loadingMore || (!reset && !hasMore)) return;
    setState(() {
      error = null;
      if (reset) {
        loading = true;
        nextPage = 0;
        hasMore = true;
      } else {
        loadingMore = true;
      }
    });
    try {
      final page = await repository.loadCatalog(
        widget.session,
        query: searchController.text,
        category: selectedCategory,
        page: reset ? 0 : nextPage,
      );
      if (!mounted) return;
      setState(() {
        if (reset) products.clear();
        products.addAll(page.content);
        nextPage = page.page + 1;
        hasMore = page.hasMore;
      });
    } on AppException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Não foi possível carregar o catálogo.');
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
          loadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = {
      ...widget.data.products.map((product) => product.category),
      ...products.map((product) => product.category),
    }.where((category) => category.isNotEmpty).toList()..sort();
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Catálogo'),
            Text('Consulte antes de ir ao Terminal'),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: AppContent(
          child: Column(
            children: [
              TextField(
                controller: searchController,
                onChanged: _search,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Buscar produtos',
                ),
              ),
              if (categories.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: ChoiceChip(
                          label: const Text('Todos'),
                          selected: selectedCategory == null,
                          onSelected: (_) {
                            setState(() => selectedCategory = null);
                            _load(reset: true);
                          },
                        ),
                      ),
                      ...categories.map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xs),
                          child: ChoiceChip(
                            label: Text(_categoryLabel(category)),
                            selected: selectedCategory == category,
                            onSelected: (_) {
                              setState(() => selectedCategory = category);
                              _load(reset: true);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Expanded(child: _content()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content() {
    if (loading && products.isEmpty) return const LoadingSection(rows: 5);
    if (error != null && products.isEmpty) {
      return ErrorState(message: error!, onRetry: () => _load(reset: true));
    }
    if (products.isEmpty) {
      return EmptyState(
        icon: searchController.text.trim().isEmpty
            ? Icons.inventory_2_outlined
            : Icons.search_off_rounded,
        title: searchController.text.trim().isEmpty
            ? 'Nenhum produto disponível'
            : 'Nenhum resultado',
        message: searchController.text.trim().isEmpty
            ? 'O catálogo deste condomínio está vazio no momento.'
            : 'Tente outro nome ou remova o filtro de categoria.',
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 620 ? 3 : 2;
          return GridView.builder(
            controller: scrollController,
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            itemCount: products.length + (loadingMore ? 2 : 0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: .67,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
            ),
            itemBuilder: (context, index) {
              if (index >= products.length) {
                return const LoadingTile();
              }
              final product = products[index];
              return ProductCard(
                product: product,
                heroTag: 'catalog-${product.id}-$index',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailPage(
                      product: product,
                      heroTag: 'catalog-${product.id}-$index',
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({
    required this.product,
    required this.heroTag,
    super.key,
  });
  final ProductSummary product;
  final String heroTag;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalhe do produto')),
    body: SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: AppContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: heroTag,
                child: AspectRatio(
                  aspectRatio: 1.25,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.hero),
                    child: ColoredBox(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      child: product.imageUrl?.isNotEmpty == true
                          ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.image_not_supported_outlined,
                                size: 64,
                              ),
                            )
                          : const Icon(
                              Icons.local_grocery_store_outlined,
                              size: 72,
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _categoryLabel(product.category),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  Icon(Icons.circle, size: 9, color: context.semantic.success),
                  const SizedBox(width: AppSpacing.xs),
                  const Text('Disponível'),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                product.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  Text(
                    money(product.price),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (product.isPromotion) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        money(product.originalPrice!),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.semantic.muted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                product.unit,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: context.semantic.muted),
              ),
              if (product.description?.isNotEmpty == true) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Sobre o produto',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  product.description!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadii.control),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.storefront_outlined),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Disponível no Terminal. Consulte aqui, identifique-se e finalize por lá.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    ),
  );
}

String _categoryLabel(String raw) {
  if (raw.isEmpty) return 'Sem categoria';
  return raw
      .toLowerCase()
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
