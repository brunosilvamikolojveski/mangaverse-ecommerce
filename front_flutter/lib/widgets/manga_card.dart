import 'package:material_ui/material_ui.dart';

import '../models/manga.dart';
import '../state/store_scope.dart';
import 'manga_cover.dart';
import 'store_layout.dart';

class MangaCard extends StatelessWidget {
  const MangaCard({super.key, required this.manga});
  final Manga manga;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 210 || constraints.maxHeight < 450;
      final session = StoreScope.of(context);
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x183D1A5B),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).pushNamed('/mangas/${manga.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: compact ? 218 : 250,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Center(
                      child: SizedBox(
                        height: compact ? 175 : 200,
                        child: MangaCover(manga: manga),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 12 : 17,
                      12,
                      compact ? 12 : 17,
                      17,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 42,
                          child: Text(
                            '${manga.title} · Vol. ${manga.volumeNumber}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: compact ? 13 : 15,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          manga.authorNames.isEmpty
                              ? 'Autor não informado'
                              : manga.authorNames,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: StoreColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          manga.formattedPrice,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 42,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            onPressed:
                                !manga.inStock ||
                                    !session.cartReady ||
                                    session.busy
                                ? null
                                : () async {
                                    try {
                                      await session.addItem(manga.id);
                                      if (context.mounted) {
                                        showStoreNotice(
                                          context,
                                          '${manga.title} foi adicionado ao carrinho.',
                                        );
                                      }
                                    } catch (error) {
                                      if (context.mounted) {
                                        showStoreNotice(
                                          context,
                                          errorMessage(error),
                                          isError: true,
                                        );
                                      }
                                    }
                                  },
                            child: Text(
                              manga.inStock ? 'Comprar' : 'Sem estoque',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
