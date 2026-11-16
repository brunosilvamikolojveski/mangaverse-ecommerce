import '../utils/money.dart';

const orderStatuses = {
  'pending': 'Aguardando pagamento',
  'paid': 'Pago',
  'shipped': 'Enviado',
  'delivered': 'Entregue',
  'cancelled': 'Cancelado',
};
const paymentMethods = {
  'pix': 'Pix',
  'boleto': 'Boleto',
  'credit_card': 'Cartão de crédito',
};
const seriesStatuses = {
  'ongoing': 'Em andamento',
  'completed': 'Concluída',
  'hiatus': 'Hiato',
};

String formatOrderDate(String? value) {
  final date = DateTime.tryParse(value ?? '')?.toLocal();
  if (date == null) return 'Data indisponível';
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year} às ${two(date.hour)}:${two(date.minute)}';
}

class StoreOrder {
  const StoreOrder({
    required this.id,
    required this.status,
    required this.total,
    required this.address,
    required this.items,
    required this.payments,
    this.placedAt,
  });
  factory StoreOrder.fromJson(Map<String, dynamic> json) => StoreOrder(
    id: json['id'] as int,
    status: json['status'] as String,
    total: json['total'].toString(),
    address: json['shipping_address'] as Map<String, dynamic>,
    items: (json['items'] as List)
        .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
        .toList(),
    payments: (json['payments'] as List)
        .map((payment) => Map<String, dynamic>.from(payment as Map))
        .toList(),
    placedAt: json['placed_at'] as String?,
  );
  final int id;
  final String status;
  final String total;
  final String? placedAt;
  final Map<String, dynamic> address;
  final List<OrderItem> items;
  final List<Map<String, dynamic>> payments;
  bool get isPending => status == 'pending';
  String get statusLabel => orderStatuses[status] ?? status;
  String get formattedTotal => formatMoney(total);
  String get paymentLabel => payments.isEmpty
      ? 'Não informado'
      : paymentMethods[payments.first['method']] ??
            payments.first['method'].toString();
  String? get nextStatus => {
    'pending': 'cancelled',
    'paid': 'shipped',
    'shipped': 'delivered',
  }[status];
}

class OrderItem {
  const OrderItem({
    required this.id,
    required this.title,
    required this.volume,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });
  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    id: json['id'] as int,
    title: json['manga_title'] as String,
    volume: json['volume_number'] as int,
    quantity: json['quantity'] as int,
    unitPrice: json['unit_price'].toString(),
    lineTotal: json['line_total'].toString(),
  );
  final int id;
  final String title;
  final int volume;
  final int quantity;
  final String unitPrice;
  final String lineTotal;
}
