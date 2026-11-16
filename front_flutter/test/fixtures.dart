import 'dart:convert';

import 'package:http/http.dart' as http;

http.Response jsonResponse(Object data, {int status = 200}) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> mangaJson(int id, {String? title, bool inStock = true}) =>
    {
      'id': id,
      'title': title ?? 'Mangá $id',
      'volume_number': id,
      'description': 'Descrição do volume $id.',
      'price': '31.50',
      'in_stock': inStock,
      'is_active': true,
      'cover_image_url': null,
      'available_quantity': inStock ? 4 : 0,
      'isbn': null,
      'series': {
        'id': 1,
        'title': 'One Piece',
        'slug': 'one-piece',
        'publisher': 'Panini',
        'authors': ['Eiichiro Oda'],
        'categories': [
          {'name': 'Shōnen', 'slug': 'shonen'},
        ],
      },
    };

Map<String, dynamic> catalogJson(
  List<Map<String, dynamic>> mangas, {
  int page = 1,
  int lastPage = 1,
  int? total,
}) => {
  'data': mangas,
  'meta': {
    'current_page': page,
    'last_page': lastPage,
    'total': total ?? mangas.length,
  },
};

Map<String, dynamic> cartJson({int quantity = 0, int cartId = 1}) => {
  'data': {
    'id': cartId,
    'items': quantity == 0
        ? []
        : [
            {
              'id': 10,
              'quantity': quantity,
              'unit_price': '31.50',
              'line_total': (quantity * 31.5).toStringAsFixed(2),
              'manga': {
                'id': 1,
                'title': 'Mangá 1',
                'volume_number': 1,
                'series': 'One Piece',
                'is_active': true,
                'in_stock': true,
              },
            },
          ],
    'subtotal': (quantity * 31.5).toStringAsFixed(2),
  },
};

Map<String, dynamic> userJson() => {
  'id': 7,
  'name': 'Leitor Teste',
  'email': 'leitor@mangaverse.test',
  'role': 'customer',
};

http.Response? guestSessionResponse(http.Request request) {
  if (request.method != 'GET') return null;
  return switch (request.url.path) {
    '/sanctum/csrf-cookie' => http.Response('', 204),
    '/api/user' => jsonResponse({'message': 'Unauthenticated.'}, status: 401),
    '/api/cart' => jsonResponse(cartJson()),
    _ => null,
  };
}
