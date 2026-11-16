import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../models/manga.dart';
import '../services/api_client.dart';
import '../services/catalog_service.dart';
import '../widgets/manga_cover.dart';
import '../widgets/quantity_control.dart';
import '../state/store_scope.dart';
import '../widgets/store_layout.dart';

class MangaDetailPage extends StatefulWidget {
  const MangaDetailPage({super.key, required this.id, required this.catalog});

  final int id;
  final CatalogService catalog;

  @override
  State<MangaDetailPage> createState() => _MangaDetailPageState();
}

class _MangaDetailPageState extends State<MangaDetailPage> {
  late Future<Manga> _manga;

  @override
  void initState() {
    super.initState();
    _manga = widget.catalog.find(widget.id);
  }

  @override
  Widget build(BuildContext context) => StorePage(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () =>
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Voltar ao catálogo'),
        ),
        const SizedBox(height: 24),
        FutureBuilder<Manga>(
          future: _manga,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(80),
                child: Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: 'Carregando mangá',
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              final error = snapshot.error;

              return StoreMessage(
                title: 'Não foi possível carregar este mangá',
                message: error is ApiException
                    ? error.message
                    : 'Tente novamente em instantes.',
                actionLabel: 'Tentar novamente',
                isError: true,
                onAction: () =>
                    setState(() => _manga = widget.catalog.find(widget.id)),
              );
            }

            return _MangaDetails(manga: snapshot.requireData);
          },
        ),
      ],
    ),
  );
}

class _MangaDetails extends StatefulWidget {
  const _MangaDetails({required this.manga});

  final Manga manga;

  @override
  State<_MangaDetails> createState() => _MangaDetailsState();
}

class _MangaDetailsState extends State<_MangaDetails> {
  int _quantity = 1;

  Manga get manga => widget.manga;

  @override
  Widget build(BuildContext context) {
    final session = StoreScope.of(context);
    final available = math.max(
      0,
      (manga.availableQuantity ?? 0) -
          (session.cart?.quantityForManga(manga.id) ?? 0),
    );
    final quantity = math.min(_quantity, math.max(1, available));
    final canAdd =
        manga.inStock && session.cartReady && available > 0 && !session.busy;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cover = Container(
          padding: const EdgeInsets.all(32),
          height: constraints.maxWidth < 800 ? 330 : 450,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: MangaCover(manga: manga)),
        );
        final information = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${manga.seriesTitle.toUpperCase()} · VOLUME ${manga.volumeNumber}',
              style: const TextStyle(
                color: StoreColors.purple,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                letterSpacing: .8,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              manga.title,
              style: Theme.of(context).textTheme.headlineLarge
                  ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1),
            ),
            const SizedBox(height: 16),
            Text(
              manga.authorNames.isEmpty
                  ? 'Autor não informado'
                  : manga.authorNames,
              style: const TextStyle(color: StoreColors.muted, fontSize: 16),
            ),
            const SizedBox(height: 32),
            Text(
              manga.formattedPrice,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              manga.inStock
                  ? 'Disponível em estoque'
                  : 'Indisponível no momento',
              style: TextStyle(
                color: manga.inStock
                    ? const Color(0xFF23734D)
                    : const Color(0xFFA12A35),
              ),
            ),
            if (manga.inStock && session.cartReady && available > 0) ...[
              const SizedBox(height: 24),
              const Text(
                'Quantidade',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              QuantityControl(
                value: quantity,
                label: manga.title,
                onDecrease: canAdd && quantity > 1
                    ? () => setState(() => _quantity = quantity - 1)
                    : null,
                onIncrease: canAdd && quantity < available
                    ? () => setState(() => _quantity = quantity + 1)
                    : null,
              ),
            ],
            if (manga.inStock && session.cartReady && available == 0)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Você já tem todo o estoque disponível no carrinho.',
                  style: TextStyle(color: StoreColors.muted),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: canAdd
                  ? () async {
                      try {
                        await session.addItem(manga.id, quantity: quantity);
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
                            error is ApiException
                                ? error.message
                                : 'Não foi possível adicionar o mangá.',
                            isError: true,
                          );
                        }
                      }
                    }
                  : null,
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(session.busy ? 'Aguarde…' : 'Adicionar ao carrinho'),
            ),
            if (manga.description?.isNotEmpty ?? false) ...[
              const SizedBox(height: 32),
              const Text(
                'Sobre este volume',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                manga.description!,
                style: const TextStyle(
                  color: StoreColors.muted,
                  fontSize: 14,
                  height: 1.75,
                ),
              ),
            ],
            const SizedBox(height: 28),
            if (manga.publisher != null)
              _Metadata(label: 'Editora', value: manga.publisher!),
            if (manga.categories.isNotEmpty)
              _Metadata(
                label: 'Categorias',
                value: manga.categories
                    .map((category) => category.name)
                    .join(', '),
              ),
            if (manga.isbn?.isNotEmpty ?? false)
              _Metadata(label: 'ISBN', value: manga.isbn!),
          ],
        );

        if (constraints.maxWidth < 800) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [cover, const SizedBox(height: 32), information],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cover),
            const SizedBox(width: 56),
            Expanded(child: information),
          ],
        );
      },
    );
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: StoreColors.line)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(color: StoreColors.muted)),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
