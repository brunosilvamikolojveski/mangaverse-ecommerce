import 'package:material_ui/material_ui.dart';

import '../state/store_scope.dart';
import '../services/api_client.dart';
import 'store_outline_icon.dart';

class AccountMenu extends StatelessWidget {
  const AccountMenu({super.key, this.admin = false});

  final bool admin;

  @override
  Widget build(BuildContext context) {
    final session = StoreScope.of(context);
    final user = session.user;
    final compact = MediaQuery.sizeOf(context).width < 720;
    return PopupMenuButton<String>(
      tooltip: admin ? 'Conta administrativa' : 'Minha conta',
      enabled: !session.busy && !session.loading,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 220),
      menuPadding: const EdgeInsets.all(6),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE8E7ED)),
      ),
      onSelected: (path) async {
        if (path != 'logout') {
          if (admin) {
            Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
          } else {
            Navigator.of(context).pushNamed(path);
          }
          return;
        }
        try {
          await session.signOut();
          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
          }
        } catch (error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  error is ApiException
                      ? error.message
                      : 'Não foi possível sair da conta. Tente novamente.',
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      },
      itemBuilder: (_) => [
        if (admin)
          _item('/', 'Ver loja')
        else ...[
          if (user?.isAdmin == true) _item('/admin', 'Painel administrativo'),
          _item('/perfil', 'Meu perfil'),
          _item('/pedidos', 'Meus pedidos'),
        ],
        _item('logout', 'Sair', color: const Color(0xFF802E2E)),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!admin) ...[
              const StoreOutlineIcon(symbol: StoreSymbol.person),
              const SizedBox(width: 8),
            ],
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width < 360
                    ? 60
                    : compact
                    ? 95
                    : 135,
              ),
              child: Text(
                user?.name ?? 'Administrador',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: admin ? 11 : 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFFFFC21A),
              size: 17,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _item(
    String value,
    String label, {
    Color color = const Color(0xFF1C1C1C),
  }) => PopupMenuItem<String>(
    value: value,
    height: 36,
    padding: const EdgeInsets.symmetric(horizontal: 11),
    child: Text(
      label,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: color,
      ),
    ),
  );
}
