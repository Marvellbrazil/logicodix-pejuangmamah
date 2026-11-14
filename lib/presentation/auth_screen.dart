import 'package:flutter/material.dart';

import '../application/api_failure.dart';
import '../domain/profile.dart';
import 'app_state.dart';
import 'app_theme.dart';
import 'ui_kit.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.state,
    required this.onGoogle,
    required this.onBack,
    this.initialRegistering = false,
    this.initialError,
  });

  final AppState state;
  final Future<bool> Function(UserRole role) onGoogle;
  final VoidCallback onBack;
  final bool initialRegistering;
  final String? initialError;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  final _displayName = TextEditingController();

  bool _registering = false;
  UserRole _role = UserRole.worker;
  String? _localError;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _registering = widget.initialRegistering;
    _localError = widget.initialError;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _fullName.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _localError = null);

    final ok = _registering
        ? await widget.state.register(
            email: _email.text,
            password: _password.text,
            fullName: _fullName.text,
            displayName: _displayName.text,
            role: _role,
          )
        : await widget.state.login(
            email: _email.text,
            password: _password.text,
          );
    if (!ok && mounted) {
      setState(() => _localError = widget.state.authError);
    }
  }

  Future<void> _google() async {
    setState(() => _localError = null);
    try {
      final ok = await widget.onGoogle(_role);
      if (!ok && mounted) setState(() => _localError = widget.state.authError);
    } on ApiFailure catch (error) {
      if (mounted) setState(() => _localError = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = widget.state.busy;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              Space.xl,
              Space.xxl,
              Space.xl,
              Space.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Brand(onBack: widget.onBack),
                      const SizedBox(height: Space.xl),
                      Text(
                        _registering
                            ? 'Buat akun profesionalmu'
                            : 'Masuk ke Kerjaqueue',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: Space.sm),
                      Text(
                        _registering
                            ? 'Isi nama lengkap dan nama panggilan seperti di LinkedIn. Butuh waktu satu menit.'
                            : 'Akun diperlukan agar lamaran, chat, dan profilmu tersimpan.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: Space.xl),

                      if (_localError != null) ...[
                        ErrorBanner(message: _localError!),
                        const SizedBox(height: Space.lg),
                      ],

                      OutlinedButton.icon(
                        onPressed: busy ? null : _google,
                        icon: busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const GoogleMark(size: 19),
                        label: const Text('Lanjutkan dengan Google'),
                      ),
                      const SizedBox(height: Space.lg),
                      const _OrDivider(),
                      const SizedBox(height: Space.lg),

                      if (_registering) ...[
                        TextFormField(
                          controller: _fullName,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          decoration: const InputDecoration(
                            labelText: 'Nama lengkap',
                            hintText: 'Rina Pratiwi',
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.length < 2) {
                              return 'Nama lengkap wajib diisi.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Space.md),
                        TextFormField(
                          controller: _displayName,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Nama panggilan',
                            hintText: 'Rina',
                            helperText: 'Nama ini yang muncul di kartu lamaranmu.',
                          ),
                          validator: (value) {
                            if ((value?.trim() ?? '').isEmpty) {
                              return 'Nama panggilan wajib diisi.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Space.lg),
                        _RoleSelector(
                          value: _role,
                          onChanged: (role) => setState(() => _role = role),
                        ),
                        const SizedBox(height: Space.lg),
                      ],

                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'nama@email.com',
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (!text.contains('@') || !text.contains('.')) {
                            return 'Format email belum benar.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: Space.md),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        autofillHints: [
                          _registering
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Kata sandi',
                          hintText: _registering ? 'Minimal 8 karakter' : null,
                          suffixIcon: IconButton(
                            tooltip: _obscure
                                ? 'Tampilkan kata sandi'
                                : 'Sembunyikan kata sandi',
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final text = value ?? '';
                          if (_registering && text.length < 8) {
                            return 'Kata sandi minimal 8 karakter.';
                          }
                          if (!_registering && text.isEmpty) {
                            return 'Kata sandi wajib diisi.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: Space.xl),
                      FilledButton(
                        onPressed: busy ? null : _submit,
                        child: busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Accent.tealInk,
                                ),
                              )
                            : Text(
                                _registering ? 'Buat akun' : 'Masuk',
                              ),
                      ),
                      const SizedBox(height: Space.md),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            _registering
                                ? 'Sudah punya akun?'
                                : 'Belum punya akun?',
                            style: theme.textTheme.bodySmall,
                          ),
                          TextButton(
                            onPressed: busy
                                ? null
                                : () => setState(() {
                                    _registering = !_registering;
                                    _localError = null;
                                  }),
                            child: Text(
                              _registering ? 'Masuk' : 'Daftar gratis',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Kembali ke halaman awal',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: Space.xs),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Accent.teal, Accent.tealDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: Radii.mdAll,
          ),
          child: const Icon(
            Icons.work_history_outlined,
            color: Accent.tealInk,
            size: 22,
          ),
        ),
        const SizedBox(width: Space.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Kerjaqueue',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'Kerja dekat, peluang terbuka.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: TextTone.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Surfaces.lineSoft)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.md),
          child: Text('atau', style: Theme.of(context).textTheme.bodySmall),
        ),
        const Expanded(child: Divider(color: Surfaces.lineSoft)),
      ],
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.value, required this.onChanged});

  final UserRole value;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Saya mendaftar sebagai', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: Space.sm),
        Row(
          children: [
            Expanded(
              child: _RoleOption(
                selected: value == UserRole.worker,
                icon: Icons.person_search_outlined,
                label: 'Pencari kerja',
                onTap: () => onChanged(UserRole.worker),
              ),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: _RoleOption(
                selected: value == UserRole.employer,
                icon: Icons.storefront_outlined,
                label: 'Pemberi kerja',
                onTap: () => onChanged(UserRole.employer),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? Accent.tealWash : Surfaces.raised,
        borderRadius: Radii.mdAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: Radii.mdAll,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.md,
              vertical: Space.md,
            ),
            decoration: BoxDecoration(
              borderRadius: Radii.mdAll,
              border: Border.all(
                color: selected ? Accent.teal : Surfaces.lineSoft,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: selected ? Accent.teal : TextTone.muted,
                ),
                const SizedBox(width: Space.sm),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Accent.teal : TextTone.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
