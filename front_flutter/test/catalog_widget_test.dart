import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mangaverse_flutter/main.dart';
import 'package:mangaverse_flutter/services/api_client.dart';

import 'fixtures.dart';

void main() {
  testWidgets(
    'uma busca antiga não substitui o resultado da busca mais recente',
    (tester) async {
      final oldSearch = Completer<http.Response>();
      final api = ApiClient(
        client: MockClient((request) async {
          final sessionResponse = guestSessionResponse(request);
          if (sessionResponse != null) return sessionResponse;
          if (request.url.path == '/api/categories') {
            return jsonResponse({'data': []});
          }
          final search = request.url.queryParameters['search'];
          if (search == 'antiga') {
            return oldSearch.future;
          }
          return jsonResponse(
            catalogJson([
              mangaJson(
                1,
                title: search == 'nova' ? 'Resultado novo' : 'Volume inicial',
              ),
            ]),
          );
        }),
      );
      addTearDown(api.close);
      await tester.pumpWidget(MangaverseApp(api: api));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'antiga');
      await tester.pump(const Duration(milliseconds: 351));
      await tester.enterText(find.byType(TextField), 'nova');
      await tester.pump(const Duration(milliseconds: 351));
      await tester.pumpAndSettle();
      oldSearch.complete(
        jsonResponse(catalogJson([mangaJson(2, title: 'Resultado antigo')])),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Resultado novo · Vol. 1').hitTestable(),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Resultado novo · Vol. 1'), findsOneWidget);
      expect(find.text('Resultado antigo · Vol. 2'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('exibe catálogo no celular e abre os detalhes do mangá', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApiClient(
      client: MockClient((request) async {
        final sessionResponse = guestSessionResponse(request);
        if (sessionResponse != null) return sessionResponse;
        if (request.url.path == '/api/categories') {
          return jsonResponse({
            'data': [
              {'name': 'Shōnen', 'slug': 'shonen'},
            ],
          });
        }
        if (request.url.path == '/api/mangas/1') {
          return jsonResponse({'data': mangaJson(1)});
        }
        return jsonResponse(catalogJson([mangaJson(1), mangaJson(2)]));
      }),
    );
    addTearDown(api.close);
    await tester.pumpWidget(MangaverseApp(api: api));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Mangá 1 · Vol. 1').hitTestable(),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Mangá 1 · Vol. 1').hitTestable().first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Sobre este volume').hitTestable(),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Sobre este volume'), findsOneWidget);
    expect(find.text('Descrição do volume 1.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('oferece nova tentativa quando a API falha', (tester) async {
    var attempts = 0;
    final api = ApiClient(
      client: MockClient((request) async {
        final sessionResponse = guestSessionResponse(request);
        if (sessionResponse != null) return sessionResponse;
        if (request.url.path == '/api/categories') {
          return jsonResponse({'data': []});
        }
        if (++attempts == 1) {
          return jsonResponse({}, status: 500);
        }
        return jsonResponse(catalogJson([mangaJson(1)]));
      }),
    );
    addTearDown(api.close);
    await tester.pumpWidget(MangaverseApp(api: api));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Tentar novamente').hitTestable(),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Não foi possível carregar o catálogo'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
