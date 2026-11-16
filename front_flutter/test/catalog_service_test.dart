import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangaverse_flutter/services/api_client.dart';
import 'package:mangaverse_flutter/services/catalog_service.dart';

import 'fixtures.dart';

void main() {
  test(
    'envia filtros combinados e página para a API e lê os relacionamentos',
    () async {
      final api = ApiClient(
        baseUrl: 'http://localhost:8000',
        client: MockClient((request) async {
          final sessionResponse = guestSessionResponse(request);
          if (sessionResponse != null) return sessionResponse;
          expect(request.url.path, '/api/mangas');
          expect(request.url.queryParameters, {
            'search': 'ação & aventura',
            'category': 'shonen',
            'sort': 'price_asc',
            'page': '2',
            'per_page': '12',
          });
          expect(request.headers['Accept'], 'application/json');
          return jsonResponse(
            catalogJson([mangaJson(13)], page: 2, lastPage: 3, total: 29),
          );
        }),
      );
      addTearDown(api.close);
      final result = await CatalogService(api).list(
        search: 'ação & aventura',
        category: 'shonen',
        sort: 'price_asc',
        page: 2,
      );
      expect(result.currentPage, 2);
      expect(result.lastPage, 3);
      expect(result.total, 29);
      expect(result.mangas.single.seriesTitle, 'One Piece');
      expect(result.mangas.single.authorNames, 'Eiichiro Oda');
      expect(result.mangas.single.categories.single.slug, 'shonen');
      expect(
        result.mangas.single.formattedPrice.replaceAll('\u00a0', ' '),
        'R\$ 31,50',
      );
    },
  );

  test(
    'busca detalhes e mantém a disponibilidade recebida do servidor',
    () async {
      final api = ApiClient(
        client: MockClient((request) async {
          final sessionResponse = guestSessionResponse(request);
          if (sessionResponse != null) return sessionResponse;
          expect(request.url.path, '/api/mangas/5');
          return jsonResponse({'data': mangaJson(5, inStock: false)});
        }),
      );
      addTearDown(api.close);
      final manga = await CatalogService(api).find(5);
      expect(manga.id, 5);
      expect(manga.inStock, isFalse);
      expect(manga.availableQuantity, 0);
    },
  );

  test('traduz um 404 sem expor a exceção interna do Laravel', () async {
    final api = ApiClient(
      client: MockClient((request) async {
        final response = guestSessionResponse(request);
        if (response != null) return response;
        return jsonResponse({
          'message': 'No query results for model',
        }, status: 404);
      }),
    );
    addTearDown(api.close);
    await expectLater(
      CatalogService(api).find(999),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'status', 404)
            .having(
              (error) => error.message,
              'mensagem',
              contains('indisponível'),
            ),
      ),
    );
  });

  test('trata resposta HTML de um proxy como erro de API', () async {
    final api = ApiClient(
      client: MockClient((request) async {
        final response = guestSessionResponse(request);
        if (response != null) return response;
        return http.Response('<html>Bad gateway</html>', 502);
      }),
    );
    addTearDown(api.close);
    await expectLater(
      CatalogService(api).list(),
      throwsA(
        isA<ApiException>().having((error) => error.statusCode, 'status', 502),
      ),
    );
  });
}
