import '../models/manga.dart';
import '../models/upload_file.dart';
import 'api_client.dart';

enum RecordKind {
  series('Séries', 'série'),
  authors('Autores', 'autor'),
  categories('Categorias', 'categoria');

  const RecordKind(this.label, this.singular);
  final String label;
  final String singular;
  String get path => '/api/admin/$name';
}

class AdminService {
  const AdminService(this.api);
  final ApiClient api;
  Future<List<Manga>> mangas() async {
    final mangas = <Manga>[];
    var page = 1;
    var lastPage = 1;
    do {
      final response = await api.get(
        '/api/admin/mangas',
        query: {'per_page': '50', 'page': '$page'},
      );
      final result = CatalogPage.fromJson(response);
      mangas.addAll(result.mangas);
      lastPage = result.lastPage;
      page++;
    } while (page <= lastPage);
    return mangas;
  }

  Future<List<Map<String, dynamic>>> records(RecordKind kind) async {
    final response = await api.get(kind.path);
    return (response['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> saveRecord(
    RecordKind kind,
    Map<String, dynamic> values, {
    int? id,
  }) async {
    if (id == null) {
      await api.post(kind.path, values);
    } else {
      await api.patch('${kind.path}/$id', values);
    }
  }

  Future<void> deleteRecord(RecordKind kind, int id) =>
      api.delete('${kind.path}/$id');
  Future<Manga> saveManga(Map<String, dynamic> data, {int? id}) async {
    final values = Map<String, dynamic>.of(data);
    final cover = values.remove('cover_image') as UploadFile?;
    final path = '/api/admin/mangas${id == null ? '' : '/$id'}';
    final response = cover != null
        ? await api.upload(
            path,
            values: values,
            file: cover,
            update: id != null,
          )
        : id == null
        ? await api.post(path, values)
        : await api.patch(path, values);
    return Manga.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deactivateManga(int id) => api.delete('/api/admin/mangas/$id');
}
