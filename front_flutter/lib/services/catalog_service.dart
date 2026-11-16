import '../models/manga.dart';
import 'api_client.dart';

class CatalogService {
  const CatalogService(this.api);

  final ApiClient api;

  Future<CatalogPage> list({
    String search = '',
    String? category,
    String sort = 'newest',
    int page = 1,
  }) async {
    final response = await api.get(
      '/api/mangas',
      query: {
        'per_page': '12',
        'page': '$page',
        'sort': sort,
        if (search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );

    return CatalogPage.fromJson(response);
  }

  Future<List<Category>> categories() async {
    final response = await api.get('/api/categories');

    return (response['data'] as List)
        .map((item) => Category.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Manga> find(int id) async {
    final response = await api.get('/api/mangas/$id');

    return Manga.fromJson(response['data'] as Map<String, dynamic>);
  }
}
