import '../models/order.dart';
import 'api_client.dart';

class OrderService {
  const OrderService(this.api);
  final ApiClient api;
  StoreOrder _order(Map<String, dynamic> response) =>
      StoreOrder.fromJson(response['data'] as Map<String, dynamic>);
  Future<List<StoreOrder>> list({bool admin = false}) async {
    final response = await api.get(admin ? '/api/admin/orders' : '/api/orders');
    return (response['data'] as List)
        .map((item) => StoreOrder.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<StoreOrder> find(int id) async =>
      _order(await api.get('/api/orders/$id'));
  Future<StoreOrder> create({
    required int addressId,
    required String paymentMethod,
  }) async => _order(
    await api.post('/api/orders', {
      'address_id': addressId,
      'payment_method': paymentMethod,
    }),
  );
  Future<StoreOrder> confirmPayment(int id) async =>
      _order(await api.post('/api/orders/$id/confirm-payment', {}));
  Future<StoreOrder> cancel(int id) async =>
      _order(await api.post('/api/orders/$id/cancel', {}));
  Future<StoreOrder> updateStatus(int id, String status) async => _order(
    await api.patch('/api/admin/orders/$id/status', {'status': status}),
  );
}
