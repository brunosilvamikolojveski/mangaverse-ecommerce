import 'package:material_ui/material_ui.dart';

import '../services/api_client.dart';
import '../state/store_scope.dart';
import 'account_menu.dart';
import 'store_outline_icon.dart';

abstract final class StoreColors {
  static const purple = Color(0xFF3D1A5B);
  static const darkPurple = Color(0xFF2C1045);
  static const yellow = Color(0xFFFFC21A);
  static const lavender = Color(0xFFF4F1F7);
  static const ink = Color(0xFF1C1C1C);
  static const muted = Color(0xFF6D6871);
  static const line = Color(0xFFDED9E3);
}

String errorMessage(Object error) => error is ApiException
    ? error.message
    : 'Não foi possível concluir a operação. Tente novamente.';

class StoreContainer extends StatelessWidget {
  const StoreContainer({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width < 720 ? 14 : 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1440),
        child: SizedBox(width: double.infinity, child: child),
      ),
    ),
  );
}

class StoreHeader extends StatelessWidget {
  const StoreHeader({
    super.key,
    this.searchController,
    this.onSearchChanged,
    this.onSection,
  });
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onSection;

  @override
  Widget build(BuildContext context) {
    final session = StoreScope.of(context);
    final compact = MediaQuery.sizeOf(context).width < 950;
    final logo = TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        alignment: Alignment.centerLeft,
      ),
      onPressed: () =>
          Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false),
      child: Text(
        'Mangáverse',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 20 : 23,
          fontWeight: FontWeight.w700,
          letterSpacing: -.9,
        ),
      ),
    );
    final search = SizedBox(
      height: 44,
      child: TextField(
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
        controller: searchController,
        readOnly: searchController == null,
        onTap: searchController == null
            ? () => Navigator.of(context).pushNamed('/?section=catalogo')
            : null,
        onChanged: onSearchChanged,
        decoration: const InputDecoration(
          hintText: 'Busque por título, série ou descrição',
          labelText: 'Buscar mangás',
          floatingLabelBehavior: FloatingLabelBehavior.never,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(color: StoreColors.yellow, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: Icon(Icons.search),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (session.user == null)
          Tooltip(
            message: 'Entrar na conta',
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(40, 40),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
              onPressed: session.loading
                  ? null
                  : () => Navigator.of(context).pushNamed('/entrar'),
              icon: const StoreOutlineIcon(symbol: StoreSymbol.person),
              label: const Text('Entrar'),
            ),
          )
        else
          const AccountMenu(),
        const SizedBox(width: 8),
        IconButton(
          constraints: const BoxConstraints.tightFor(width: 42, height: 42),
          padding: const EdgeInsets.all(8),
          tooltip: 'Carrinho com ${session.cartCount} itens',
          onPressed: () => Navigator.of(context).pushNamed('/carrinho'),
          icon: Badge(
            isLabelVisible: true,
            backgroundColor: StoreColors.yellow,
            textColor: StoreColors.darkPurple,
            label: Text(
              session.cartCount > 99 ? '99+' : '${session.cartCount}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
            child: const StoreOutlineIcon(symbol: StoreSymbol.cart, size: 26),
          ),
        ),
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ColoredBox(
          color: StoreColors.purple,
          child: StoreContainer(
            child: SizedBox(
              height: 28,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Um universo de histórias em cada volume',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                  if (!compact)
                    const Text(
                      'Encontre seu próximo mangá',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                ],
              ),
            ),
          ),
        ),
        ColoredBox(
          color: StoreColors.purple,
          child: StoreContainer(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: compact ? 14 : 22),
              child: compact
                  ? Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: logo,
                              ),
                            ),
                            actions,
                          ],
                        ),
                        if (searchController != null) ...[
                          const SizedBox(height: 12),
                          search,
                        ],
                      ],
                    )
                  : Row(
                      children: [
                        if (searchController != null) ...[
                          SizedBox(width: 210, child: logo),
                          const SizedBox(width: 32),
                          Expanded(child: search),
                          const SizedBox(width: 32),
                        ] else ...[
                          logo,
                          const Spacer(),
                        ],
                        actions,
                      ],
                    ),
            ),
          ),
        ),
        ColoredBox(
          color: StoreColors.darkPurple,
          child: StoreContainer(
            child: SizedBox(
              height: 42,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final entry in const {
                      'Novidades': 'novidades',
                      'Catálogo': 'catalogo',
                      'Categorias': 'categorias',
                      'Sobre a Mangáverse': 'sobre',
                    }.entries)
                      Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: TextButton(
                          onPressed: () {
                            if (onSection != null) {
                              onSection!(entry.value);
                            } else {
                              Navigator.of(context)
                                  .pushNamed('/?section=${entry.value}');
                            }
                          },
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (session.cartError != null)
          _StoreBanner(
            messages: [session.cartError!],
            onRetry: session.initialize,
          ),
        if (session.mergeMessages.isNotEmpty)
          _StoreBanner(
            messages: session.mergeMessages,
            onDismiss: session.dismissMergeMessages,
          ),
      ],
    );
  }
}

class _StoreBanner extends StatelessWidget {
  const _StoreBanner({required this.messages, this.onDismiss, this.onRetry});
  final List<String> messages;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: StoreColors.lavender,
    child: StoreContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Semantics(
          liveRegion: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final message in messages)
                      Text(
                        message,
                        style: const TextStyle(
                          color: StoreColors.darkPurple,
                          height: 1.5,
                        ),
                      ),
                    if (onRetry != null)
                      TextButton(
                        onPressed: onRetry,
                        child: const Text('Recarregar conta e carrinho'),
                      ),
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  tooltip: 'Fechar aviso',
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close, size: 18),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

void showStoreNotice(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : StoreColors.purple,
      ),
    );
}

class StoreFooter extends StatelessWidget {
  const StoreFooter({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => compact
      ? ColoredBox(
          color: const Color(0xFF21122C),
          child: StoreContainer(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 24,
                runSpacing: 8,
                children: [
                  const Text(
                    'Mangáverse',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '© ${DateTime.now().year} Mangáverse · Projeto acadêmico',
                    style: const TextStyle(
                      color: Color(0xFFB9AFC0),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      : ColoredBox(
          color: const Color(0xFF21122C),
          child: StoreContainer(
            child: Padding(
              padding: const EdgeInsets.only(top: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 40,
                    runSpacing: 28,
                    children: [
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width < 720
                            ? MediaQuery.sizeOf(context).width - 28
                            : (MediaQuery.sizeOf(context).width.clamp(0, 1440) -
                                      48) *
                                  .4,
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mangáverse',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Um universo de histórias em cada volume.\nDescubra novas séries e complete sua coleção.',
                              style: TextStyle(
                                color: Color(0xFFB9AFC0),
                                fontSize: 12,
                                height: 1.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Explore',
                            style: TextStyle(
                              color: StoreColors.yellow,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Mangás, histórias e novas descobertas',
                            style: TextStyle(
                              color: Color(0xFFB9AFC0),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sobre a loja',
                            style: TextStyle(
                              color: StoreColors.yellow,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Projeto acadêmico de e-commerce',
                            style: TextStyle(
                              color: Color(0xFFB9AFC0),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white12),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      '© ${DateTime.now().year} Mangáverse. Projeto acadêmico.',
                      style: const TextStyle(
                        color: Color(0xFF8F8298),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
}

class StoreMessage extends StatelessWidget {
  const StoreMessage({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.isError = false,
  });
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final bool isError;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            isError ? Icons.cloud_off_outlined : Icons.search_off,
            size: 44,
            color: StoreColors.purple,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: StoreColors.muted, height: 1.6),
          ),
          const SizedBox(height: 20),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    ),
  );
}

class StorePage extends StatelessWidget {
  const StorePage({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: StoreHeader()),
        SliverToBoxAdapter(
          child: StoreContainer(
            child: Padding(
              padding: const EdgeInsets.only(top: 38, bottom: 56),
              child: child,
            ),
          ),
        ),
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [StoreFooter(compact: true)],
          ),
        ),
      ],
    ),
  );
}

class StorePanel extends StatelessWidget {
  const StorePanel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFEBE7EE)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: child,
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, {super.key, this.subtitle, this.action});
  final String title;
  final String? subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 24,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                color: StoreColors.purple,
                letterSpacing: -.9,
              ),
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  subtitle!,
                  style: const TextStyle(
                    color: StoreColors.muted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
        ?action,
      ],
    ),
  );
}

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ) ??
    false;

class AccountGate extends StatelessWidget {
  const AccountGate({
    super.key,
    required this.path,
    required this.builder,
    this.admin = false,
  });
  final String path;
  final WidgetBuilder builder;
  final bool admin;
  @override
  Widget build(BuildContext context) {
    final session = StoreScope.of(context);
    if (!session.initialized) {
      return const StorePage(child: Center(child: CircularProgressIndicator()));
    }
    if (session.user == null) {
      return StorePage(
        child: StoreMessage(
          title: 'Entre para continuar',
          message: 'Acesse sua conta para abrir esta página.',
          actionLabel: 'Entrar na conta',
          onAction: () => Navigator.of(context).pushReplacementNamed(
            '/entrar?redirect=${Uri.encodeComponent(path)}',
          ),
        ),
      );
    }
    if (admin && !session.user!.isAdmin) {
      return StorePage(
        child: StoreMessage(
          title: 'Acesso restrito',
          message: 'Esta área é exclusiva da administração.',
          actionLabel: 'Voltar à loja',
          onAction: () =>
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false),
        ),
      );
    }
    return builder(context);
  }
}
