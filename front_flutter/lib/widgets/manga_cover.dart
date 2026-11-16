import 'package:material_ui/material_ui.dart';

import '../models/manga.dart';

class MangaCover extends StatelessWidget {
  const MangaCover({super.key, required this.manga});

  final Manga manga;

  @override
  Widget build(BuildContext context) {
    final placeholder = _PlaceholderCover(manga: manga);

    return AspectRatio(
      aspectRatio: 2 / 3,
      child: manga.coverImageUrl == null || manga.coverImageUrl!.isEmpty
          ? placeholder
          : Image.network(
              manga.coverImageUrl!,
              fit: BoxFit.contain,
              semanticLabel: 'Capa de ${manga.title}',
              webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
              errorBuilder: (context, error, stackTrace) => placeholder,
            ),
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  const _PlaceholderCover({required this.manga});

  final Manga manga;

  @override
  Widget build(BuildContext context) {
    final color = HSLColor.fromAHSL(
      1,
      ((manga.id * 47) % 360).toDouble(),
      .48,
      .35,
    ).toColor();

    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 220,
        height: 330,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: .75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: const Border(
              left: BorderSide(color: Colors.black26, width: 6),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(3, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  manga.seriesTitle.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  manga.title,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    height: 1.2,
                  ),
                ),
                const Spacer(),
                Text(
                  'Volume ${manga.volumeNumber}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
