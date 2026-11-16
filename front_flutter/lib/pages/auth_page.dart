import 'package:material_ui/material_ui.dart';

import '../services/api_client.dart';
import '../state/store_scope.dart';
import '../widgets/store_layout.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.redirect});
  final String? redirect;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _registering = false;
  bool _showPassword = false;
  String? _error;
  Map<String, List<String>> _fieldErrors = {};

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _switchMode(bool registering) {
    _formKey.currentState?.reset();
    _password.clear();
    _confirmation.clear();
    setState(() {
      _registering = registering;
      _error = null;
      _fieldErrors = {};
    });
  }

  void _clearError(String field) {
    if (_fieldErrors.containsKey(field) || _error != null) {
      setState(() {
        _fieldErrors.remove(field);
        _error = null;
      });
    }
  }

  String? _fieldError(String field) {
    final messages = _fieldErrors[field];
    return messages == null || messages.isEmpty ? null : messages.first;
  }

  Future<void> _submit() async {
    final session = StoreScope.of(context);
    if (session.busy || session.loading || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _error = null;
      _fieldErrors = {};
    });
    try {
      if (_registering) {
        await session.register(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          passwordConfirmation: _confirmation.text,
        );
      } else {
        await session.signIn(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        widget.redirect != null &&
                widget.redirect!.startsWith('/') &&
                !widget.redirect!.startsWith('//')
            ? widget.redirect!
            : '/',
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _fieldErrors = error is ApiException ? Map.of(error.errors) : {};
        _error = _fieldErrors.isEmpty
            ? (error is ApiException
                  ? error.message
                  : 'Não foi possível entrar na conta. Tente novamente.')
            : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = StoreScope.of(context);
    final enabled = !session.busy && !session.loading;
    return StorePage(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: session.user != null
              ? StoreMessage(
                  title: 'Você já está na sua conta',
                  message: session.user!.email,
                  actionLabel: 'Ver meu carrinho',
                  onAction: () =>
                      Navigator.of(context).pushReplacementNamed('/carrinho'),
                )
              : Container(
                  padding: EdgeInsets.all(
                    MediaQuery.sizeOf(context).width < 720 ? 22 : 32,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFEBE7EE)),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x121C122A),
                        blurRadius: 18,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _registering
                            ? 'Crie sua conta'
                            : 'Que bom ter você de volta',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: StoreColors.purple,
                            ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Entre na sua conta para continuar sua coleção.',
                        style: TextStyle(color: StoreColors.muted, height: 1.6),
                      ),
                      const SizedBox(height: 28),
                      SegmentedButton<bool>(
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(5),
                              ),
                            ),
                          ),
                        ),
                        segments: const [
                          ButtonSegment(value: false, label: Text('Entrar')),
                          ButtonSegment(
                            value: true,
                            label: Text('Criar conta'),
                          ),
                        ],
                        selected: {_registering},
                        onSelectionChanged: enabled
                            ? (selection) => _switchMode(selection.single)
                            : null,
                      ),
                      const SizedBox(height: 28),
                      AutofillGroup(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_registering) ...[
                                TextFormField(
                                  key: const ValueKey('auth-name'),
                                  controller: _name,
                                  enabled: enabled,
                                  autofillHints: const [AutofillHints.name],
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: 'Nome',
                                    errorText: _fieldError('name'),
                                  ),
                                  onChanged: (_) => _clearError('name'),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                      ? 'Informe seu nome.'
                                      : null,
                                ),
                                const SizedBox(height: 20),
                              ],
                              TextFormField(
                                key: const ValueKey('auth-email'),
                                controller: _email,
                                enabled: enabled,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'E-mail',
                                  errorText: _fieldError('email'),
                                ),
                                onChanged: (_) => _clearError('email'),
                                validator: (value) =>
                                    value == null ||
                                        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                            .hasMatch(value.trim())
                                    ? 'Informe um e-mail válido.'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                key: const ValueKey('auth-password'),
                                controller: _password,
                                enabled: enabled,
                                obscureText: !_showPassword,
                                autofillHints: [
                                  _registering
                                      ? AutofillHints.newPassword
                                      : AutofillHints.password,
                                ],
                                textInputAction: _registering
                                    ? TextInputAction.next
                                    : TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: 'Senha',
                                  errorText: _fieldError('password'),
                                  suffixIcon: IconButton(
                                    tooltip: _showPassword
                                        ? 'Ocultar senha'
                                        : 'Mostrar senha',
                                    onPressed: () => setState(
                                      () => _showPassword = !_showPassword,
                                    ),
                                    icon: Icon(
                                      _showPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                                onChanged: (_) => _clearError('password'),
                                onFieldSubmitted: _registering
                                    ? null
                                    : (_) => _submit(),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Informe sua senha.';
                                  }
                                  if (_registering && value.length < 8) {
                                    return 'Use pelo menos 8 caracteres.';
                                  }
                                  return null;
                                },
                              ),
                              if (_registering) ...[
                                const SizedBox(height: 20),
                                TextFormField(
                                  key: const ValueKey('auth-confirmation'),
                                  controller: _confirmation,
                                  enabled: enabled,
                                  obscureText: !_showPassword,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  textInputAction: TextInputAction.done,
                                  decoration: InputDecoration(
                                    labelText: 'Confirmar senha',
                                    errorText: _fieldError(
                                      'password_confirmation',
                                    ),
                                  ),
                                  onChanged: (_) =>
                                      _clearError('password_confirmation'),
                                  onFieldSubmitted: (_) => _submit(),
                                  validator: (value) => value != _password.text
                                      ? 'As senhas precisam ser iguais.'
                                      : null,
                                ),
                              ],
                              if (_error != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      _error!,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error,
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 28),
                              FilledButton(
                                key: const ValueKey('auth-submit'),
                                onPressed: enabled ? _submit : null,
                                child: Text(
                                  session.busy
                                      ? 'Aguarde…'
                                      : _registering
                                      ? 'Cadastrar e entrar'
                                      : 'Entrar na conta',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context)
                                .pushNamedAndRemoveUntil('/', (_) => false),
                        child: const Text('Continuar navegando'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
