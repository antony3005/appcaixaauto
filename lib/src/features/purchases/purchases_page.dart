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

  ClientRepository get repository => widget.controller.repository;

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
    final session = widget.controller.session;
    if (session == null) {
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
    appBar: const AppTopBar(
      title: 'Minhas compras',
      subtitle: 'Histórico no Terminal',
    ),
    body: SafeArea(top: false, bottom: false, child: _content()),
  );

  Widget _content() {
    if (loading && purchases.isEmpty) {
      return const AppContent(child: LoadingSection(rows: 5));
    }
    if (error != null && purchases.isEmpty) {
      return Center(
        child: ErrorState(message: error!, onRetry: () => _load(reset: true)),
      );
    }
    if (purchases.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: const CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: AppContent(
                child: EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Nenhuma compra ainda',
                  message:
                      'Quando você fizer uma compra identificada no Terminal, ela aparecerá aqui.',
                ),
              ),
            ),
          ],
        ),
      );
    }
    final rows = _monthRows(purchases);
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.s8),
        itemCount: rows.length + 1 + (loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return AppContent(child: _PurchasesSummary(purchases: purchases));
          }
          final rowIndex = index - 1;
          if (rowIndex == rows.length) {
            return const AppContent(child: LoadingSection(rows: 1));
          }
          final row = rows[rowIndex];
          return AppContent(
            child: switch (row) {
              _MonthHeader(:final label, :final total) => Padding(
                padding: EdgeInsets.only(
                  top: rowIndex == 0 ? AppSpacing.s4 : AppSpacing.section,
                  bottom: AppSpacing.s1,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(label, style: context.text.titleSmall),
                      ),
                    ),
                    Text(money(total), style: context.text.bodySmall),
                  ],
                ),
              ),
              _PurchaseRowItem(:final purchase, :final first) => Column(
                children: [
                  if (!first) const Divider(),
                  PurchaseCard(
                    purchase: purchase,
                    onTap: () => openPurchaseDetail(
                      context,
                      purchase,
                      widget.controller,
                    ),
                  ),
                ],
              ),
            },
          );
        },
      ),
    );
  }
}

sealed class _ListRow {
  const _ListRow();
}

class _MonthHeader extends _ListRow {
  const _MonthHeader(this.label, this.total);
  final String label;
  final double total;
}

class _PurchaseRowItem extends _ListRow {
  const _PurchaseRowItem(this.purchase, {required this.first});
  final PurchaseSummary purchase;
  final bool first;
}

const _months = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

List<_ListRow> _monthRows(List<PurchaseSummary> purchases) {
  final rows = <_ListRow>[];
  String? current;
  var headerIndex = 0;
  var total = 0.0;
  for (final purchase in purchases) {
    final date = purchase.createdAt.toLocal();
    final label = '${_months[date.month - 1]} de ${date.year}';
    if (label != current) {
      if (current != null) rows[headerIndex] = _MonthHeader(current, total);
      current = label;
      total = 0;
      headerIndex = rows.length;
      rows.add(_MonthHeader(label, 0));
      rows.add(_PurchaseRowItem(purchase, first: true));
    } else {
      rows.add(_PurchaseRowItem(purchase, first: false));
    }
    if (purchase.status == PurchaseStatus.approved) total += purchase.total;
  }
  if (current != null) rows[headerIndex] = _MonthHeader(current, total);
  return rows;
}

/// Resumo do histórico carregado, sem caixa: número grande e uma etiqueta.
class _PurchasesSummary extends StatelessWidget {
  const _PurchasesSummary({required this.purchases});
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
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.s2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total aprovado', style: context.text.bodySmall),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(money(total), style: context.text.displaySmall),
            ),
            const SizedBox(height: AppSpacing.s2),
            AppTag(
              tone: TagTone.success,
              label:
                  '${approved.length} ${approved.length == 1 ? 'compra aprovada' : 'compras aprovadas'}',
            ),
          ],
        ),
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

  ClientRepository get repository => widget.controller.repository;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final session = widget.controller.session;
    if (session == null) {
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
      final result = await repository.loadPurchase(session, widget.purchase.id);
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
    appBar: const AppTopBar(title: 'Detalhe da compra'),
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

  Widget _detail(BuildContext context, PurchaseDetail value) {
    final approved = value.status == PurchaseStatus.approved;
    return SingleChildScrollView(
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
            if (approved)
              Notice(
                tone: NoticeTone.success,
                icon: Icons.check_circle_outline_rounded,
                title: 'Compra aprovada',
                message: _dates(value),
              )
            else
              Row(
                children: [
                  StatusChip(status: value.status),
                  const Spacer(),
                  Text(_dates(value), style: context.text.bodySmall),
                ],
              ),
            const SizedBox(height: AppSpacing.s3),
            Text(
              'Pedido #${_shortId(value.id)}',
              style: context.text.bodySmall,
            ),
            const SizedBox(height: AppSpacing.section),
            SectionHeader(
              title: 'Produtos',
              trailing: Text(
                '${value.items.length} ${value.items.length == 1 ? 'item' : 'itens'}',
                style: context.text.bodySmall,
              ),
            ),
            ListGroup(
              children: [
                for (final item in value.items) _PurchaseItemRow(item: item),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            Container(
              padding: const EdgeInsets.all(AppSpacing.s4),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: OrderSummary(
                subtotal: value.subtotal,
                discount: value.discount,
                total: value.total,
              ),
            ),
            if (approved) ...[
              const SizedBox(height: AppSpacing.s6),
              PrimaryButton(
                label: 'VER COMPROVANTE',
                icon: Icons.receipt_long_outlined,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ReceiptPage(
                      purchaseId: value.id,
                      controller: widget.controller,
                    ),
                  ),
                ),
              ),
            ],
            if (widget.controller.data?.capabilities.purchaseSupport ==
                true) ...[
              const SizedBox(height: AppSpacing.s3),
              SecondaryButton(
                label: 'PRECISO DE AJUDA',
                icon: Icons.support_agent_outlined,
                onPressed: () => showPurchaseSupportSheet(
                  context,
                  purchaseId: value.id,
                  controller: widget.controller,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _dates(PurchaseDetail value) {
    final created =
        '${localDate(value.createdAt)} às ${localTime(value.createdAt)}';
    final paid = value.paidAt;
    if (paid == null) return created;
    return '$created · pago às ${localTime(paid)}';
  }
}

class _PurchaseItemRow extends StatelessWidget {
  const _PurchaseItemRow({required this.item});
  final PurchaseItem item;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconWell(icon: Icons.inventory_2_outlined),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: context.text.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '${_quantity(item.quantity)} ${item.unit} · ${money(item.finalPrice)} un.',
                  style: context.text.bodySmall,
                ),
                if (item.discount > 0)
                  Text(
                    'Economia de ${money(item.discount)}',
                    style: context.text.bodySmall?.copyWith(
                      color: context.semantic.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Text(money(item.subtotal), style: context.text.titleSmall),
        ],
      ),
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

  ClientRepository get repository => widget.controller.repository;

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
    appBar: AppTopBar(
      title: 'Comprovante',
      actions: [
        AppIconButton(
          tooltip: 'Compartilhar comprovante',
          onPressed: receipt == null ? null : share,
          icon: Icons.share_outlined,
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: loading
          ? const Center(child: AppSpinner(label: 'Carregando comprovante'))
          : error != null
          ? Center(
              child: ErrorState(message: error!, onRetry: load),
            )
          : Column(
              children: [
                Expanded(
                  child: AppContent(
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: InteractiveViewer(
                        minScale: .8,
                        maxScale: 4,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.s4),
                            child: Image.memory(
                              receipt!.bytes,
                              semanticLabel: 'Imagem do comprovante',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                AppContent(
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  child: PrimaryButton(
                    label: 'ENVIAR COMPROVANTE',
                    icon: Icons.send_outlined,
                    onPressed: () => showReceiptSendSheet(
                      context,
                      purchaseId: widget.purchaseId,
                      controller: widget.controller,
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
      await widget.controller.repository.sendReceipt(
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
  Widget build(BuildContext context) => _SheetBody(
    title: 'Enviar comprovante',
    children: [
      AppSegmented<String>(
        label: 'Canal de envio',
        segments: const [
          ('EMAIL', 'E-mail', Icons.mail_outline_rounded),
          ('WHATSAPP', 'WhatsApp', Icons.chat_outlined),
        ],
        selected: channel,
        onChanged: loading
            ? null
            : (value) => setState(() {
                channel = value;
                recipient.text = channel == 'EMAIL'
                    ? widget.controller.data?.user.email ?? ''
                    : widget.controller.data?.user.phone ?? '';
              }),
      ),
      const SizedBox(height: AppSpacing.s6),
      TextField(
        controller: recipient,
        enabled: !loading,
        keyboardType: channel == 'EMAIL'
            ? TextInputType.emailAddress
            : TextInputType.phone,
        decoration: InputDecoration(
          labelText: channel == 'EMAIL' ? 'E-mail' : 'WhatsApp',
          hintText: channel == 'EMAIL'
              ? 'cliente@email.com'
              : '(75) 99999-9999',
          prefixIcon: Icon(
            channel == 'EMAIL'
                ? Icons.mail_outline_rounded
                : Icons.chat_outlined,
          ),
          errorText: error,
        ),
      ),
      const SizedBox(height: AppSpacing.s6),
      PrimaryButton(
        label: 'ENVIAR',
        loadingLabel: 'ENVIANDO',
        icon: Icons.send_outlined,
        loading: loading,
        onPressed: send,
      ),
    ],
  );
}

/// Corpo padrão das folhas inferiores: título e conteúdo acima do teclado.
class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      AppSpacing.gutter,
      0,
      AppSpacing.gutter,
      MediaQuery.viewInsetsOf(context).bottom + AppSpacing.s6,
    ),
    child: AppContent(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: context.text.titleLarge),
          ),
          const SizedBox(height: AppSpacing.s5),
          ...children,
        ],
      ),
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
      final result = await widget.controller.repository.requestPurchaseSupport(
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
  Widget build(BuildContext context) => _SheetBody(
    title: 'Ajuda com a compra',
    children: [
      Text(
        'Conte o que aconteceu. Você recebe um protocolo para acompanhar.',
        style: context.text.bodyMedium?.copyWith(color: context.semantic.muted),
      ),
      const SizedBox(height: AppSpacing.s6),
      TextField(
        controller: category,
        maxLength: 50,
        enabled: !loading,
        decoration: const InputDecoration(
          labelText: 'Categoria ou assunto',
          hintText: 'Ex.: cobrança, produto, comprovante',
          prefixIcon: Icon(Icons.label_outline_rounded),
        ),
      ),
      const SizedBox(height: AppSpacing.s3),
      TextField(
        controller: message,
        maxLength: 2000,
        minLines: 3,
        maxLines: 6,
        enabled: !loading,
        decoration: const InputDecoration(
          labelText: 'Mensagem',
          hintText: 'Descreva o problema',
          alignLabelWithHint: true,
        ),
      ),
      if (error != null) ...[
        const SizedBox(height: AppSpacing.s2),
        Notice(
          tone: NoticeTone.error,
          icon: Icons.error_outline_rounded,
          message: error!,
          live: true,
        ),
      ],
      const SizedBox(height: AppSpacing.s5),
      PrimaryButton(
        label: 'ENVIAR SOLICITAÇÃO',
        loadingLabel: 'ENVIANDO',
        loading: loading,
        onPressed: send,
      ),
    ],
  );
}

String _quantity(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value
          .toStringAsFixed(2)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
String _shortId(String id) => id.length <= 6 ? id : id.substring(id.length - 6);
