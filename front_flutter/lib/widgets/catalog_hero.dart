import 'package:material_ui/material_ui.dart';

import 'store_layout.dart';

class CatalogHero extends StatelessWidget {
  const CatalogHero({super.key, required this.onExplore});
  final VoidCallback onExplore;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: StoreColors.lavender,
    child: StoreContainer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final copy = Padding(
            padding: EdgeInsets.fromLTRB(compact ? 8 : 42, 32, 12, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: StoreColors.yellow,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'SEU PRÓXIMO UNIVERSO COMEÇA AQUI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .5,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Histórias que ficam\ncom você.',
                  style: TextStyle(
                    color: StoreColors.purple,
                    fontSize: compact ? 35 : 48,
                    height: 1.04,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.6,
                  ),
                ),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: const Text(
                    'Explore mangás, encontre novas séries e complete sua coleção.',
                    style: TextStyle(
                      color: StoreColors.muted,
                      fontSize: 15,
                      height: 1.7,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onExplore,
                  child: const Text(
                    'Explorar catálogo →',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
          if (compact) {
            return ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 390),
              child: Stack(
                children: [
                  Positioned(
                    right: -200,
                    bottom: -55,
                    child: Opacity(opacity: .12, child: _HeroBooks()),
                  ),
                  copy,
                ],
              ),
            );
          }
          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 360),
            child: Row(
              children: [
                Expanded(child: copy),
                const Expanded(child: Center(child: _HeroBooks())),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class _HeroBooks extends StatelessWidget {
  const _HeroBooks();
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 400,
    height: 310,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: -.32,
          child: Container(
            width: 320,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: StoreColors.purple, width: 2),
              borderRadius: BorderRadius.circular(200),
            ),
          ),
        ),
        Transform.rotate(
          angle: .61,
          child: Container(
            width: 260,
            height: 170,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFEF694E), width: 2),
              borderRadius: BorderRadius.circular(200),
            ),
          ),
        ),
        Positioned(
          left: 188,
          top: 72,
          child: Transform.rotate(
            angle: .19,
            child: const _Book(color: Color(0xFFEF694E), letter: 'V'),
          ),
        ),
        Positioned(
          left: 95,
          top: 48,
          child: Transform.rotate(
            angle: -.14,
            child: const _Book(color: Color(0xFF27C5B8), letter: 'M'),
          ),
        ),
        const Positioned(
          right: 38,
          top: 20,
          child: Text(
            '✦',
            style: TextStyle(color: StoreColors.purple, fontSize: 37),
          ),
        ),
        const Positioned(
          left: 52,
          bottom: 15,
          child: Text(
            '✦',
            style: TextStyle(color: Color(0xFFEF694E), fontSize: 28),
          ),
        ),
      ],
    ),
  );
}

class _Book extends StatelessWidget {
  const _Book({required this.color, required this.letter});
  final Color color;
  final String letter;
  @override
  Widget build(BuildContext context) => Container(
    width: 140,
    height: 205,
    decoration: BoxDecoration(
      color: color,
      border: Border.all(width: 3, color: StoreColors.ink),
      borderRadius: BorderRadius.circular(3),
      boxShadow: const [
        BoxShadow(color: StoreColors.ink, offset: Offset(6, 7)),
      ],
    ),
    child: Center(
      child: Container(
        width: 83,
        height: 83,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(width: 3, color: StoreColors.ink),
        ),
        child: Text(
          letter,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 52,
            color: StoreColors.purple,
          ),
        ),
      ),
    ),
  );
}
