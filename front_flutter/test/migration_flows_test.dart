import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mangaverse_flutter/main.dart';
import 'package:mangaverse_flutter/models/upload_file.dart';
import 'package:mangaverse_flutter/models/manga.dart';
import 'package:mangaverse_flutter/models/order.dart';
import 'package:mangaverse_flutter/widgets/order_panel.dart';
import 'package:mangaverse_flutter/services/admin_service.dart';
import 'package:mangaverse_flutter/services/api_client.dart';
import 'package:mangaverse_flutter/widgets/editor_form.dart';

import 'fixtures.dart';

Map<String, dynamic> orderJson({String status = 'pending'}) => {
  'data': {
    'id': 9,
    'status': status,
    'subtotal': '31.50',
    'shipping_cost': '0.00',
    'total': '31.50',
    'shipping_address': {
      'recipient_name': 'Leitor',
      'street': 'Rua Teste',
      'number': '123',
      'neighborhood': 'Centro',
      'city': 'Curitiba',
      'state': 'PR',
      'postal_code': '80000-000',
      'complement': null,
    },
    'items': [
      {
        'id': 1,
        'manga_title': 'Mangá 1',
        'volume_number': 1,
        'quantity': 1,
        'unit_price': '31.50',
        'line_total': '31.50',
      },
    ],
    'payments': [
      {'method': 'pix', 'status': status},
    ],
    'placed_at': '2026-11-15T12:00:00Z',
  },
};

void main() {
  for (final shippingCost in ['0.00', '12.90']) {
    testWidgets(
      'detalhes mostram valores e data do pagamento com frete $shippingCost',
      (tester) async {
        final data = orderJson(status: 'paid')['data'] as Map<String, dynamic>;
        data['shipping_cost'] = shippingCost;
        data['total'] = shippingCost == '0.00' ? '31.50' : '44.40';
        (data['payments'] as List).first['paid_at'] = '2026-11-15T12:30:00Z';
        final order = StoreOrder.fromJson(data);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: OrderPanel(order: order, showAddress: true),
              ),
            ),
          ),
        );
        expect(find.text('Subtotal'), findsOneWidget);
        expect(find.text('Frete'), findsOneWidget);
        expect(find.text(order.formattedSubtotal), findsAtLeastNWidgets(1));
        expect(find.text(order.formattedShippingCost), findsOneWidget);
        expect(find.text('Total: ${order.formattedTotal}'), findsOneWidget);
        expect(
          find.text('Pago em ${formatOrderDate(order.paidAt)}'),
          findsOneWidget,
        );
        expect(order.paidAt, '2026-11-15T12:30:00Z');
        expect(tester.takeException(), isNull);
      },
    );
  }

  test(
    'aceita inteiros enviados como texto na resposta de upload do Laravel',
    () {
      final data = mangaJson(1)
        ..['volume_number'] = '3'
        ..['stock'] = '5';
      final manga = Manga.fromJson(data);
      expect(manga.volumeNumber, 3);
      expect(manga.stock, 5);
    },
  );

  test(
    'recria o multipart após 419 e preserva PATCH, campos vazios e capa',
    () async {
      var uploads = 0;
      final api = ApiClient(
        readXsrfToken: () => 'token',
        client: MockClient((request) async {
          if (request.url.path == '/sanctum/csrf-cookie') {
            return http.Response('', 204);
          }
          uploads++;
          expect(request.method, 'POST');
          expect(request.headers['X-XSRF-TOKEN'], 'token');
          expect(
            request.headers['content-type'],
            startsWith('multipart/form-data; boundary='),
          );
          final body = utf8.decode(request.bodyBytes);
          expect(body, contains('name="_method"\r\n\r\nPATCH'));
          expect(body, contains('filename="capa.png"'));
          expect(
            RegExp(r'name="description"\r\n(?:[^\r\n]+\r\n)*\r\n\r\n--')
                .hasMatch(body),
            isTrue,
          );
          expect(body, contains('imagem-teste'));
          return uploads == 1
              ? jsonResponse({}, status: 419)
              : jsonResponse({'data': mangaJson(1)});
        }),
      );
      addTearDown(api.close);
      await api.upload(
        '/api/admin/mangas/1',
        values: {'description': null, 'is_active': true},
        file: UploadFile(
          name: 'capa.png',
          bytes: Uint8List.fromList(utf8.encode('imagem-teste')),
        ),
        update: true,
      );
      expect(uploads, 2);
    },
  );

  test('catálogo administrativo lê todas as páginas', () async {
    final pages = <String?>[];
    final api = ApiClient(
      client: MockClient((request) async {
        if (request.url.path == '/sanctum/csrf-cookie') {
          return http.Response('', 204);
        }
        pages.add(request.url.queryParameters['page']);
        final page = int.parse(pages.last!);
        return jsonResponse(
          catalogJson([mangaJson(page)], page: page, lastPage: 2),
        );
      }),
    );
    addTearDown(api.close);
    expect((await AdminService(api).mangas()).map((m) => m.id), [1, 2]);
    expect(pages, ['1', '2']);
  });

  testWidgets(
    'cliente não abre cadastros administrativos nem consulta a API de admin',
    (tester) async {
      final adminPaths = <String>[];
      final api = ApiClient(
        client: MockClient((request) async {
          if (request.url.path.startsWith('/api/admin/')) {
            adminPaths.add(request.url.path);
          }
          if (request.url.path == '/api/user') {
            return jsonResponse({'data': userJson()});
          }
          final session = guestSessionResponse(request);
          if (session != null) return session;
          if (request.url.path == '/api/categories') {
            return jsonResponse({'data': []});
          }
          return jsonResponse(catalogJson([]));
        }),
      );
      addTearDown(api.close);
      await tester.pumpWidget(MangaverseApp(api: api));
      await tester.pumpAndSettle();
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .pushNamed('/admin/cadastros');
      await tester.pumpAndSettle();
      expect(find.text('Acesso restrito'), findsOneWidget);
      expect(adminPaths, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'atualiza pedidos sem esconder a lista e permite tentar novamente após falha',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1050);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var reads = 0;
      var refresh = Completer<http.Response>();
      final api = ApiClient(
        client: MockClient((request) async {
          if (request.url.path == '/api/admin/orders') {
            reads++;
            if (reads == 1) {
              return jsonResponse({
                'data': [orderJson()['data']],
              });
            }
            return refresh.future;
          }
          if (request.url.path == '/api/user') {
            return jsonResponse({'data': userJson()..['role'] = 'admin'});
          }
          final session = guestSessionResponse(request);
          if (session != null) return session;
          if (request.url.path == '/api/categories') {
            return jsonResponse({'data': []});
          }
          return jsonResponse(catalogJson([]));
        }),
      );
      addTearDown(api.close);
      await tester.pumpWidget(MangaverseApp(api: api));
      await tester.pumpAndSettle();
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .pushNamed('/admin/pedidos');
      await tester.pumpAndSettle();
      expect(find.text('PEDIDO #9'), findsOneWidget);
      await tester.tap(find.text('Atualizar pedidos'));
      await tester.pump();
      expect(find.text('Atualizando…'), findsOneWidget);
      expect(find.text('PEDIDO #9'), findsOneWidget);
      await tester.tap(find.text('Atualizando…'));
      await tester.pump();
      expect(reads, 2);
      refresh.complete(
        jsonResponse({'message': 'Falha temporária'}, status: 500),
      );
      await tester.pumpAndSettle();
      expect(find.text('PEDIDO #9'), findsOneWidget);
      expect(
        find.text('Não foi possível concluir a solicitação. Tente novamente.'),
        findsOneWidget,
      );
      refresh = Completer<http.Response>();
      await tester.tap(find.text('Atualizar pedidos'));
      await tester.pump();
      refresh.complete(
        jsonResponse({
          'data': [orderJson(status: 'paid')['data']],
        }),
      );
      await tester.pumpAndSettle();
      expect(reads, 3);
      expect(find.text('Pago'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'checkout seleciona endereço novo, cria pedido e confirma pagamento',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1050);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final addresses = <Map<String, dynamic>>[
        {
          'id': 3,
          'label': 'Casa',
          'recipient_name': 'Leitor',
          'street': 'Rua Teste',
          'number': '123',
          'neighborhood': 'Centro',
          'city': 'Curitiba',
          'state': 'PR',
          'postal_code': '80000-000',
          'is_default': true,
        },
      ];
      var created = false;
      Map<String, dynamic>? payload;
      final api = ApiClient(
        client: MockClient((request) async {
          switch (request.url.path) {
            case '/api/user':
              return jsonResponse({'data': userJson()});
            case '/api/cart':
              return jsonResponse(cartJson(quantity: created ? 0 : 1));
            case '/api/addresses':
              if (request.method == 'POST') {
                final address = {
                  ...jsonDecode(request.body) as Map<String, dynamic>,
                  'id': 4,
                };
                addresses.add(address);
                return jsonResponse({'data': address}, status: 201);
              }
              return jsonResponse({'data': addresses});
            case '/api/orders':
              payload = jsonDecode(request.body) as Map<String, dynamic>;
              created = true;
              return jsonResponse(orderJson(), status: 201);
            case '/api/orders/9/confirm-payment':
              return jsonResponse(orderJson(status: 'paid'));
          }
          final session = guestSessionResponse(request);
          if (session != null) return session;
          if (request.url.path == '/api/categories') {
            return jsonResponse({'data': []});
          }
          return jsonResponse(catalogJson([]));
        }),
      );
      addTearDown(api.close);
      await tester.pumpWidget(MangaverseApp(api: api));
      await tester.pumpAndSettle();
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .pushNamed('/finalizar');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Novo endereço'));
      await tester.pumpAndSettle();
      for (final entry in {
        'label': 'Trabalho',
        'recipient_name': 'Leitor',
        'postal_code': '80000-000',
        'state': 'PR',
        'city': 'Curitiba',
        'neighborhood': 'Centro',
        'street': 'Rua Nova',
        'number': '456',
      }.entries) {
        final field = find.byKey(ValueKey('field-${entry.key}'));
        await tester.ensureVisible(field);
        await tester.enterText(field, entry.value);
      }
      await tester.ensureVisible(find.text('Salvar'));
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(addresses.first['is_default'], isTrue);
      expect(addresses.last['is_default'], isFalse);
      await tester.scrollUntilVisible(
        find.text('Criar pedido').hitTestable(),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Criar pedido'));
      await tester.pumpAndSettle();
      expect(payload, {'address_id': 4, 'payment_method': 'pix'});
      expect(find.text('Pedido criado!'), findsOneWidget);
      expect(find.textContaining('Pago em'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Confirmar pagamento de teste').hitTestable(),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Confirmar pagamento de teste'));
      await tester.pumpAndSettle();
      expect(find.text('Pagamento confirmado!'), findsOneWidget);
      expect(find.text('Pago'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('CEP inválido é barrado em português antes de enviar', (
    tester,
  ) async {
    var submitted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: EditorForm(
              fields: const [EditorField('postal_code', 'CEP', required: true)],
              onSave: (_) async {
                submitted = true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('field-postal_code')),
      '123',
    );
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe um CEP válido, como 80000-000.'), findsOneWidget);
    expect(submitted, false);
  });
}
