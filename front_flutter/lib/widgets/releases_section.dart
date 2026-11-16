import 'package:material_ui/material_ui.dart';

import '../models/manga.dart';
import 'manga_card.dart';
import 'store_layout.dart';

class ReleasesSection extends StatefulWidget {
  const ReleasesSection({
    super.key,
    required this.mangas,
    required this.onExplore,
  });
  final List<Manga> mangas;
  final VoidCallback onExplore;
  @override
  State<ReleasesSection> createState() => _ReleasesSectionState();
}

class _ReleasesSectionState extends State<ReleasesSection> {
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _move(int direction) => _scroll.animateTo(
    (_scroll.offset + direction * 500).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    ),
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFF5F5F5),
    child: StoreContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 38),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACABARAM DE CHEGAR',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1,
                        color: StoreColors.purple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Novidades Mangáverse',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: widget.onExplore,
                      child: const Text('Ver catálogo'),
                    ),
                    IconButton(
                      tooltip: 'Novidades anteriores',
                      onPressed: () => _move(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    IconButton(
                      tooltip: 'Próximas novidades',
                      onPressed: () => _move(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final mobile = constraints.maxWidth < 720;
                final width = mobile
                    ? constraints.maxWidth * .72
                    : (constraints.maxWidth - 4 * 24) / 5;
                return SizedBox(
                  height: mobile ? 420 : 460,
                  child: ListView.separated(
                    controller: _scroll,
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.mangas.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 24),
                    itemBuilder: (context, index) => SizedBox(
                      width: width,
                      child: MangaCard(
                        key: ValueKey('release-${widget.mangas[index].id}'),
                        manga: widget.mangas[index],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
