import 'package:material_ui/material_ui.dart';

import '../models/order.dart';
import '../services/order_service.dart';
import '../widgets/order_panel.dart';
import '../widgets/store_layout.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key, required this.orders, this.id});
  final OrderService orders;
  final int? id;
  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<StoreOrder> _orders = [];
  bool _loading = true;
  int? _busyId;
  String? _error;
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
      final orders = widget.id == null
          ? await widget.orders.list()
          : [await widget.orders.find(widget.id!)];
      if (mounted) setState(() => _orders = orders);
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _action(StoreOrder order, {bool cancel = false}) async {
    if (!await confirmAction(
      context,
      cancel ? 'Cancelar pedido?' : 'Confirmar pagamento de teste?',
      cancel
          ? 'Os itens voltarão ao estoque.'
          : 'Esta confirmação é simulada para o projeto acadêmico.',
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => _busyId = order.id);
    try {
      final updated = cancel
          ? await widget.orders.cancel(order.id)
          : await widget.orders.confirmPayment(order.id);
      if (mounted) {
        setState(
          () => _orders = _orders
              .map((item) => item.id == updated.id ? updated : item)
              .toList(),
        );
      }
    } catch (error) {
      if (mounted) showStoreNotice(context, errorMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) => StorePage(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeading(
          widget.id == null ? 'Meus pedidos' : 'Detalhes do pedido',
          subtitle: 'Acompanhe suas compras e pagamentos.',
          action: widget.id != null
              ? TextButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushReplacementNamed('/pedidos'),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Meus pedidos'),
                )
              : TextButton(
                  onPressed: _loading ? null : _load,
                  child: const Text('Atualizar pedidos'),
                ),
        ),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          StoreMessage(
            title: 'Não foi possível carregar os pedidos',
            message: _error!,
            actionLabel: 'Tentar novamente',
            onAction: _load,
            isError: true,
          )
        else if (_orders.isEmpty)
          StoreMessage(
            title: 'Você ainda não tem pedidos',
            message: 'Encontre sua próxima leitura no catálogo.',
            actionLabel: 'Explorar catálogo',
            onAction: () => Navigator.of(context).pushNamed('/'),
          )
        else
          for (final order in _orders)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: OrderPanel(
                order: order,
                showAddress: widget.id != null,
                actions: [
                  if (order.isPending)
                    FilledButton(
                      onPressed: _busyId != null ? null : () => _action(order),
                      child: Text(
                        _busyId == order.id
                            ? 'Aguarde…'
                            : 'Confirmar pagamento de teste',
                      ),
                    ),
                  if (order.isPending)
                    OutlinedButton(
                      onPressed: _busyId != null
                          ? null
                          : () => _action(order, cancel: true),
                      child: const Text('Cancelar pedido'),
                    ),
                  if (widget.id == null)
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context)
                              .pushNamed('/pedidos/${order.id}'),
                      child: const Text('Ver detalhes'),
                    ),
                ],
              ),
            ),
      ],
    ),
  );
}
