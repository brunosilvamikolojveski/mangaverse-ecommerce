import 'package:material_ui/material_ui.dart';

import '../models/order.dart';
import '../services/order_service.dart';
import '../widgets/admin_layout.dart';
import '../widgets/admin_components.dart';
import '../widgets/order_panel.dart';
import '../widgets/store_layout.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key, required this.orders});
  final OrderService orders;
  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  List<StoreOrder> _orders = [];
  String _status = 'all';
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
      final orders = await widget.orders.list(admin: true);
      if (mounted) setState(() => _orders = orders);
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _update(StoreOrder order) async {
    final status = order.nextStatus!;
    if (!await confirmAction(
      context,
      'Atualizar pedido #${order.id}?',
      'O pedido ficará com o status: ${orderStatuses[status]}.',
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => _busyId = order.id);
    try {
      final updated = await widget.orders.updateStatus(order.id, status);
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
  Widget build(BuildContext context) {
    final filtered = _orders
        .where((order) => _status == 'all' || order.status == _status)
        .toList();
    return AdminLayout(
      path: '/admin/pedidos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminHeading(
            'Gestão de pedidos',
            subtitle: 'Veja as compras recentes e acompanhe o andamento das entregas.',
            action: OutlinedButton.icon(
              onPressed: _loading || _busyId != null ? null : _load,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Atualizar pedidos'),
            ),
          ),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              AdminStat(
                'Pedidos totais',
                '${_orders.length}',
                caption: 'Em todos os status',
                columns: 4,
              ),
              AdminStat(
                'Aguardando pagamento',
                '${_orders.where((o) => o.isPending).length}',
                caption: 'Pedidos pendentes',
                accent: const Color(0xFFE4A829),
                columns: 4,
              ),
              AdminStat(
                'Em andamento',
                '${_orders.where((o) => {'paid', 'shipped'}.contains(o.status)).length}',
                caption: 'Pagos ou enviados',
                accent: const Color(0xFF3F78A8),
                columns: 4,
              ),
              AdminStat(
                'Entregues',
                '${_orders.where((o) => o.status == 'delivered').length}',
                caption: 'Pedidos concluídos',
                accent: const Color(0xFF39916A),
                columns: 4,
              ),
            ],
          ),
          const SizedBox(height: 24),
          AdminTabs(
            labels: const {
              'all': 'Todos',
              'pending': 'Aguardando',
              'paid': 'Pagos',
              'shipped': 'Enviados',
              'delivered': 'Entregues',
              'cancelled': 'Cancelados',
            },
            counts: {
              for (final status in ['all', ...orderStatuses.keys])
                status: _orders
                    .where((o) => status == 'all' || o.status == status)
                    .length,
            },
            value: _status,
            onChanged: (value) => setState(() => _status = value),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            StoreMessage(
              title: 'Não foi possível carregar os pedidos',
              message: _error!,
              actionLabel: 'Tentar novamente',
              onAction: _load,
              isError: true,
            )
          else if (filtered.isEmpty)
            const AdminEmptyState(
              title: 'Nenhum pedido neste filtro',
              message: 'Quando houver pedidos, eles aparecerão aqui.',
              icon: Icons.receipt_long_outlined,
            )
          else
            for (final order in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: OrderPanel(
                  order: order,
                  showAddress: true,
                  admin: true,
                  actions: [
                    if (order.nextStatus != null)
                      order.nextStatus == 'cancelled'
                          ? OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF802E2E),
                                side: const BorderSide(
                                  color: Color(0xFFD8B8B8),
                                ),
                              ),
                              onPressed: _busyId != null
                                  ? null
                                  : () => _update(order),
                              child: Text(
                                _busyId == order.id
                                    ? 'Atualizando…'
                                    : 'Cancelar pedido',
                              ),
                            )
                          : FilledButton(
                              onPressed: _busyId != null
                                  ? null
                                  : () => _update(order),
                              child: Text(
                                _busyId == order.id
                                    ? 'Atualizando…'
                                    : order.nextStatus == 'shipped'
                                    ? 'Marcar como enviado'
                                    : 'Marcar como entregue',
                              ),
                            ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
