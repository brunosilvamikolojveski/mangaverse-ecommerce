import 'package:material_ui/material_ui.dart';

import '../models/manga.dart';
import '../services/admin_service.dart';
import '../widgets/admin_layout.dart';
import '../widgets/admin_components.dart';
import '../widgets/editor_form.dart';
import '../widgets/manga_cover.dart';
import '../widgets/store_layout.dart';

class AdminMangasPage extends StatefulWidget {
  const AdminMangasPage({super.key, required this.admin});
  final AdminService admin;
  @override
  State<AdminMangasPage> createState() => _AdminMangasPageState();
}

class _AdminMangasPageState extends State<AdminMangasPage> {
  List<Manga> _mangas = [];
  List<Map<String, dynamic>> _series = [];
  final _search = TextEditingController();
  String _visibility = 'all';
  bool _loading = true;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final mangas = await widget.admin.mangas();
      final series = await widget.admin.records(RecordKind.series);
      if (mounted) {
        setState(() {
          _mangas = mangas;
          _series = series;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([Manga? manga]) async {
    final fields = [
      EditorField(
        'series_id',
        'Série',
        required: true,
        type: FieldType.select,
        choices: {
          for (final series in _series)
            series['id'] as int: series['title'] as String,
        },
      ),
      const EditorField(
        'volume_number',
        'Número do volume',
        required: true,
        type: FieldType.integer,
        minimum: 1,
      ),
      const EditorField('title', 'Título do volume', maxLength: 180),
      const EditorField('isbn', 'ISBN (opcional)', maxLength: 20),
      const EditorField('description', 'Descrição', type: FieldType.paragraph),
      const EditorField(
        'price',
        'Preço (R\$)',
        required: true,
        type: FieldType.decimal,
        minimum: .01,
      ),
      const EditorField(
        'stock',
        'Estoque',
        required: true,
        type: FieldType.integer,
        minimum: 0,
      ),
      const EditorField(
        'published_at',
        'Data de publicação (AAAA-MM-DD)',
        type: FieldType.date,
      ),
      const EditorField('cover_image', 'Capa', type: FieldType.image),
      const EditorField('is_active', 'Visível na loja', type: FieldType.toggle),
    ];
    final saved = await showEditor(
      context,
      title: manga == null ? 'Cadastrar mangá' : 'Editar mangá',
      fields: fields,
      initial: manga == null
          ? {'stock': 0, 'is_active': true, 'volume_number': 1}
          : {
              'series_id': manga.seriesId,
              'volume_number': manga.volumeNumber,
              'title': manga.title,
              'isbn': manga.isbn,
              'description': manga.description,
              'price': manga.price,
              'stock': manga.stock,
              'published_at': manga.publishedAt?.split('T').first,
              'is_active': manga.isActive,
            },
      onSave: (values) async {
        await widget.admin.saveManga(values, id: manga?.id);
      },
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _setVisibility(Manga manga) async {
    if (manga.isActive &&
        !await confirmAction(
          context,
          'Desativar mangá?',
          'O volume sairá do catálogo público. Você poderá reativá-lo ao editar.',
        )) {
      return;
    }
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      if (manga.isActive) {
        await widget.admin.deactivateManga(manga.id);
      } else {
        await widget.admin.saveManga({'is_active': true}, id: manga.id);
      }
      if (mounted) await _load();
    } catch (error) {
      if (mounted) showStoreNotice(context, errorMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = _mangas
        .where(
          (m) =>
              (_visibility == 'all' ||
                  m.isActive == (_visibility == 'active')) &&
              '${m.title} ${m.seriesTitle} ${m.authorNames}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
    return AdminLayout(
      path: '/admin/mangas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminHeading(
            'Catálogo de mangás',
            subtitle: 'Gerencie os volumes, preços, estoque e capas da loja.',
            action: FilledButton.icon(
              onPressed: _loading || _busy ? null : _edit,
              icon: const Icon(Icons.add, size: 17),
              label: const Text('Cadastrar mangá'),
            ),
          ),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              AdminStat('Total de volumes', '${_mangas.length}'),
              AdminStat('Ativos', '${_mangas.where((m) => m.isActive).length}'),
              AdminStat(
                'Inativos',
                '${_mangas.where((m) => !m.isActive).length}',
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final search = SizedBox(
                width: constraints.maxWidth < 800 ? constraints.maxWidth : 390,
                child: TextField(
                  controller: _search,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    labelText: 'Buscar título, série ou autor',
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    prefixIcon: Icon(Icons.search, size: 19),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              );
              final filters = AdminTabs(
                labels: const {
                  'all': 'Todos',
                  'active': 'Ativos',
                  'inactive': 'Inativos',
                },
                value: _visibility,
                onChanged: (value) => setState(() => _visibility = value),
              );
              if (constraints.maxWidth < 800) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [search, const SizedBox(height: 12), filters],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [search, const SizedBox(width: 20), filters],
              );
            },
          ),
          const SizedBox(height: 18),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            StoreMessage(
              title: 'Não foi possível carregar o catálogo',
              message: _error!,
              actionLabel: 'Tentar novamente',
              onAction: _load,
              isError: true,
            )
          else if (visible.isEmpty)
            AdminEmptyState(
              title: 'Nenhum volume encontrado',
              message: 'Tente outro título ou altere os filtros do catálogo.',
              action: TextButton(
                onPressed: () => setState(() {
                  _search.clear();
                  _visibility = 'all';
                }),
                child: const Text('Limpar busca e filtros'),
              ),
            )
          else
            for (final manga in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MangaRow(
                  manga: manga,
                  busy: _busy,
                  onEdit: () => _edit(manga),
                  onVisibility: () => _setVisibility(manga),
                ),
              ),
        ],
      ),
    );
  }
}

class _MangaRow extends StatelessWidget {
  const _MangaRow({
    required this.manga,
    required this.busy,
    required this.onEdit,
    required this.onVisibility,
  });
  final Manga manga;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onVisibility;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE8E7ED)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final information = Row(
          children: [
            SizedBox(width: 50, height: 68, child: MangaCover(manga: manga)),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manga.seriesTitle,
                    style: const TextStyle(
                      color: StoreColors.purple,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${manga.title} · Vol. ${manga.volumeNumber}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    manga.authorNames,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: StoreColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        final pricing = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preço',
              style: TextStyle(color: StoreColors.muted, fontSize: 10),
            ),
            const SizedBox(height: 4),
            Text(
              manga.formattedPrice,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        );
        final stock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estoque',
              style: TextStyle(color: StoreColors.muted, fontSize: 10),
            ),
            const SizedBox(height: 4),
            Text(
              '${manga.stock} unidade(s)',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Tooltip(
              message: 'Editar ${manga.title}',
              child: OutlinedButton(
                onPressed: busy ? null : onEdit,
                child: const Text('Editar'),
              ),
            ),
            Tooltip(
              message:
                  '${manga.isActive ? 'Desativar' : 'Ativar'} ${manga.title}',
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: manga.isActive
                      ? const Color(0xFF802E2E)
                      : const Color(0xFF175A35),
                ),
                onPressed: busy ? null : onVisibility,
                child: Text(manga.isActive ? 'Desativar' : 'Ativar'),
              ),
            ),
          ],
        );
        if (constraints.maxWidth < 1000) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              information,
              const SizedBox(height: 16),
              Wrap(
                spacing: 26,
                runSpacing: 14,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [pricing, stock, VisibilityBadge(manga.isActive)],
              ),
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: actions),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: information),
            const SizedBox(width: 20),
            SizedBox(width: 110, child: pricing),
            SizedBox(width: 100, child: stock),
            SizedBox(
              width: 95,
              child: Align(
                alignment: Alignment.centerLeft,
                child: VisibilityBadge(manga.isActive),
              ),
            ),
            actions,
          ],
        );
      },
    ),
  );
}
