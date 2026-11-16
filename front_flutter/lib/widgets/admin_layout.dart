import 'package:material_ui/material_ui.dart';

import 'account_menu.dart';
import 'store_layout.dart';

class AdminLayout extends StatelessWidget {
  const AdminLayout({super.key, required this.path, required this.child});

  final String path;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F5F7),
    body: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ColoredBox(
            color: StoreColors.purple,
            child: StoreContainer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final brand = InkWell(
                    onTap: () =>
                        Navigator.of(context).pushReplacementNamed('/admin'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: StoreColors.yellow,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Text(
                            'M',
                            style: TextStyle(
                              color: StoreColors.purple,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mangáverse',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'PAINEL ADMINISTRATIVO',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: .9,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                  final compact = constraints.maxWidth < 900;
                  final navigation = SizedBox(
                    height: compact ? 42 : 74,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final entry in const {
                            '/admin': 'Visão geral',
                            '/admin/mangas': 'Catálogo',
                            '/admin/cadastros': 'Cadastros',
                            '/admin/pedidos': 'Pedidos',
                          }.entries)
                            Container(
                              height: double.infinity,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: path == entry.key
                                        ? StoreColors.yellow
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: path == entry.key
                                      ? Colors.white
                                      : Colors.white70,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  textStyle: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0,
                                  ),
                                  shape: const RoundedRectangleBorder(),
                                ),
                                onPressed: () =>
                                    Navigator.of(context)
                                        .pushReplacementNamed(entry.key),
                                child: Text(entry.value),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                  if (compact) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 13),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: brand),
                              const AccountMenu(admin: true),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: navigation,
                          ),
                        ],
                      ),
                    );
                  }
                  return Row(
                    children: [
                      brand,
                      const Spacer(),
                      navigation,
                      const Spacer(),
                      const AccountMenu(admin: true),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: StoreContainer(
            child: Padding(
              padding: const EdgeInsets.only(top: 42, bottom: 64),
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

class AdminStat extends StatelessWidget {
  const AdminStat(
    this.label,
    this.value, {
    super.key,
    this.caption,
    this.accent,
    this.columns = 3,
  });
  final String label;
  final String value;
  final String? caption;
  final Color? accent;
  final int columns;
  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context).width;
    final contentWidth = (viewport - (viewport < 720 ? 28 : 48)).clamp(0, 1440);
    final count = viewport < 900 ? 2 : columns;
    final width = (contentWidth - (count - 1) * 16) / count;
    final compact = width < 260;
    final number = Text(
      value,
      style: const TextStyle(
        fontSize: 28,
        height: 1,
        fontWeight: FontWeight.w600,
        color: StoreColors.purple,
      ),
    );
    final description = caption == null
        ? null
        : Text(
            caption!,
            textAlign: compact ? TextAlign.start : TextAlign.end,
            style: const TextStyle(color: StoreColors.muted, fontSize: 11),
          );
    return SizedBox(
      width: width,
      child: Container(
        clipBehavior: Clip.antiAlias,
        constraints: BoxConstraints(minHeight: caption == null ? 90 : 112),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE8E7ED)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D0C1037),
              blurRadius: 7,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (accent != null)
              SizedBox(height: 3, child: ColoredBox(color: accent!)),
            Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                accent == null ? 19 : 16,
                18,
                18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: compact && caption != null ? 34 : 0,
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: StoreColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: caption == null
                        ? 14
                        : compact
                        ? 20
                        : 28,
                  ),
                  if (compact)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        number,
                        if (description != null) ...[
                          const SizedBox(height: 8),
                          description,
                        ],
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        number,
                        if (description != null) ...[
                          const SizedBox(width: 12),
                          Expanded(child: description),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
