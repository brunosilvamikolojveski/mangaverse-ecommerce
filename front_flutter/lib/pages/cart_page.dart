import 'package:material_ui/material_ui.dart';

import '../models/cart.dart';
import '../state/store_scope.dart';
import '../state/store_session.dart';
import '../widgets/quantity_control.dart';
import '../widgets/store_layout.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  Future<void> _clear(BuildContext context, StoreSession session) async {
    if (!await confirmAction(
      context,
      'Esvaziar carrinho?',
      'Todos os itens serão removidos do seu carrinho.',
    )) {
      return;
    }
    if (!context.mounted) return;
    try {
      await session.clearCart();
    } catch (error) {
      if (context.mounted) {
        showStoreNotice(context, errorMessage(error), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = StoreScope.of(context);
    final cart = session.cart;
    return StorePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 20,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SUA SELEÇÃO',
                    style: TextStyle(
                      color: StoreColors.purple,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Meu carrinho',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.8,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () =>
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/', (_) => false),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Continuar comprando'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          if (session.loading)
            const Padding(
              padding: EdgeInsets.all(64),
              child: Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Carregando carrinho',
                ),
              ),
            )
          else if (session.cartError != null)
            StoreMessage(
              title: 'Não foi possível carregar o carrinho',
              message: session.cartError!,
              actionLabel: 'Tentar novamente',
              onAction: session.refreshCart,
              isError: true,
            )
          else if (cart == null || cart.items.isEmpty)
            const _EmptyCart()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final items = StorePanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Itens (${cart.itemCount})',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Opções do carrinho',
                            enabled: !session.busy,
                            onSelected: (_) => _clear(context, session),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'clear',
                                child: Text('Esvaziar carrinho'),
                              ),
                            ],
                            icon: const Icon(
                              Icons.more_horiz,
                              color: StoreColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: StoreColors.line),
                      for (
                        var index = 0;
                        index < cart.items.length;
                        index++
                      ) ...[
                        if (index > 0)
                          const Divider(height: 1, color: StoreColors.line),
                        _CartItemTile(
                          item: cart.items[index],
                          session: session,
                        ),
                      ],
                    ],
                  ),
                );
                final summary = _CartSummary(cart: cart, session: session);
                if (constraints.maxWidth < 950) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [items, const SizedBox(height: 24), summary],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: items),
                    const SizedBox(width: 28),
                    Expanded(child: summary),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 52),
    child: Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: StoreColors.lavender,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.shopping_bag_outlined,
            size: 36,
            color: StoreColors.purple,
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Seu carrinho está vazio',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -.4,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Explore o catálogo e encontre sua próxima leitura.',
          textAlign: TextAlign.center,
          style: TextStyle(color: StoreColors.muted, height: 1.6),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false),
          child: const Text('Explorar catálogo'),
        ),
      ],
    ),
  );
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item, required this.session});
  final CartItem item;
  final StoreSession session;

  Future<void> _perform(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error) {
      if (context.mounted) {
        showStoreNotice(context, errorMessage(error), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = !session.busy && !session.loading;
    final available = item.manga.isAvailable;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 66,
                height: 92,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: HSLColor.fromAHSL(
                    1,
                    ((item.manga.id * 47) % 360).toDouble(),
                    .48,
                    .35,
                  ).toColor(),
                  border: const Border(
                    left: BorderSide(color: Colors.black26, width: 4),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.manga.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Vol. ${item.manga.volumeNumber}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.manga.series,
                      style: const TextStyle(
                        color: StoreColors.purple,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${item.manga.title} · Vol. ${item.manga.volumeNumber}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${item.formattedUnitPrice} por unidade',
                      style: const TextStyle(
                        color: StoreColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    if (!available)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Indisponível no momento',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remover ${item.manga.title} do carrinho',
                onPressed: enabled
                    ? () => _perform(context, () => session.removeItem(item.id))
                    : null,
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: StoreColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 20,
            runSpacing: 12,
            children: [
              QuantityControl(
                value: item.quantity,
                label: '${item.manga.title}, volume ${item.manga.volumeNumber}',
                onDecrease: enabled && available && item.quantity > 1
                    ? () => _perform(
                        context,
                        () => session.updateItem(item.id, item.quantity - 1),
                      )
                    : null,
                onIncrease: enabled && available
                    ? () => _perform(
                        context,
                        () => session.updateItem(item.id, item.quantity + 1),
                      )
                    : null,
              ),
              Text(
                item.formattedLineTotal,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.cart, required this.session});
  final Cart cart;
  final StoreSession session;

  @override
  Widget build(BuildContext context) => StorePanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Resumo do pedido',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        _SummaryRow(label: 'Itens', value: '${cart.itemCount}'),
        const SizedBox(height: 16),
        _SummaryRow(label: 'Subtotal', value: cart.formattedSubtotal),
        const SizedBox(height: 16),
        const _SummaryRow(
          label: 'Frete',
          value: 'Grátis',
          valueColor: Color(0xFF23734D),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Divider(height: 1, color: StoreColors.line),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: Text(
                'Total',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              cart.formattedSubtotal,
              style: const TextStyle(
                color: StoreColors.purple,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed:
              session.busy ||
                  !session.cartReady ||
                  cart.items.any((item) => !item.manga.isAvailable)
              ? null
              : () => Navigator.of(context).pushNamed(
                  session.user == null
                      ? '/entrar?redirect=%2Ffinalizar'
                      : '/finalizar',
                ),
          child: const Text('Continuar para entrega'),
        ),
        const SizedBox(height: 14),
        Text(
          session.user == null
              ? 'Na próxima etapa, entre ou crie sua conta para escolher o endereço de entrega.'
              : 'Confira seu endereço e escolha a forma de pagamento na próxima etapa.',
          style: const TextStyle(
            color: StoreColors.muted,
            fontSize: 12,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 15, color: StoreColors.muted),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Frete gratuito e pagamento simulado neste projeto acadêmico.',
                style: TextStyle(
                  color: StoreColors.muted,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label;
  final String value;
  final Color? valueColor;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: StoreColors.muted, fontSize: 13),
        ),
      ),
      const SizedBox(width: 12),
      Text(
        value,
        style: TextStyle(
          color: valueColor ?? StoreColors.ink,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}
