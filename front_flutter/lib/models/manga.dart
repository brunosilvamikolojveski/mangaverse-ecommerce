import '../utils/money.dart';

class Category {
  const Category({required this.name, required this.slug});

  factory Category.fromJson(Map<String, dynamic> json) =>
      Category(name: json['name'] as String, slug: json['slug'] as String);

  final String name;
  final String slug;
}

class Manga {
  const Manga({
    required this.id,
    required this.title,
    required this.volumeNumber,
    required this.price,
    required this.inStock,
    required this.seriesTitle,
    required this.authors,
    required this.categories,
    this.coverImageUrl,
    this.description,
    this.publisher,
    this.isbn,
    this.availableQuantity,
    this.seriesId,
    this.stock,
    this.isActive = true,
    this.publishedAt,
  });

  factory Manga.fromJson(Map<String, dynamic> json) {
    final series = json['series'] as Map<String, dynamic>;

    return Manga(
      id: json['id'] as int,
      title: json['title'] as String,
      volumeNumber: int.parse(json['volume_number'].toString()),
      price: json['price'].toString(),
      inStock: json['in_stock'] as bool,
      seriesTitle: series['title'] as String,
      authors: List<String>.from(series['authors'] as List),
      categories: (series['categories'] as List)
          .map((item) => Category.fromJson(item as Map<String, dynamic>))
          .toList(),
      coverImageUrl: json['cover_image_url'] as String?,
      description: json['description'] as String?,
      publisher: series['publisher'] as String?,
      isbn: json['isbn'] as String?,
      availableQuantity: json['available_quantity'] as int?,
      seriesId: series['id'] as int?,
      stock: json['stock'] == null ? null : int.parse(json['stock'].toString()),
      isActive: json['is_active'] as bool? ?? true,
      publishedAt: json['published_at'] as String?,
    );
  }

  final int id;
  final String title;
  final int volumeNumber;
  final String price;
  final bool inStock;
  final String seriesTitle;
  final List<String> authors;
  final List<Category> categories;
  final String? coverImageUrl;
  final String? description;
  final String? publisher;
  final String? isbn;
  final int? availableQuantity;
  final int? seriesId;
  final int? stock;
  final bool isActive;
  final String? publishedAt;

  String get formattedPrice => formatMoney(price);

  String get authorNames => authors.join(', ');
}

class CatalogPage {
  const CatalogPage({
    required this.mangas,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory CatalogPage.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>;

    return CatalogPage(
      mangas: (json['data'] as List)
          .map((item) => Manga.fromJson(item as Map<String, dynamic>))
          .toList(),
      currentPage: meta['current_page'] as int,
      lastPage: meta['last_page'] as int,
      total: meta['total'] as int,
    );
  }

  final List<Manga> mangas;
  final int currentPage;
  final int lastPage;
  final int total;
}
