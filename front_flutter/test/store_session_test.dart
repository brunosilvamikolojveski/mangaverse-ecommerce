import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangaverse_flutter/models/cart.dart';
import 'package:mangaverse_flutter/services/api_client.dart';
import 'package:mangaverse_flutter/services/auth_service.dart';
import 'package:mangaverse_flutter/services/cart_service.dart';
import 'package:mangaverse_flutter/state/store_session.dart';

import 'fixtures.dart';

void main() {
  StoreSession sessionFor(http.Client client) {
    final api = ApiClient(client: client);
    final session = StoreSession(
      authService: AuthService(api),
      cartService: CartService(api),
    );
    addTearDown(api.close);
    addTearDown(session.dispose);
    return session;
  }

  test('login carrega o carrinho mesclado e logout troca pelo carrinho de visitante', () async {
    var loggedIn = false;
    final session = sessionFor(
      MockClient((request) async {
        if (request.url.path == '/sanctum/csrf-cookie') {
          return http.Response('', 204);
        }
        if (request.url.path == '/api/auth/login') {
          loggedIn = true;
          return jsonResponse({
            'data': userJson(),
            'cart_merge': {
              'adjusted_items': [
                {
                  'title': 'Mangá 1',
                  'requested_quantity': 5,
                  'kept_quantity': 4,
                },
              ],
              'removed_items': [
                {'title': 'Volume indisponível'},
              ],
            },
          });
        }
        if (request.url.path == '/api/auth/logout') {
          loggedIn = false;
          return jsonResponse({'message': 'Sessão encerrada.'});
        }
        if (request.url.path == '/api/user') {
          return jsonResponse({'message': 'Unauthenticated.'}, status: 401);
        }
        return jsonResponse(
          cartJson(quantity: loggedIn ? 4 : 0, cartId: loggedIn ? 9 : 1),
        );
      }),
    );

    await session.initialize();
    expect(session.user, isNull);
    expect(session.cartReady, isTrue);
    await session.signIn(
      email: 'leitor@mangaverse.test',
      password: 'senha-teste',
    );
    expect(session.user!.id, 7);
    expect(session.cart!.id, 9);
    expect(session.cartCount, 4);
    expect(session.mergeMessages.first, contains('de 5 para 4'));
    expect(session.mergeMessages.last, contains('indisponível'));

    await session.signOut();
    expect(session.user, isNull);
    expect(session.cart!.id, 1);
    expect(session.cartCount, 0);
    expect(session.mergeMessages, isEmpty);
  });

  test(
    'rejeição de estoque mantém a quantidade e o subtotal anteriores',
    () async {
      final session = sessionFor(
        MockClient((request) async {
          if (request.method == 'POST') {
            return jsonResponse({
              'message':
                  'A quantidade solicitada é maior que o estoque disponível.',
            }, status: 422);
          }
          if (request.url.path == '/api/cart') {
            return jsonResponse(cartJson(quantity: 2));
          }
          return guestSessionResponse(request)!;
        }),
      );
      await session.initialize();
      final cartBefore = session.cart;

      await expectLater(
        session.addItem(1),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'status',
            422,
          ),
        ),
      );

      expect(session.cart, same(cartBefore));
      expect(session.cartCount, 2);
      expect(session.cart!.subtotal, '63.00');
      expect(session.busy, isFalse);
      expect(session.cartReady, isTrue);
    },
  );

  test(
    'login inválido preserva o carrinho de visitante e os erros do campo',
    () async {
      final session = sessionFor(
        MockClient((request) async {
          if (request.url.path == '/api/auth/login') {
            return jsonResponse({
              'message': 'E-mail ou senha incorretos.',
              'errors': {
                'email': ['E-mail ou senha incorretos.'],
              },
            }, status: 422);
          }
          if (request.url.path == '/api/cart') {
            return jsonResponse(cartJson(quantity: 2));
          }
          return guestSessionResponse(request)!;
        }),
      );
      await session.initialize();

      await expectLater(
        session.signIn(email: 'leitor@mangaverse.test', password: 'errada'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.errors['email'],
            'erro do e-mail',
            ['E-mail ou senha incorretos.'],
          ),
        ),
      );
      expect(session.user, isNull);
      expect(session.cartCount, 2);
      expect(session.busy, isFalse);
    },
  );

  test('falha ao atualizar o carrinho após login preserva a autenticação e permite recarregar', () async {
    var loggedIn = false;
    var failCart = false;
    final session = sessionFor(
      MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          loggedIn = true;
          failCart = true;
          return jsonResponse({'data': userJson()});
        }
        if (request.url.path == '/api/cart') {
          if (failCart) return jsonResponse({}, status: 500);
          return jsonResponse(cartJson(quantity: loggedIn ? 3 : 1));
        }
        return guestSessionResponse(request)!;
      }),
    );
    await session.initialize();
    await session.signIn(
      email: 'leitor@mangaverse.test',
      password: 'senha-teste',
    );

    expect(session.user!.id, 7);
    expect(session.cart, isNull);
    expect(session.cartError, isNotNull);
    failCart = false;
    await session.refreshCart();
    expect(session.cartCount, 3);
    expect(session.cartReady, isTrue);
  });

  test(
    'o contador soma as unidades e distingue o ID da linha do ID do mangá',
    () {
      final cart = Cart.fromJson(
        cartJson(quantity: 120)['data'] as Map<String, dynamic>,
      );
      expect(cart.itemCount, 120);
      expect(cart.items.single.id, 10);
      expect(cart.items.single.manga.id, 1);
      expect(cart.quantityForManga(1), 120);
      expect(cart.quantityForManga(999), 0);
    },
  );
}
