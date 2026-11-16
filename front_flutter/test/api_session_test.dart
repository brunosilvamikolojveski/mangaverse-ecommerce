import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangaverse_flutter/services/api_client.dart';

import 'fixtures.dart';

void main() {
  test('inicializa uma única sessão antes de consultas concorrentes', () async {
    final paths = <String>[];
    final api = ApiClient(
      client: MockClient((request) async {
        paths.add(request.url.path);
        if (request.url.path == '/sanctum/csrf-cookie') {
          return http.Response('', 204);
        }
        return jsonResponse({'data': []});
      }),
    );
    addTearDown(api.close);

    await Future.wait([api.get('/api/user'), api.get('/api/cart')]);

    expect(paths.first, '/sanctum/csrf-cookie');
    expect(paths.where((path) => path == '/sanctum/csrf-cookie'), hasLength(1));
    expect(paths, containsAll(['/api/user', '/api/cart']));
  });

  test(
    'envia o CSRF atualizado e repete apenas uma requisição rejeitada com 419',
    () async {
      var tokenVersion = 0;
      var posts = 0;
      final sentTokens = <String?>[];
      final api = ApiClient(
        readXsrfToken: () => 'csrf-$tokenVersion',
        client: MockClient((request) async {
          if (request.url.path == '/sanctum/csrf-cookie') {
            tokenVersion++;
            return http.Response('', 204);
          }
          expect(request.method, 'POST');
          expect(jsonDecode(request.body), {'manga_id': 1, 'quantity': 2});
          sentTokens.add(request.headers['X-XSRF-TOKEN']);
          if (++posts == 1) {
            return jsonResponse({
              'message': 'CSRF token mismatch.',
            }, status: 419);
          }
          return jsonResponse(cartJson(quantity: 2));
        }),
      );
      addTearDown(api.close);

      await api.post('/api/cart/items', {'manga_id': 1, 'quantity': 2});

      expect(posts, 2);
      expect(sentTokens, ['csrf-2', 'csrf-3']);
    },
  );

  test('aceita DELETE 204 sem tentar ler um JSON vazio', () async {
    final api = ApiClient(
      client: MockClient((request) async {
        if (request.url.path == '/sanctum/csrf-cookie') {
          return http.Response('', 204);
        }
        expect(request.method, 'DELETE');
        return http.Response('', 204);
      }),
    );
    addTearDown(api.close);

    await expectLater(api.delete('/api/cart/items/10'), completes);
  });

  test(
    'não repete um POST com falha de rede para evitar inclusão duplicada',
    () async {
      var posts = 0;
      final api = ApiClient(
        client: MockClient((request) async {
          if (request.url.path == '/sanctum/csrf-cookie') {
            return http.Response('', 204);
          }
          posts++;
          throw http.ClientException('Falha de rede');
        }),
      );
      addTearDown(api.close);

      await expectLater(
        api.post('/api/cart/items', {'manga_id': 1, 'quantity': 1}),
        throwsA(isA<ApiException>()),
      );
      expect(posts, 1);
    },
  );
}
