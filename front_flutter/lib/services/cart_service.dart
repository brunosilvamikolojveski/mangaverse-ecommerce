import '../models/cart.dart';
import 'api_client.dart';

class CartService {
  const CartService(this.api);

  final ApiClient api;

  Cart _cart(Map<String, dynamic> response) =>
      Cart.fromJson(response['data'] as Map<String, dynamic>);

  Future<Cart> load() async => _cart(await api.get('/api/cart'));

  Future<Cart> addItem(int mangaId, int quantity) async => _cart(
    await api.post('/api/cart/items', {
      'manga_id': mangaId,
      'quantity': quantity,
    }),
  );

  Future<Cart> updateItem(int itemId, int quantity) async =>
      _cart(await api.patch('/api/cart/items/$itemId', {'quantity': quantity}));

  Future<Cart> removeItem(int itemId) async {
    await api.delete('/api/cart/items/$itemId');
    return load();
  }

  Future<Cart> clear() async {
    await api.delete('/api/cart');
    return load();
  }
}
