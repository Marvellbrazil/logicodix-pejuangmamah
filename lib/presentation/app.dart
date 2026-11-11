import 'package:flutter/material.dart';

import '../application/auth_repository.dart';
import '../application/scan_receipt.dart';
import '../domain/receipt.dart';
import '../domain/user_account.dart';
import 'app_theme.dart';
import 'home_shell.dart';
import 'welcome_screen.dart';

class PejuangMamahApp extends StatelessWidget {
  const PejuangMamahApp({
    super.key,
    required this.repository,
    required this.scanReceipt,
    required this.auth,
  });

  final ReceiptRepository repository;
  final ScanReceipt scanReceipt;
  final AuthRepository auth;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nota UMKM',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: _Root(
        repository: repository,
        scanReceipt: scanReceipt,
        auth: auth,
      ),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root({
    required this.repository,
    required this.scanReceipt,
    required this.auth,
  });

  final ReceiptRepository repository;
  final ScanReceipt scanReceipt;
  final AuthRepository auth;

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _entered = false;
  bool _busy = false;
  UserAccount? _account;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final account = await widget.auth.restore();
    if (!mounted || account == null) return;
    setState(() {
      _account = account;
      _entered = true;
    });
  }

  Future<void> _signIn() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final account = await widget.auth.signIn();
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (account != null) {
          _account = account;
          _entered = true;
        }
      });
    } on AuthFailure {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Gagal masuk dengan Google. Coba lagi atau lanjut sebagai tamu.'),
          ),
        );
    }
  }

  Future<void> _signOut() async {
    try {
      await widget.auth.signOut();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _account = null;
      _entered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _entered
          ? HomeShell(
              key: const ValueKey('home'),
              repository: widget.repository,
              scanReceipt: widget.scanReceipt,
              account: _account,
              onSignIn: _signIn,
              onSignOut: _signOut,
            )
          : WelcomeScreen(
              key: const ValueKey('welcome'),
              busy: _busy,
              onGoogle: _signIn,
              onGuest: () => setState(() => _entered = true),
            ),
    );
  }
}
