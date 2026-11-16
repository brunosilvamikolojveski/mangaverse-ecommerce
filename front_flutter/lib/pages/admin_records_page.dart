import 'package:material_ui/material_ui.dart';

import '../models/order.dart';
import '../services/admin_service.dart';
import '../widgets/admin_layout.dart';
import '../widgets/admin_components.dart';
import '../widgets/editor_form.dart';
import '../widgets/store_layout.dart';

class AdminRecordsPage extends StatefulWidget {
  const AdminRecordsPage({super.key, required this.admin});
  final AdminService admin;
  @override
  State<AdminRecordsPage> createState() => _AdminRecordsPageState();
}

class _AdminRecordsPageState extends State<AdminRecordsPage> {
  final Map<RecordKind, List<Map<String, dynamic>>> _records = {};
  RecordKind _kind = RecordKind.series;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait(
        RecordKind.values.map(widget.admin.records),
      );
      if (mounted) {
        setState(() {
          for (var i = 0; i < results.length; i++) {
            _records[RecordKind.values[i]] = results[i];
          }
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([Map<String, dynamic>? record]) async {
    final kind = _kind;
    final fields = switch (kind) {
      RecordKind.authors => const [
        EditorField('name', 'Nome do autor', required: true, maxLength: 120),
        EditorField('biography', 'Biografia', type: FieldType.paragraph),
      ],
      RecordKind.categories => const [
        EditorField(
          'name',
          'Nome da categoria',
          required: true,
          maxLength: 100,
        ),
        EditorField(
          'slug',
          'Slug',
          required: true,
          maxLength: 120,
          slugFrom: 'name',
        ),
      ],
      RecordKind.series => [
        const EditorField(
          'title',
          'Título da série',
          required: true,
          maxLength: 180,
        ),
        const EditorField(
          'slug',
          'Slug',
          required: true,
          maxLength: 200,
          slugFrom: 'title',
        ),
        const EditorField(
          'description',
          'Descrição',
          type: FieldType.paragraph,
        ),
        const EditorField(
          'status',
          'Situação',
          type: FieldType.select,
          required: true,
          choices: seriesStatuses,
        ),
        EditorField(
          'author_ids',
          'Autores',
          type: FieldType.multiple,
          choices: {
            for (final r
                in _records[RecordKind.authors] ?? <Map<String, dynamic>>[])
              r['id'] as int: r['name'] as String,
          },
        ),
        EditorField(
          'category_ids',
          'Categorias',
          type: FieldType.multiple,
          choices: {
            for (final r
                in _records[RecordKind.categories] ?? <Map<String, dynamic>>[])
              r['id'] as int: r['name'] as String,
          },
        ),
      ],
    };
    final initial = <String, dynamic>{'status': 'ongoing', ...?record};
    if (kind == RecordKind.series) {
      initial['author_ids'] = (record?['authors'] as List? ?? [])
          .map((r) => (r as Map)['id'])
          .toList();
      initial['category_ids'] = (record?['categories'] as List? ?? [])
          .map((r) => (r as Map)['id'])
          .toList();
    }
    final saved = await showEditor(
      context,
      title: '${record == null ? 'Cadastrar' : 'Editar'} ${kind.singular}',
      fields: fields,
      initial: initial,
      onSave: (values) async {
        await widget.admin.saveRecord(kind, values, id: record?['id'] as int?);
      },
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _delete(Map<String, dynamic> record) async {
    if (!await confirmAction(
      context,
      'Excluir ${_kind.singular}?',
      'A exclusão será permitida somente se o cadastro não estiver em uso.',
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await widget.admin.deleteRecord(_kind, record['id'] as int);
      if (mounted) await _load();
    } catch (error) {
      if (mounted) showStoreNotice(context, errorMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AdminLayout(
    path: '/admin/cadastros',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminHeading(
          'Séries, autores e categorias',
          subtitle: 'Organize as informações usadas para montar o catálogo.',
          action: FilledButton.icon(
            onPressed: _loading || _busy ? null : _edit,
            icon: const Icon(Icons.add, size: 17),
            label: Text('Cadastrar ${_kind.singular}'),
          ),
        ),
        AdminTabs(
          labels: {for (final kind in RecordKind.values) kind.name: kind.label},
          counts: {
            for (final kind in RecordKind.values)
              kind.name: _records[kind]?.length ?? 0,
          },
          value: _kind.name,
          onChanged: _busy
              ? null
              : (value) =>
                    setState(() => _kind = RecordKind.values.byName(value)),
        ),
        const SizedBox(height: 18),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          StoreMessage(
            title: 'Não foi possível carregar os cadastros',
            message: _error!,
            actionLabel: 'Tentar novamente',
            onAction: _load,
            isError: true,
          )
        else if ((_records[_kind] ?? []).isEmpty)
          AdminEmptyState(
            title: 'Nenhum cadastro de ${_kind.label.toLowerCase()}',
            message: 'Crie o primeiro cadastro para organizar os mangás.',
            action: FilledButton(
              onPressed: _edit,
              child: Text('Cadastrar ${_kind.singular}'),
            ),
          )
        else
          for (final record in _records[_kind]!)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _recordRow(record),
            ),
      ],
    ),
  );

  Widget _recordRow(Map<String, dynamic> record) {
    final title = (record['title'] ?? record['name']) as String;
    final authors = (record['authors'] as List? ?? [])
        .map((a) => (a as Map)['name'])
        .join(', ');
    final categories = (record['categories'] as List? ?? [])
        .map((a) => (a as Map)['name'])
        .join(', ');
    final description = switch (_kind) {
      RecordKind.series =>
        '${authors.isEmpty ? 'Sem autores associados' : authors} · ${categories.isEmpty ? 'Sem categorias' : categories}',
      RecordKind.authors =>
        record['biography'] as String? ?? 'Sem biografia cadastrada',
      RecordKind.categories => record['slug'] as String,
    };
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E7ED)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final information = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: StoreColors.lavender,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  switch (_kind) {
                    RecordKind.series => Icons.auto_stories_outlined,
                    RecordKind.authors => Icons.edit_outlined,
                    RecordKind.categories => Icons.category_outlined,
                  },
                  size: 21,
                  color: StoreColors.purple,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_kind == RecordKind.series)
                      Text(
                        seriesStatuses[record['status']] ??
                            record['status'].toString(),
                        style: const TextStyle(
                          color: StoreColors.purple,
                          fontSize: 10,
                        ),
                      ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: StoreColors.muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_kind == RecordKind.series)
                Text(
                  '${record['mangas_count'] ?? 0} volume(s)',
                  style: const TextStyle(
                    color: StoreColors.muted,
                    fontSize: 11,
                  ),
                ),
              Tooltip(
                message: 'Editar $title',
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _edit(record),
                  child: const Text('Editar'),
                ),
              ),
              Tooltip(
                message: 'Excluir $title',
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF802E2E),
                  ),
                  onPressed: _busy ? null : () => _delete(record),
                  child: const Text('Excluir'),
                ),
              ),
            ],
          );
          if (constraints.maxWidth < 700) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                information,
                const SizedBox(height: 14),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: information),
              const SizedBox(width: 20),
              actions,
            ],
          );
        },
      ),
    );
  }
}
