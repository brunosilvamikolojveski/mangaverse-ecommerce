import 'package:flutter/foundation.dart';

import '../models/cart.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';

class StoreSession extends ChangeNotifier {
  StoreSession({required this.authService, required this.cartService});

  final AuthService authService;
  final CartService cartService;
  StoreUser? user;
  Cart? cart;
  List<String> mergeMessages = [];
  bool loading = true;
  bool initialized = false;
  bool busy = false;
  String? cartError;
  bool _disposed = false;

  int get cartCount => cart?.itemCount ?? 0;
  bool get cartReady => !loading && cartError == null && cart != null;

  Future<void> initialize() async {
    loading = true;
    cartError = null;
    _notify();
    try {
      user = await authService.currentUser();
      cart = await cartService.load();
    } catch (error) {
      cartError = _message(error);
    } finally {
      loading = false;
      initialized = true;
      _notify();
    }
  }

  Future<void> refreshCart() async {
    loading = true;
    cartError = null;
    _notify();
    try {
      cart = await cartService.load();
    } catch (error) {
      cartError = _message(error);
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> signIn({required String email, required String password}) =>
      _authenticate(() => authService.signIn(email: email, password: password));

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) => _authenticate(
    () => authService.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    ),
  );

  Future<void> _authenticate(Future<AuthResult> Function() action) async {
    _beginAction();
    try {
      final result = await action();
      user = result.user;
      mergeMessages = result.mergeMessages;
      cart = null;
      await refreshCart();
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> signOut() async {
    _beginAction();
    try {
      await authService.signOut();
      user = null;
      mergeMessages = [];
      cart = null;
      await refreshCart();
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> addItem(int mangaId, {int quantity = 1}) =>
      _changeCart(() => cartService.addItem(mangaId, quantity));

  Future<void> updateItem(int itemId, int quantity) =>
      _changeCart(() => cartService.updateItem(itemId, quantity));

  Future<void> removeItem(int itemId) =>
      _changeCart(() => cartService.removeItem(itemId));

  Future<void> clearCart() => _changeCart(cartService.clear);

  Future<void> _changeCart(Future<Cart> Function() action) async {
    _beginAction();
    try {
      cart = await action();
      cartError = null;
    } catch (error) {
      if (error is! ApiException || error.statusCode != 422) {
        cartError = 'Atualize seu carrinho para conferir os itens antes de tentar novamente.';
      }
      rethrow;
    } finally {
      busy = false;
      _notify();
    }
  }

  void _beginAction() {
    if (busy || loading) {
      throw const ApiException('Aguarde a operação atual terminar.');
    }
    busy = true;
    _notify();
  }

  void updateUser(StoreUser value) {
    user = value;
    _notify();
  }

  void dismissMergeMessages() {
    mergeMessages = [];
    _notify();
  }

  String _message(Object error) => error is ApiException
      ? error.message
      : 'Não foi possível carregar seu carrinho. Tente novamente.';

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
