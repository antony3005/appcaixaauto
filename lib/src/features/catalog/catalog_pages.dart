import 'dart:async';
import 'dart:developer' as developer;

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
    setState(() {});
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _load(reset: true);
    });
  }

  Future<void> _load({bool reset = false}) async {
    final repository = widget.repository;
    final stopwatch = Stopwatch()..start();
    final auditId = DateTime.now().microsecondsSinceEpoch.toString();

    void audit(
      String event, {
      Object? details,
      Object? error,
      StackTrace? stackTrace,
    }) {
      developer.log(
        '[CATALOG][$auditId] $event'
        '${details != null ? ' | $details' : ''}',
        name: 'catalog.audit',
        error: error,
        stackTrace: stackTrace,
      );
    }

    audit(
      'LOAD_REQUESTED',
      details:
          'reset=$reset, page=$nextPage, '
          'category=$selectedCategory, query="${searchController.text}"',
    );

    if (loadingMore || (!reset && !hasMore)) {
      audit(
        'LOAD_SKIPPED',
        details: 'loadingMore=$loadingMore, hasMore=$hasMore',
      );
      return;
    }

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

    final requestedPage = reset ? 0 : nextPage;

    audit('LOAD_STARTED', details: 'page=$requestedPage, reset=$reset');

    try {
      final page = await repository.loadCatalog(
        widget.session,
        query: searchController.text,
        category: selectedCategory,
        page: requestedPage,
      );

      if (!mounted) {
        audit('LOAD_COMPLETED_AFTER_DISPOSE');
        return;
      }

      setState(() {
        if (reset) products.clear();

        products.addAll(page.content);
        nextPage = page.page + 1;
        hasMore = page.hasMore;
      });

      audit(
        'LOAD_SUCCEEDED',
        details:
            'requestedPage=$requestedPage, '
            'returnedPage=${page.page}, '
            'received=${page.content.length}, '
            'totalLoaded=${products.length}, '
            'hasMore=${page.hasMore}',
      );
    } on AppException catch (exception, stackTrace) {
      audit(
        'LOAD_APP_ERROR',
        details: 'page=$requestedPage, message=${exception.message}',
        error: exception,
        stackTrace: stackTrace,
      );

      if (mounted) {
        setState(() => error = exception.message);
      }
    } catch (exception, stackTrace) {
      audit(
        'LOAD_UNEXPECTED_ERROR',
        details: 'page=$requestedPage',
        error: exception,
        stackTrace: stackTrace,
      );

      if (mounted) {
        setState(() {
          error = 'Não foi possível carregar o catálogo.';
        });
      }
    } finally {
      stopwatch.stop();

      audit(
        'LOAD_FINISHED',
        details:
            'durationMs=${stopwatch.elapsedMilliseconds}, '
            'mounted=$mounted',
      );

      if (mounted) {
        setState(() {
          loading = false;
          loadingMore = false;
        });
      }
    }
  }

  void _selectCategory(String? category) {
    if (selectedCategory == category) return;
    setState(() => selectedCategory = category);
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final categories = {
      ...widget.data.products.map((product) => product.category),
      ...products.map((product) => product.category),
    }.where((category) => category.isNotEmpty).toList()..sort();
    return Scaffold(
      appBar: const AppTopBar(
        title: 'Catálogo',
        subtitle: 'Consulte antes de ir ao Terminal',
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            AppContent(
              child: TextField(
                controller: searchController,
                onChanged: _search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar produtos',
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  filled: true,
                  fillColor: context.colors.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s4,
                    vertical: AppSpacing.s3,
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: AppSpacing.s3),
                    child: Icon(Icons.search_rounded, size: AppSizes.iconMd),
                  ),
                  suffixIcon: searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar busca',
                          icon: const Icon(
                            Icons.close_rounded,
                            size: AppSizes.iconMd,
                          ),
                          onPressed: () {
                            searchController.clear();
                            setState(() {});
                            _load(reset: true);
                          },
                        ),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppRadii.pill),
                    ),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppRadii.pill),
                    ),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(AppRadii.pill),
                    ),
                    borderSide: BorderSide(
                      color: context.colors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            if (categories.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s1),
              SizedBox(
                height: AppSizes.tapTarget,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSizes.contentMax,
                    ),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.gutter,
                      ),
                      children: [
                        AppFilterChip(
                          label: 'Todos',
                          selected: selectedCategory == null,
                          onTap: () => _selectCategory(null),
                        ),
                        for (final category in categories) ...[
                          const SizedBox(width: AppSpacing.s2),
                          AppFilterChip(
                            label: categoryLabel(category),
                            selected: selectedCategory == category,
                            onTap: () => _selectCategory(category),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s3),
            Expanded(child: _content()),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    if (loading && products.isEmpty) {
      return const AppContent(child: LoadingSection(rows: 5));
    }
    if (error != null && products.isEmpty) {
      return Center(
        child: ErrorState(message: error!, onRetry: () => _load(reset: true)),
      );
    }
    final searching = searchController.text.trim().isNotEmpty;
    if (products.isEmpty) {
      return SingleChildScrollView(
        child: AppContent(
          child: EmptyState(
            icon: searching
                ? Icons.search_off_rounded
                : Icons.inventory_2_outlined,
            title: searching ? 'Nenhum resultado' : 'Nenhum produto disponível',
            message: searching
                ? 'Tente outro nome ou remova o filtro de categoria.'
                : 'O catálogo deste condomínio está vazio no momento.',
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.clamp(0.0, AppSizes.contentMax);
          final side = (constraints.maxWidth - width) / 2 + AppSpacing.s3;
          const gap = AppSpacing.s2;
          final tileWidth = (width - AppSpacing.s3 * 2 - gap) / 2;
          final scale = MediaQuery.textScalerOf(
            context,
          ).scale(1).clamp(1.0, 2.0);
          final extent = tileWidth * .75 + 84 * scale + 12;
          return GridView.builder(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(side, 0, side, AppSpacing.s8),
            itemCount: products.length + (loadingMore ? 2 : 0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: extent,
              crossAxisSpacing: gap,
              mainAxisSpacing: AppSpacing.s3,
            ),
            itemBuilder: (context, index) {
              if (index >= products.length) {
                return const LoadingTile();
              }
              final product = products[index];
              final heroTag = 'catalog-${product.id}-$index';
              return ProductCard(
                product: product,
                heroTag: heroTag,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ProductDetailPage(product: product, heroTag: heroTag),
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
  Widget build(BuildContext context) {
    final discount = product.isPromotion
        ? ((1 - product.price / product.originalPrice!) * 100).round()
        : 0;
    return Scaffold(
      appBar: const AppTopBar(title: 'Detalhe do produto'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: AppContent(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.s2,
              AppSpacing.gutter,
              AppSpacing.s8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: heroTag,
                        child: ProductImage(
                          url: product.imageUrl,
                          iconSize: 64,
                        ),
                      ),
                      if (discount > 0)
                        Positioned(
                          top: AppSpacing.s3,
                          left: AppSpacing.s3,
                          child: OfferBadge(label: '-$discount%'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s5),
                Text(
                  categoryLabel(product.category).toUpperCase(),
                  style: context.eyebrowStyle.copyWith(
                    color: context.colors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s1),
                Text(product.name, style: context.text.titleLarge),
                const SizedBox(height: AppSpacing.s3),
                Wrap(
                  spacing: AppSpacing.s2,
                  runSpacing: AppSpacing.s1,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    Text(
                      money(product.price),
                      style: context.priceStyle.copyWith(
                        color: product.isPromotion
                            ? context.colors.error
                            : context.colors.primary,
                      ),
                    ),
                    if (product.isPromotion)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          money(product.originalPrice!),
                          style: context.text.bodyMedium?.copyWith(
                            color: context.semantic.muted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                  ],
                ),
                if (product.unit.isNotEmpty)
                  Text(product.unit, style: context.text.bodySmall),
                if (product.promotionName?.isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.s2),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppTag(
                      label: product.promotionName!,
                      tone: TagTone.primary,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.s5),
                const Notice(
                  tone: NoticeTone.success,
                  icon: Icons.storefront_outlined,
                  title: 'Disponível no Terminal',
                  message:
                      'Consulte aqui, identifique-se com o Meu QR e finalize a compra por lá.',
                ),
                if (product.description?.isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.section),
                  Text('Sobre o produto', style: context.text.titleMedium),
                  const SizedBox(height: AppSpacing.s2),
                  Text(product.description!, style: context.text.bodyMedium),
                ],
                const SizedBox(height: AppSpacing.section),
                const Notice(message: terminalReminder),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
