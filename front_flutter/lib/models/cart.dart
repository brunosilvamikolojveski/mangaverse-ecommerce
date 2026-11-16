import '../utils/money.dart';

class Cart {
  const Cart({required this.id, required this.items, required this.subtotal});

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
    id: json['id'] as int,
    items: (json['items'] as List)
        .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
        .toList(),
    subtotal: json['subtotal'].toString(),
  );

  final int id;
  final List<CartItem> items;
  final String subtotal;

  int get itemCount => items.fold(0, (total, item) => total + item.quantity);
  String get formattedSubtotal => formatMoney(subtotal);

  int quantityForManga(int id) => items
      .where((item) => item.manga.id == id)
      .fold(0, (total, item) => total + item.quantity);
}

class CartItem {
  const CartItem({
    required this.id,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.manga,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'] as int,
    quantity: json['quantity'] as int,
    unitPrice: json['unit_price'].toString(),
    lineTotal: json['line_total'].toString(),
    manga: CartManga.fromJson(json['manga'] as Map<String, dynamic>),
  );

  final int id;
  final int quantity;
  final String unitPrice;
  final String lineTotal;
  final CartManga manga;

  String get formattedUnitPrice => formatMoney(unitPrice);
  String get formattedLineTotal => formatMoney(lineTotal);
}

class CartManga {
  const CartManga({
    required this.id,
    required this.title,
    required this.volumeNumber,
    required this.series,
    required this.isActive,
    required this.inStock,
  });

  factory CartManga.fromJson(Map<String, dynamic> json) => CartManga(
    id: json['id'] as int,
    title: json['title'] as String,
    volumeNumber: json['volume_number'] as int,
    series: json['series'] as String,
    isActive: json['is_active'] as bool,
    inStock: json['in_stock'] as bool,
  );

  final int id;
  final String title;
  final int volumeNumber;
  final String series;
  final bool isActive;
  final bool inStock;

  bool get isAvailable => isActive && inStock;
}
