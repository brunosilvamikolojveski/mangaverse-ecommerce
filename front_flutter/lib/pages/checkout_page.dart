import 'package:material_ui/material_ui.dart';

import '../models/address.dart';
import '../models/order.dart';
import '../services/account_service.dart';
import '../services/order_service.dart';
import '../state/store_scope.dart';
import '../widgets/editor_form.dart';
import '../widgets/order_panel.dart';
import '../widgets/store_layout.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, required this.account, required this.orders});
  final AccountService account;
  final OrderService orders;
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  List<Address> _addresses = [];
  int? _addressId;
  String _method = 'pix';
  bool _loading = true;
  bool _busy = false;
  String? _error;
  StoreOrder? _order;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final addresses = await widget.account.addresses();
      if (mounted) {
        setState(() {
          _addresses = addresses;
          _addressId =
              addresses.where((a) => a.isDefault).firstOrNull?.id ??
              addresses.firstOrNull?.id;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _newAddress() async {
    final saved = await showEditor(
      context,
      title: 'Novo endereço de entrega',
      fields: addressFields,
      initial: {'is_default': _addresses.isEmpty},
      onSave: (values) async {
        await widget.account.saveAddress(values);
      },
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _create() async {
    if (_addressId == null || _busy) return;
    final session = StoreScope.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final order = await widget.orders.create(
        addressId: _addressId!,
        paymentMethod: _method,
      );
      if (mounted) setState(() => _order = order);
      await session.refreshCart();
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final order = await widget.orders.confirmPayment(_order!.id);
      if (mounted) setState(() => _order = order);
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = StoreScope.of(context);
    final cart = session.cart;
    final order = _order;
    return StorePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeading(
            order == null
                ? 'Finalizar compra'
                : order.isPending
                ? 'Pedido criado!'
                : 'Pagamento confirmado!',
            subtitle: order == null
                ? 'Confira os itens e escolha onde deseja receber sua compra.'
                : 'Acompanhe sua compra em Meus pedidos.',
          ),
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFF9E7E7),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFF802E2E), fontSize: 13),
              ),
            ),
          if (order != null)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: OrderPanel(
                  order: order,
                  showAddress: true,
                  actions: [
                    if (order.isPending)
                      FilledButton(
                        onPressed: _busy ? null : _pay,
                        child: Text(
                          _busy
                              ? 'Confirmando…'
                              : 'Confirmar pagamento de teste',
                        ),
                      ),
                    OutlinedButton(
                      onPressed: () =>
                          Navigator.of(context)
                              .pushReplacementNamed('/pedidos'),
                      child: const Text('Ver meus pedidos'),
                    ),
                  ],
                ),
              ),
            )
          else if (_loading || session.loading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (session.cartError != null)
            StoreMessage(
              title: 'Atualize seu carrinho',
              message: session.cartError!,
              actionLabel: 'Atualizar',
              onAction: session.refreshCart,
              isError: true,
            )
          else if (cart == null || cart.items.isEmpty)
            StoreMessage(
              title: 'Seu carrinho está vazio',
              message: 'Adicione um mangá para continuar.',
              actionLabel: 'Explorar catálogo',
              onAction: () => Navigator.of(context).pushNamed('/'),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final address = _addresses
                    .where((item) => item.id == _addressId)
                    .firstOrNull;
                final steps = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StorePanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _stepTitle(1, 'Endereço de entrega'),
                          const SizedBox(height: 20),
                          if (_addresses.isEmpty)
                            const Text(
                              'Cadastre um endereço para receber sua compra.',
                              style: TextStyle(
                                color: StoreColors.muted,
                                fontSize: 13,
                              ),
                            )
                          else ...[
                            DropdownButtonFormField<int>(
                              key: ValueKey(_addressId),
                              initialValue: _addressId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Escolha um endereço',
                              ),
                              items: [
                                for (final item in _addresses)
                                  DropdownMenuItem(
                                    value: item.id,
                                    child: Text(
                                      '${item.label} · ${item.streetLine}',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                              ],
                              onChanged: _busy
                                  ? null
                                  : (value) =>
                                        setState(() => _addressId = value),
                            ),
                            if (address != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(
                                  '${address.recipient}\n${address.streetLine}\n${address.cityLine} · CEP ${address.values['postal_code']}',
                                  style: const TextStyle(
                                    color: StoreColors.muted,
                                    fontSize: 12,
                                    height: 1.7,
                                  ),
                                ),
                              ),
                          ],
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _busy ? null : _newAddress,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Novo endereço'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    StorePanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _stepTitle(2, 'Forma de pagamento'),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final entry in paymentMethods.entries)
                                ChoiceChip(
                                  showCheckmark: false,
                                  avatar: Icon(
                                    _method == entry.key
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    size: 17,
                                    color: StoreColors.purple,
                                  ),
                                  label: Text(
                                    entry.value,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  selected: _method == entry.key,
                                  selectedColor: StoreColors.lavender,
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                    side: BorderSide(
                                      color: _method == entry.key
                                          ? StoreColors.purple
                                          : StoreColors.line,
                                    ),
                                  ),
                                  onSelected: _busy
                                      ? null
                                      : (_) =>
                                            setState(() => _method = entry.key),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'O pagamento é simulado. Nenhuma cobrança real será realizada.',
                            style: TextStyle(
                              color: StoreColors.muted,
                              fontSize: 11,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                final summary = StorePanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Resumo do pedido',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      for (final item in cart.items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.quantity} × ${item.manga.title} · Vol. ${item.manga.volumeNumber}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: StoreColors.muted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                item.formattedLineTotal,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Divider(height: 32, color: StoreColors.line),
                      _priceLine('Subtotal', cart.formattedSubtotal),
                      const SizedBox(height: 14),
                      _priceLine('Frete', 'Grátis'),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            cart.formattedSubtotal,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: StoreColors.purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _busy || _addressId == null ? null : _create,
                        child: Text(_busy ? 'Criando pedido…' : 'Criar pedido'),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Frete gratuito neste projeto acadêmico.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: StoreColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
                if (constraints.maxWidth < 900) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [steps, const SizedBox(height: 20), summary],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: steps),
                    const SizedBox(width: 24),
                    Expanded(child: summary),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _stepTitle(int number, String title) => Row(
    children: [
      Container(
        width: 25,
        height: 25,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: StoreColors.purple,
          shape: BoxShape.circle,
        ),
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
  Widget _priceLine(String label, String price) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: StoreColors.muted, fontSize: 12),
        ),
      ),
      Text(
        price,
        style: TextStyle(
          fontSize: 12,
          color: label == 'Frete' ? const Color(0xFF267245) : StoreColors.ink,
        ),
      ),
    ],
  );
}
