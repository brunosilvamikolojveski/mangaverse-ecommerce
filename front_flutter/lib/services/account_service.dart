import '../models/address.dart';
import '../models/user.dart';
import 'api_client.dart';

class AccountService {
  const AccountService(this.api);
  final ApiClient api;
  Future<List<Address>> addresses() async {
    final response = await api.get('/api/addresses');
    return (response['data'] as List)
        .map((item) => Address.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Address> saveAddress(Map<String, dynamic> data, {int? id}) async {
    final response = id == null
        ? await api.post('/api/addresses', data)
        : await api.patch('/api/addresses/$id', data);
    return Address.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteAddress(int id) => api.delete('/api/addresses/$id');
  Future<StoreUser> updateProfile(Map<String, dynamic> data) async {
    final response = await api.patch('/api/user', data);
    return StoreUser.fromJson(response['data'] as Map<String, dynamic>);
  }
}
