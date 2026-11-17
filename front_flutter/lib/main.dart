import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'pages/catalog_page.dart';
import 'pages/manga_detail_page.dart';
import 'pages/auth_page.dart';
import 'pages/cart_page.dart';
import 'pages/profile_page.dart';
import 'pages/checkout_page.dart';
import 'pages/orders_page.dart';
import 'pages/admin_dashboard_page.dart';
import 'pages/admin_mangas_page.dart';
import 'pages/admin_records_page.dart';
import 'pages/admin_orders_page.dart';
import 'services/account_service.dart';
import 'services/order_service.dart';
import 'services/admin_service.dart';
import 'services/api_client.dart';
import 'services/catalog_service.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'state/store_scope.dart';
import 'state/store_session.dart';
import 'widgets/store_layout.dart';

void main() => runApp(const MangaverseApp());

class MangaverseApp extends StatefulWidget {
  const MangaverseApp({super.key, this.api});

  final ApiClient? api;

  @override
  State<MangaverseApp> createState() => _MangaverseAppState();
}

class _MangaverseAppState extends State<MangaverseApp> {
  late final ApiClient _api = widget.api ?? ApiClient();
  late final CatalogService _catalog = CatalogService(_api);
  late final StoreSession _session = StoreSession(
    authService: AuthService(_api),
    cartService: CartService(_api),
  );

  @override
  void initState() {
    super.initState();
    unawaited(_session.initialize());
  }

  @override
  void dispose() {
    _session.dispose();
    if (widget.api == null) _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: StoreColors.purple).copyWith(
      primary: StoreColors.purple,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: StoreColors.ink,
    );

    return MaterialApp(
      title: 'Mangáverse',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => StoreScope(session: _session, child: child!),
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: scheme,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w600,
            height: 1.15,
            letterSpacing: -1,
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: -.8,
          ),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            height: 1.25,
            letterSpacing: -.5,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1.35,
            letterSpacing: -.3,
          ),
          titleMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.4,
            letterSpacing: 0,
          ),
          titleSmall: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.4,
            letterSpacing: 0,
          ),
          bodyLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.5,
            letterSpacing: 0,
          ),
          bodyMedium: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.5,
            letterSpacing: 0,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.5,
            letterSpacing: 0,
          ),
          labelLarge: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          titleTextStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 21,
            fontWeight: FontWeight.w600,
            color: StoreColors.purple,
            letterSpacing: -.5,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          labelStyle: const TextStyle(fontSize: 13, color: StoreColors.muted),
          hintStyle: const TextStyle(fontSize: 13, color: StoreColors.muted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: StoreColors.line),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 13,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: StoreColors.line),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            minimumSize: const Size(48, 44),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
            minimumSize: const Size(48, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
      onGenerateRoute: (settings) {
        final uri = Uri.tryParse(settings.name ?? '/') ?? Uri(path: '/');
        final path = uri.path;
        final match = RegExp(r'^/mangas/(\d+)$').firstMatch(path);
        final id = match == null ? null : int.tryParse(match.group(1)!);
        final Widget page;

        if (path == '/') {
          page = CatalogPageView(
            catalog: _catalog,
            section: uri.queryParameters['section'],
          );
        } else if (path == '/entrar') {
          page = AuthPage(redirect: uri.queryParameters['redirect']);
        } else if (path == '/carrinho') {
          page = const CartPage();
        } else if (path == '/perfil') {
          page = AccountGate(
            path: path,
            builder: (_) => ProfilePage(account: AccountService(_api)),
          );
        } else if (path == '/finalizar') {
          page = AccountGate(
            path: path,
            builder: (_) => CheckoutPage(
              account: AccountService(_api),
              orders: OrderService(_api),
            ),
          );
        } else if (path == '/pedidos' ||
            RegExp(r'^/pedidos/\d+$').hasMatch(path)) {
          page = AccountGate(
            path: path,
            builder: (_) => OrdersPage(
              orders: OrderService(_api),
              id: int.tryParse(path.split('/').last),
            ),
          );
        } else if (const {
          '/admin',
          '/admin/mangas',
          '/admin/cadastros',
          '/admin/pedidos',
        }.contains(path)) {
          page = AccountGate(
            path: path,
            admin: true,
            builder: (_) => switch (path) {
              '/admin/mangas' => AdminMangasPage(admin: AdminService(_api)),
              '/admin/cadastros' => AdminRecordsPage(admin: AdminService(_api)),
              '/admin/pedidos' => AdminOrdersPage(orders: OrderService(_api)),
              _ => AdminDashboardPage(
                admin: AdminService(_api),
                orders: OrderService(_api),
              ),
            },
          );
        } else if (id != null) {
          page = MangaDetailPage(id: id, catalog: _catalog);
        } else {
          page = Builder(
            builder: (context) => Scaffold(
              body: StoreContainer(
                child: StoreMessage(
                  title: 'Página não encontrada',
                  message:
                      'Explore o catálogo para encontrar sua próxima leitura.',
                  actionLabel: 'Voltar ao catálogo',
                  onAction: () =>
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/', (_) => false),
                ),
              ),
            ),
          );
        }

        return PageRouteBuilder<void>(
          settings: settings,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (_, _, _) => page,
        );
      },
    );
  }
}
