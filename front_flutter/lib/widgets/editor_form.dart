import 'package:material_ui/material_ui.dart';

import '../models/upload_file.dart';
import '../services/api_client.dart';
import '../services/cover_picker.dart';
import 'store_layout.dart';

enum FieldType {
  text,
  paragraph,
  integer,
  decimal,
  email,
  date,
  select,
  multiple,
  toggle,
  image,
}

class EditorField {
  const EditorField(
    this.name,
    this.label, {
    this.type = FieldType.text,
    this.required = false,
    this.maxLength,
    this.minimum,
    this.choices = const {},
    this.slugFrom,
  });
  final String name;
  final String label;
  final FieldType type;
  final bool required;
  final int? maxLength;
  final num? minimum;
  final Map<Object, String> choices;
  final String? slugFrom;
}

const addressFields = [
  EditorField('label', 'Nome do endereço', required: true, maxLength: 50),
  EditorField(
    'recipient_name',
    'Nome do destinatário',
    required: true,
    maxLength: 120,
  ),
  EditorField('postal_code', 'CEP', required: true, maxLength: 9),
  EditorField('state', 'Estado (UF)', required: true, maxLength: 2),
  EditorField('city', 'Cidade', required: true, maxLength: 100),
  EditorField('neighborhood', 'Bairro', required: true, maxLength: 100),
  EditorField('street', 'Rua', required: true, maxLength: 160),
  EditorField('number', 'Número', required: true, maxLength: 20),
  EditorField('complement', 'Complemento', maxLength: 100),
  EditorField('phone', 'Telefone', maxLength: 30),
  EditorField(
    'is_default',
    'Usar como endereço principal',
    type: FieldType.toggle,
  ),
];

String createSlug(String text) {
  const accents = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const plain = 'aaaaaeeeeiiiiooooouuuuc';
  var result = text.toLowerCase();
  for (var i = 0; i < accents.length; i++) {
    result = result.replaceAll(accents[i], plain[i]);
  }
  return result
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

class EditorForm extends StatefulWidget {
  const EditorForm({
    super.key,
    required this.fields,
    required this.onSave,
    this.initial = const {},
    this.submitLabel = 'Salvar',
    this.onCancel,
    this.singleColumn = false,
    this.title,
  });
  final List<EditorField> fields;
  final Map<String, dynamic> initial;
  final Future<void> Function(Map<String, dynamic>) onSave;
  final String submitLabel;
  final VoidCallback? onCancel;
  final bool singleColumn;
  final String? title;
  @override
  State<EditorForm> createState() => _EditorFormState();
}

class _EditorFormState extends State<EditorForm> {
  final _form = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _values = <String, dynamic>{};
  final _editedSlugs = <String>{};
  Map<String, List<String>> _errors = {};
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      final value = widget.initial[field.name];
      if ({
        FieldType.select,
        FieldType.multiple,
        FieldType.toggle,
        FieldType.image,
      }.contains(field.type)) {
        _values[field.name] =
            value ??
            (field.type == FieldType.toggle
                ? false
                : field.type == FieldType.multiple
                ? <dynamic>[]
                : null);
      } else {
        _controllers[field.name] = TextEditingController(
          text: value?.toString() ?? '',
        );
      }
      if (field.slugFrom != null && value != null) _editedSlugs.add(field.name);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _changed(EditorField field, String text) {
    if (field.slugFrom != null) _editedSlugs.add(field.name);
    for (final slug in widget.fields.where(
      (item) => item.slugFrom == field.name,
    )) {
      if (!_editedSlugs.contains(slug.name)) {
        _controllers[slug.name]!.text = createSlug(text);
      }
    }
    if (_errors.containsKey(field.name)) {
      setState(() => _errors.remove(field.name));
    }
  }

  String? _validate(EditorField field, String? value) {
    final text = value?.trim() ?? '';
    if (field.required && text.isEmpty) return 'Preencha este campo.';
    if (text.isEmpty) return null;
    if (field.type == FieldType.email &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
      return 'Informe um e-mail válido.';
    }
    if (field.maxLength != null && text.length > field.maxLength!) {
      return 'Use até ${field.maxLength} caracteres.';
    }
    if (field.name == 'postal_code' &&
        !RegExp(r'^\d{5}-?\d{3}$').hasMatch(text)) {
      return 'Informe um CEP válido, como 80000-000.';
    }
    if (field.name == 'state' && !RegExp(r'^[a-zA-Z]{2}$').hasMatch(text)) {
      return 'Informe a sigla do estado com duas letras.';
    }
    if (field.type == FieldType.integer || field.type == FieldType.decimal) {
      final number = field.type == FieldType.integer
          ? int.tryParse(text)
          : num.tryParse(text.replaceAll(',', '.'));
      if (number == null ||
          !number.isFinite ||
          (field.minimum != null && number < field.minimum!)) {
        return 'Informe um número válido${field.minimum == null ? '' : ' a partir de ${field.minimum}'}.';
      }
    }
    if (field.type == FieldType.date && DateTime.tryParse(text) == null) {
      return 'Use o formato AAAA-MM-DD.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
      _errors = {};
    });
    final data = <String, dynamic>{..._values};
    for (final field in widget.fields.where(
      (field) => _controllers.containsKey(field.name),
    )) {
      final text = _controllers[field.name]!.text.trim();
      data[field.name] = text.isEmpty
          ? null
          : switch (field.type) {
              FieldType.integer => int.parse(text),
              FieldType.decimal => text.replaceAll(',', '.'),
              _ => text,
            };
    }
    try {
      await widget.onSave(data);
    } catch (error) {
      if (mounted) {
        setState(() {
          _errors = error is ApiException ? Map.of(error.errors) : {};
          _error = errorMessage(error);
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickImage(EditorField field) async {
    try {
      final selected = await pickCover();
      if (!mounted || selected == null) return;
      if (selected.bytes.length > 2 * 1024 * 1024 ||
          !RegExp(
            r'\.(jpe?g|png|webp)$',
            caseSensitive: false,
          ).hasMatch(selected.name)) {
        setState(
          () => _errors[field.name] = ['Use JPG, PNG ou WebP de até 2 MB.'],
        );
        return;
      }
      setState(() {
        _values[field.name] = selected;
        _errors.remove(field.name);
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _errors[field.name] = ['Não foi possível abrir esta imagem.'],
        );
      }
    }
  }

  Widget _field(EditorField field) {
    final decoration = InputDecoration(
      labelText: '${field.label}${field.required ? ' *' : ''}',
      errorText: _errors[field.name]?.join('\n'),
    );
    if (field.type == FieldType.toggle) {
      return CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(field.label),
        value: _values[field.name] == true,
        onChanged: _saving
            ? null
            : (value) => setState(() => _values[field.name] = value),
      );
    }
    if (field.type == FieldType.multiple) {
      final selected = List<dynamic>.from(_values[field.name] as List);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          if (field.choices.isEmpty)
            const Text(
              'Nenhum cadastro disponível.',
              style: TextStyle(color: StoreColors.muted),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final choice in field.choices.entries)
                FilterChip(
                  label: Text(choice.value),
                  selected: selected.contains(choice.key),
                  onSelected: _saving
                      ? null
                      : (checked) => setState(() {
                          if (checked) {
                            selected.add(choice.key);
                          } else {
                            selected.remove(choice.key);
                          }
                          _values[field.name] = selected;
                        }),
                ),
            ],
          ),
          if (_errors[field.name] != null)
            Text(
              _errors[field.name]!.join('\n'),
              style: const TextStyle(color: Colors.red),
            ),
        ],
      );
    }
    if (field.type == FieldType.select) {
      return DropdownButtonFormField<Object>(
        initialValue: field.choices.containsKey(_values[field.name])
            ? _values[field.name] as Object?
            : null,
        isExpanded: true,
        decoration: decoration,
        items: [
          for (final choice in field.choices.entries)
            DropdownMenuItem(
              value: choice.key,
              child: Text(choice.value, overflow: TextOverflow.ellipsis),
            ),
        ],
        validator: (value) =>
            field.required && value == null ? 'Escolha uma opção.' : null,
        onChanged: _saving
            ? null
            : (value) => setState(() {
                _values[field.name] = value;
                _errors.remove(field.name);
              }),
      );
    }
    if (field.type == FieldType.image) {
      final file = _values[field.name] as UploadFile?;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _saving ? null : () => _pickImage(field),
            icon: const Icon(Icons.upload_outlined),
            label: Text(file?.name ?? 'Escolher imagem'),
          ),
          if (file != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Image.memory(
                file.bytes,
                height: 120,
                errorBuilder: (_, _, _) =>
                    const Text('Não foi possível exibir a imagem.'),
              ),
            ),
          Text(
            _errors[field.name]?.join('\n') ?? 'JPG, PNG ou WebP, até 2 MB. Se não escolher outra, a capa atual será mantida.',
            style: TextStyle(
              fontSize: 12,
              color: _errors.containsKey(field.name)
                  ? Colors.red.shade800
                  : StoreColors.muted,
            ),
          ),
        ],
      );
    }
    return TextFormField(
      key: ValueKey('field-${field.name}'),
      controller: _controllers[field.name],
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      enabled: !_saving,
      decoration: decoration,
      maxLines: field.type == FieldType.paragraph ? 3 : 1,
      keyboardType: switch (field.type) {
        FieldType.integer => TextInputType.number,
        FieldType.decimal => const TextInputType.numberWithOptions(
          decimal: true,
        ),
        FieldType.email => TextInputType.emailAddress,
        _ => TextInputType.text,
      },
      validator: (value) => _validate(field, value),
      onChanged: (value) => _changed(field, value),
    );
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = !widget.singleColumn && constraints.maxWidth >= 520;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.title != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title!,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        color: StoreColors.purple,
                        letterSpacing: -.4,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar formulário',
                    onPressed: _saving ? null : widget.onCancel,
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: StoreColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final field in widget.fields)
                  SizedBox(
                    width:
                        twoColumns &&
                            !{
                              FieldType.paragraph,
                              FieldType.multiple,
                              FieldType.toggle,
                              FieldType.image,
                            }.contains(field.type)
                        ? (constraints.maxWidth - 16) / 2
                        : constraints.maxWidth,
                    child: _field(field),
                  ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: Text(_saving ? 'Salvando…' : widget.submitLabel),
                ),
                if (widget.onCancel != null)
                  TextButton(
                    onPressed: _saving ? null : widget.onCancel,
                    child: const Text('Cancelar'),
                  ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

Future<bool?> showEditor(
  BuildContext context, {
  required String title,
  required List<EditorField> fields,
  required Future<void> Function(Map<String, dynamic>) onSave,
  Map<String, dynamic> initial = const {},
}) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 650),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: EditorForm(
          title: title,
          fields: fields,
          initial: initial,
          onCancel: () => Navigator.pop(context, false),
          onSave: (values) async {
            await onSave(values);
            if (context.mounted) Navigator.pop(context, true);
          },
        ),
      ),
    ),
  ),
);
