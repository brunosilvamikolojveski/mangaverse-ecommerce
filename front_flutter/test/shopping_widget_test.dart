import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mangaverse_flutter/main.dart';
import 'package:mangaverse_flutter/services/api_client.dart';

import 'fixtures.dart';

void main() {
  testWidgets(
    'permite corrigir os campos depois de uma falha de conexão no login',
    (tester) async {
      final api = ApiClient(
        client: MockClient((request) async {
          if (request.url.path == '/api/auth/login') {
            throw http.ClientException('Falha de rede');
          }
          final sessionResponse = guestSessionResponse(request);
          if (sessionResponse != null) {
            return sessionResponse;
          }
          if (request.url.path == '/api/categories') {
            return jsonResponse({'data': []});
          }
          return jsonResponse(catalogJson([]));
        }),
      );
      addTearDown(api.close);

      await tester.pumpWidget(MangaverseApp(api: api));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Entrar na conta'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('auth-email')),
        'leitor@mangaverse.test',
      );
      await tester.enterText(
        find.byKey(const ValueKey('auth-password')),
        'senha-teste',
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('auth-submit')).hitTestable(),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('auth-submit')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Não foi possível conectar'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('auth-email')),
        'outro@mangaverse.test',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Não foi possível conectar'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'adiciona pelo catálogo, atualiza a quantidade e remove pelo carrinho no celular',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var quantity = 0;
      final api = ApiClient(
        client: MockClient((request) async {
          if (request.url.path == '/api/cart') {
            return jsonResponse(cartJson(quantity: quantity));
          }
          if (request.url.path == '/api/cart/items') {
            quantity +=
                (jsonDecode(request.body) as Map<String, dynamic>)['quantity']
                    as int;
            return jsonResponse(cartJson(quantity: quantity));
          }
          if (request.url.path == '/api/cart/items/10') {
            quantity = request.method == 'DELETE'
                ? 0
                : (jsonDecode(request.body) as Map<String, dynamic>)['quantity']
                      as int;
            return request.method == 'DELETE'
                ? jsonResponse({}, status: 204)
                : jsonResponse(cartJson(quantity: quantity));
          }
          final sessionResponse = guestSessionResponse(request);
          if (sessionResponse != null) return sessionResponse;
          if (request.url.path == '/api/categories') {
            return jsonResponse({'data': []});
          }
          return jsonResponse(catalogJson([mangaJson(1)]));
        }),
      );
      addTearDown(api.close);

      await tester.pumpWidget(MangaverseApp(api: api));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Comprar').hitTestable(),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.widgetWithText(FilledButton, 'Comprar').hitTestable().first,
      );
      await tester.pumpAndSettle();
      expect(quantity, 1);
      await tester.scrollUntilVisible(
        find.byTooltip('Carrinho com 1 itens').hitTestable(),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byTooltip('Carrinho com 1 itens'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find
            .byTooltip('Aumentar quantidade de Mangá 1, volume 1')
            .hitTestable(),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byTooltip('Aumentar quantidade de Mangá 1, volume 1'),
      );
      await tester.pumpAndSettle();
      expect(quantity, 2);
      expect(find.textContaining('63,00'), findsAtLeastNWidgets(1));
      await tester.scrollUntilVisible(
        find.byTooltip('Remover Mangá 1 do carrinho').hitTestable(),
        -150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byTooltip('Remover Mangá 1 do carrinho'));
      await tester.pumpAndSettle();
      expect(find.text('Seu carrinho está vazio'), findsOneWidget);
      expect(quantity, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('mostra o erro de credenciais no campo de e-mail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApiClient(
      client: MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return jsonResponse({
            'message': 'E-mail ou senha incorretos.',
            'errors': {
              'email': ['E-mail ou senha incorretos.'],
            },
          }, status: 422);
        }
        final sessionResponse = guestSessionResponse(request);
        if (sessionResponse != null) return sessionResponse;
        if (request.url.path == '/api/categories') {
          return jsonResponse({'data': []});
        }
        return jsonResponse(catalogJson([]));
      }),
    );
    addTearDown(api.close);

    await tester.pumpWidget(MangaverseApp(api: api));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Entrar na conta'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'leitor@mangaverse.test',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-password')),
      'errada',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('auth-submit')).hitTestable(),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();
    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('limita o contador visual a 99+ em telas pequenas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApiClient(
      client: MockClient((request) async {
        if (request.url.path == '/api/cart') {
          return jsonResponse(cartJson(quantity: 120));
        }
        final sessionResponse = guestSessionResponse(request);
        if (sessionResponse != null) return sessionResponse;
        if (request.url.path == '/api/categories') {
          return jsonResponse({'data': []});
        }
        return jsonResponse(catalogJson([]));
      }),
    );
    addTearDown(api.close);

    await tester.pumpWidget(MangaverseApp(api: api));
    await tester.pumpAndSettle();
    expect(find.text('99+'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
