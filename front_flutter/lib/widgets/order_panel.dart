import 'package:material_ui/material_ui.dart';

import '../models/order.dart';
import '../utils/money.dart';
import 'store_layout.dart';

class OrderBadge extends StatelessWidget {
  const OrderBadge(this.order, {super.key});
  final StoreOrder order;
  @override
  Widget build(BuildContext context) {
    final (color, background) = switch (order.status) {
      'paid' ||
      'delivered' => (const Color(0xFF175A35), const Color(0xFFE5F4E9)),
      'shipped' => (const Color(0xFF174E7A), const Color(0xFFE5F1F9)),
      'cancelled' => (const Color(0xFF802E2E), const Color(0xFFF9E7E7)),
      _ => (const Color(0xFF6A4E00), const Color(0xFFFFF2CA)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        order.statusLabel,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class OrderPanel extends StatelessWidget {
  const OrderPanel({
    super.key,
    required this.order,
    this.actions = const [],
    this.showAddress = false,
    this.admin = false,
  });
  final StoreOrder order;
  final List<Widget> actions;
  final bool showAddress;
  final bool admin;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFEBE7EE)),
      borderRadius: BorderRadius.circular(admin ? 12 : 8),
      boxShadow: admin
          ? const [
              BoxShadow(
                color: Color(0x0A0C1037),
                blurRadius: 7,
                offset: Offset(0, 2),
              ),
            ]
          : null,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
          decoration: BoxDecoration(
            color: admin ? Colors.white : const Color(0xFFFAF9FB),
            border: const Border(bottom: BorderSide(color: Color(0xFFEBE7EE))),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    admin ? 'PEDIDO #${order.id}' : 'Pedido #${order.id}',
                    style: TextStyle(
                      fontSize: admin ? 11 : 16,
                      letterSpacing: admin ? .7 : 0,
                      fontWeight: FontWeight.w600,
                      color: admin ? StoreColors.purple : StoreColors.ink,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${formatOrderDate(order.placedAt)}${admin ? ' · ${order.items.length} item(ns)' : ''}',
                    style: const TextStyle(
                      color: StoreColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              OrderBadge(order),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (admin && showAddress)
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 750) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _products(),
                          const SizedBox(height: 16),
                          _shippingAddress(),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 15, child: _products()),
                        const SizedBox(width: 25),
                        Expanded(flex: 8, child: _shippingAddress()),
                      ],
                    );
                  },
                )
              else
                _products(),
              if (showAddress && !admin) ...[
                const SizedBox(height: 20),
                _shippingAddress(),
                const SizedBox(height: 20),
                _summaryRow('Subtotal', order.formattedSubtotal),
                const SizedBox(height: 12),
                _summaryRow('Frete', order.formattedShippingCost),
              ],
              const Divider(height: 28, color: Color(0xFFEBE7EE)),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 20,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pagamento: ${order.paymentLabel}',
                        style: const TextStyle(
                          color: StoreColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      if (showAddress && !admin && order.paidAt != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Pago em ${formatOrderDate(order.paidAt)}',
                          style: const TextStyle(
                            color: StoreColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        'Total: ${order.formattedTotal}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (actions.isNotEmpty)
                    Theme(
                      data: Theme.of(context).copyWith(
                        filledButtonTheme: FilledButtonThemeData(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(40, 36),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            textStyle: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        outlinedButtonTheme: OutlinedButtonThemeData(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(40, 36),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            textStyle: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      child: Wrap(spacing: 9, runSpacing: 9, children: actions),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _summaryRow(String label, String value) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: StoreColors.muted, fontSize: 13),
        ),
      ),
      Text(value, style: const TextStyle(fontSize: 13)),
    ],
  );

  Widget _products() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final item in order.items)
        Padding(
          padding: EdgeInsets.only(bottom: admin ? 16 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${admin ? '${item.quantity} × ' : ''}${item.title} · Vol. ${item.volume}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF514D54),
                      ),
                    ),
                    if (!admin) ...[
                      const SizedBox(height: 5),
                      Text(
                        '${item.quantity} × ${formatMoney(item.unitPrice)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: StoreColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Text(
                formatMoney(item.lineTotal),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
    ],
  );

  Widget _shippingAddress() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: StoreColors.lavender,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          admin
              ? 'Entrega para ${order.address['recipient_name']}'
              : 'Endereço de entrega',
          style: const TextStyle(
            color: StoreColors.purple,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          '${admin ? '' : '${order.address['recipient_name']}\n'}'
          '${order.address['street']}, ${order.address['number']}'
          '${order.address['complement'] == null ? '' : ' · ${order.address['complement']}'}'
          '${admin ? ' — ' : '\n'}${order.address['neighborhood']}, '
          '${order.address['city']} - ${order.address['state']}'
          '${admin ? ' · ' : '\n'}CEP ${order.address['postal_code']}',
          style: const TextStyle(
            color: StoreColors.muted,
            fontSize: 12,
            height: 1.7,
          ),
        ),
      ],
    ),
  );
}
