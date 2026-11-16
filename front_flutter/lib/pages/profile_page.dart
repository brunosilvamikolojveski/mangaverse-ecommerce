import 'package:material_ui/material_ui.dart';

import '../models/address.dart';
import '../services/account_service.dart';
import '../state/store_scope.dart';
import '../widgets/editor_form.dart';
import '../widgets/store_layout.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.account});
  final AccountService account;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<Address> _addresses = [];
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
      final addresses = await widget.account.addresses();
      if (mounted) setState(() => _addresses = addresses);
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([Address? address]) async {
    final saved = await showEditor(
      context,
      title: address == null ? 'Novo endereço' : 'Editar endereço',
      fields: addressFields,
      initial: address?.values ?? {'is_default': _addresses.isEmpty},
      onSave: (values) async {
        await widget.account.saveAddress(values, id: address?.id);
      },
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _change(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) await _load();
    } catch (error) {
      if (mounted) showStoreNotice(context, errorMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => StorePage(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeading(
          'Meu perfil',
          subtitle: 'Atualize seus dados e organize seus endereços de entrega.',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final profile = _profileForm(context);
            final addresses = _addressPanel();
            if (constraints.maxWidth < 800) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [profile, const SizedBox(height: 20), addresses],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: profile),
                const SizedBox(width: 20),
                Expanded(flex: 5, child: addresses),
              ],
            );
          },
        ),
      ],
    ),
  );

  Widget _profileForm(BuildContext context) {
    final session = StoreScope.of(context);
    final user = session.user!;
    return StorePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Meus dados',
            style: TextStyle(
              color: StoreColors.purple,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          EditorForm(
            singleColumn: true,
            fields: const [
              EditorField('name', 'Nome', required: true, maxLength: 255),
              EditorField(
                'email',
                'E-mail',
                required: true,
                type: FieldType.email,
                maxLength: 255,
              ),
            ],
            initial: {'name': user.name, 'email': user.email},
            submitLabel: 'Salvar dados',
            onSave: (values) async {
              final updated = await widget.account.updateProfile(values);
              session.updateUser(updated);
              if (context.mounted) {
                showStoreNotice(context, 'Dados atualizados.');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _addressPanel() => StorePanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            const Text(
              'Meus endereços',
              style: TextStyle(
                color: StoreColors.purple,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _edit,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Novo endereço'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          StoreMessage(
            title: 'Não foi possível carregar os endereços',
            message: _error!,
            actionLabel: 'Tentar novamente',
            onAction: _load,
            isError: true,
          )
        else if (_addresses.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Você ainda não tem um endereço cadastrado.',
              style: TextStyle(color: StoreColors.muted, fontSize: 13),
            ),
          )
        else
          for (final address in _addresses) ...[
            const Divider(height: 1, color: Color(0xFFEBE7EE)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 9,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        address.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (address.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5F4E9),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Text(
                            'Principal',
                            style: TextStyle(
                              color: Color(0xFF175A35),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${address.recipient}\n${address.streetLine}\n${address.cityLine}\nCEP ${address.values['postal_code']}',
                    style: const TextStyle(
                      color: StoreColors.muted,
                      fontSize: 12,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      TextButton(
                        onPressed: _busy ? null : () => _edit(address),
                        child: const Text('Editar endereço'),
                      ),
                      if (!address.isDefault)
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _change(() async {
                                  await widget.account.saveAddress({
                                    'is_default': true,
                                  }, id: address.id);
                                }),
                          child: const Text('Tornar principal'),
                        ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF802E2E),
                        ),
                        onPressed: _busy
                            ? null
                            : () async {
                                if (await confirmAction(
                                      context,
                                      'Excluir endereço?',
                                      'Este endereço será removido da sua conta.',
                                    ) &&
                                    mounted) {
                                  await _change(
                                    () => widget.account.deleteAddress(
                                      address.id,
                                    ),
                                  );
                                }
                              },
                        child: const Text('Excluir'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
      ],
    ),
  );
}
