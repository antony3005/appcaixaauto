import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../data/client_repository.dart';
import '../../domain/models.dart';
import '../../shared/app_widgets.dart';
import '../../state/client_controller.dart';

class PurchasesPage extends StatefulWidget {
  const PurchasesPage({
    required this.controller,
    required this.data,
    super.key,
  });
  final ClientController controller;
  final ClientBootstrap data;

  @override
  State<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends State<PurchasesPage> {
  final purchases = <PurchaseSummary>[];
  final scrollController = ScrollController();
  bool loading = true;
  bool loadingMore = false;
  bool hasMore = true;
  int nextPage = 0;
  String? error;

  ClientFeatureRepository? get featureRepository =>
      widget.controller.repository is ClientFeatureRepository
      ? widget.controller.repository as ClientFeatureRepository
      : null;

  @override
  void initState() {
    super.initState();
    purchases.addAll(widget.data.purchases);
    scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (scrollController.position.extentAfter < 320) _load();
  }

  Future<void> _load({bool reset = false}) async {
    final repository = featureRepository;
    final session = widget.controller.session;
    if (repository == null || session == null) {
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
      final page = await repository.loadPurchasePage(
        session,
        page: reset ? 0 : nextPage,
      );
      if (!mounted) return;
      setState(() {
        if (reset) purchases.clear();
        purchases.addAll(page.content);
        nextPage = page.page + 1;
        hasMore = page.hasMore;
      });
    } on AppException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } catch (_) {
      if (mounted) setState(() => error = 'Não foi possível carregar compras.');
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text('Minhas compras'), Text('Histórico no Terminal')],
      ),
    ),
    body: SafeArea(top: false, child: AppContent(child: _content())),
  );

  Widget _content() {
    if (loading && purchases.isEmpty) return const LoadingSection(rows: 5);
    if (error != null && purchases.isEmpty) {
      return ErrorState(message: error!, onRetry: () => _load(reset: true));
    }
    if (purchases.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: const CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Nenhuma compra ainda',
                message:
                    'Quando você fizer uma compra identificada no Terminal, ela aparecerá aqui.',
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.separated(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        itemCount: purchases.length + 1 + (loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) return _PurchasesIntro(purchases: purchases);
          final purchaseIndex = index - 1;
          if (purchaseIndex == purchases.length) {
            return const LoadingTile(height: 72);
          }
          final purchase = purchases[purchaseIndex];
          return PurchaseCard(
            purchase: purchase,
            onTap: () =>
                openPurchaseDetail(context, purchase, widget.controller),
          );
        },
      ),
    );
  }
}

class _PurchasesIntro extends StatelessWidget {
  const _PurchasesIntro({required this.purchases});
  final List<PurchaseSummary> purchases;

  @override
  Widget build(BuildContext context) {
    final approved = purchases
        .where((purchase) => purchase.status == PurchaseStatus.approved)
        .toList();
    final total = approved.fold<double>(
      0,
      (sum, purchase) => sum + purchase.total,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppRadii.hero),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.darkText.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${approved.length} ${approved.length == 1 ? 'compra aprovada' : 'compras aprovadas'}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: AppColors.darkMuted),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  money(total),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  'Total do histórico carregado',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.darkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void openPurchaseDetail(
  BuildContext context,
  PurchaseSummary purchase,
  ClientController controller,
) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          PurchaseDetailPage(purchase: purchase, controller: controller),
    ),
  );
}

class PurchaseDetailPage extends StatefulWidget {
  const PurchaseDetailPage({
    required this.purchase,
    required this.controller,
    super.key,
  });
  final PurchaseSummary purchase;
  final ClientController controller;

  @override
  State<PurchaseDetailPage> createState() => _PurchaseDetailPageState();
}

class _PurchaseDetailPageState extends State<PurchaseDetailPage> {
  PurchaseDetail? detail;
  String? error;
  bool loading = true;

  ClientFeatureRepository? get repository =>
      widget.controller.repository is ClientFeatureRepository
      ? widget.controller.repository as ClientFeatureRepository
      : null;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final api = repository;
    final session = widget.controller.session;
    if (api == null || session == null) {
      setState(() {
        loading = false;
        error = 'Detalhes indisponíveis nesta sessão.';
      });
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await api.loadPurchase(session, widget.purchase.id);
      if (mounted) setState(() => detail = result);
    } on AppException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } catch (_) {
      if (mounted) setState(() => error = 'Não foi possível abrir a compra.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalhe da compra')),
    body: SafeArea(
      top: false,
      child: loading
          ? const AppContent(child: LoadingSection(rows: 5))
          : error != null
          ? Center(
              child: ErrorState(message: error!, onRetry: load),
            )
          : _detail(context, detail!),
    ),
  );

  Widget _detail(
    BuildContext context,
    PurchaseDetail value,
  ) => SingleChildScrollView(
    child: AppContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: value.status == PurchaseStatus.approved
                  ? context.semantic.successContainer
                  : Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: Row(
              children: [
                StatusChip(status: value.status),
                const Spacer(),
                Text('#${_shortId(value.id)}'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${localDate(value.createdAt)} às ${localTime(value.createdAt)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.semantic.muted),
          ),
          if (value.paidAt != null)
            Text(
              'Pago em ${localDate(value.paidAt!)} às ${localTime(value.paidAt!)}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.semantic.muted),
            ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            title: 'Produtos',
            trailing: Text('${value.items.length} itens'),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              children: [
                for (var index = 0; index < value.items.length; index++) ...[
                  _PurchaseItemRow(item: value.items[index]),
                  if (index != value.items.length - 1) const Divider(),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Resumo', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                _ValueRow(label: 'Subtotal', value: money(value.subtotal)),
                if (value.discount > 0)
                  _ValueRow(
                    label: 'Descontos e promoções',
                    value: '- ${money(value.discount)}',
                    valueColor: context.semantic.success,
                  ),
                const Divider(),
                _ValueRow(
                  label: 'Total',
                  value: money(value.total),
                  strong: true,
                ),
              ],
            ),
          ),
          if (value.status == PurchaseStatus.approved) ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReceiptPage(
                      purchaseId: value.id,
                      controller: widget.controller,
                    ),
                  ),
                ),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Ver comprovante'),
              ),
            ),
          ],
          if (widget.controller.data?.capabilities.purchaseSupport == true) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showPurchaseSupportSheet(
                  context,
                  purchaseId: value.id,
                  controller: widget.controller,
                ),
                icon: const Icon(Icons.support_agent_outlined),
                label: const Text('Preciso de ajuda com esta compra'),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    ),
  );
}

class _PurchaseItemRow extends StatelessWidget {
  const _PurchaseItemRow({required this.item});
  final PurchaseItem item;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadii.small),
          ),
          child: const Icon(Icons.inventory_2_outlined),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: Theme.of(context).textTheme.titleSmall),
              Text(
                '${_quantity(item.quantity)} ${item.unit} • ${money(item.finalPrice)} un.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.semantic.muted),
              ),
              if (item.discount > 0)
                Text(
                  'Economia de ${money(item.discount)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.semantic.success,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          money(item.subtotal),
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    ),
  );
}

class ReceiptPage extends StatefulWidget {
  const ReceiptPage({
    required this.purchaseId,
    required this.controller,
    super.key,
  });
  final String purchaseId;
  final ClientController controller;

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  ReceiptImage? receipt;
  String? error;
  bool loading = true;

  ClientFeatureRepository get repository =>
      widget.controller.repository as ClientFeatureRepository;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final value = await repository.loadReceipt(
        widget.controller.session!,
        widget.purchaseId,
      );
      if (mounted) setState(() => receipt = value);
    } on AppException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Não foi possível abrir o comprovante.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> share() async {
    final image = receipt;
    if (image == null) return;
    await SharePlus.instance.share(
      ShareParams(
        text: 'Comprovante da compra #${_shortId(widget.purchaseId)}',
        files: [XFile.fromData(image.bytes, mimeType: 'image/png')],
        fileNameOverrides: ['comprovante-app247.png'],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Comprovante'),
      actions: [
        IconButton(
          tooltip: 'Compartilhar comprovante',
          onPressed: receipt == null ? null : share,
          icon: const Icon(Icons.share_outlined),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: ErrorState(message: error!, onRetry: load),
            )
          : Column(
              children: [
                Expanded(
                  child: InteractiveViewer(
                    minScale: .8,
                    maxScale: 4,
                    child: Center(child: Image.memory(receipt!.bytes)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => showReceiptSendSheet(
                        context,
                        purchaseId: widget.purchaseId,
                        controller: widget.controller,
                      ),
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('Enviar comprovante'),
                    ),
                  ),
                ),
              ],
            ),
    ),
  );
}

Future<void> showReceiptSendSheet(
  BuildContext context, {
  required String purchaseId,
  required ClientController controller,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) =>
      _ReceiptSendSheet(purchaseId: purchaseId, controller: controller),
);

class _ReceiptSendSheet extends StatefulWidget {
  const _ReceiptSendSheet({required this.purchaseId, required this.controller});
  final String purchaseId;
  final ClientController controller;

  @override
  State<_ReceiptSendSheet> createState() => _ReceiptSendSheetState();
}

class _ReceiptSendSheetState extends State<_ReceiptSendSheet> {
  String channel = 'EMAIL';
  late final recipient = TextEditingController(
    text: widget.controller.data?.user.email ?? '',
  );
  bool loading = false;
  String? error;

  @override
  void dispose() {
    recipient.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (recipient.text.trim().isEmpty || loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final repository =
          widget.controller.repository as ClientFeatureRepository;
      await repository.sendReceipt(
        widget.controller.session!,
        widget.purchaseId,
        channel: channel,
        recipient: recipient.text.trim(),
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Envio solicitado com sucesso.')),
      );
    } on AppException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.lg,
      MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enviar comprovante',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'EMAIL',
              label: Text('E-mail'),
              icon: Icon(Icons.mail_outline),
            ),
            ButtonSegment(
              value: 'WHATSAPP',
              label: Text('WhatsApp'),
              icon: Icon(Icons.chat_outlined),
            ),
          ],
          selected: {channel},
          onSelectionChanged: loading
              ? null
              : (value) {
                  setState(() {
                    channel = value.first;
                    recipient.text = channel == 'EMAIL'
                        ? widget.controller.data?.user.email ?? ''
                        : widget.controller.data?.user.phone ?? '';
                  });
                },
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: recipient,
          enabled: !loading,
          keyboardType: channel == 'EMAIL'
              ? TextInputType.emailAddress
              : TextInputType.phone,
          decoration: InputDecoration(
            labelText: channel == 'EMAIL' ? 'E-mail' : 'WhatsApp',
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            error!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: loading ? null : send,
            child: Text(loading ? 'Enviando...' : 'Enviar'),
          ),
        ),
      ],
    ),
  );
}

Future<void> showPurchaseSupportSheet(
  BuildContext context, {
  required String purchaseId,
  required ClientController controller,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) =>
      _PurchaseSupportSheet(purchaseId: purchaseId, controller: controller),
);

class _PurchaseSupportSheet extends StatefulWidget {
  const _PurchaseSupportSheet({
    required this.purchaseId,
    required this.controller,
  });
  final String purchaseId;
  final ClientController controller;

  @override
  State<_PurchaseSupportSheet> createState() => _PurchaseSupportSheetState();
}

class _PurchaseSupportSheetState extends State<_PurchaseSupportSheet> {
  final category = TextEditingController();
  final message = TextEditingController();
  bool loading = false;
  String? error;

  @override
  void dispose() {
    category.dispose();
    message.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (loading ||
        category.text.trim().isEmpty ||
        message.text.trim().isEmpty) {
      setState(() => error = 'Informe a categoria e descreva o problema.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result =
          await (widget.controller.repository as ClientFeatureRepository)
              .requestPurchaseSupport(
                widget.controller.session!,
                widget.purchaseId,
                category: category.text.trim(),
                message: message.text.trim(),
              );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Solicitação enviada. Protocolo: ${result.protocol}'),
        ),
      );
    } on AppException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.lg,
      MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ajuda com a compra',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: category,
          maxLength: 50,
          decoration: const InputDecoration(labelText: 'Categoria ou assunto'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: message,
          maxLength: 2000,
          minLines: 4,
          maxLines: 7,
          decoration: const InputDecoration(labelText: 'Mensagem'),
        ),
        if (error != null)
          Text(
            error!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: loading ? null : send,
            child: Text(loading ? 'Enviando...' : 'Enviar solicitação'),
          ),
        ),
      ],
    ),
  );
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    this.strong = false,
    this.valueColor,
  });
  final String label, value;
  final bool strong;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: strong ? Theme.of(context).textTheme.titleMedium : null,
          ),
        ),
        Text(
          value,
          style:
              (strong
                      ? Theme.of(context).textTheme.titleMedium
                      : Theme.of(context).textTheme.bodyMedium)
                  ?.copyWith(color: valueColor),
        ),
      ],
    ),
  );
}

String _quantity(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value
          .toStringAsFixed(2)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
String _shortId(String id) => id.length <= 6 ? id : id.substring(id.length - 6);
