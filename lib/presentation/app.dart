import 'package:flutter/material.dart';

import '../application/scan_receipt.dart';
import '../domain/receipt.dart';
import 'app_theme.dart';
import 'home_shell.dart';
import 'welcome_screen.dart';

class PejuangMamahApp extends StatelessWidget {
  const PejuangMamahApp({
    super.key,
    required this.repository,
    required this.scanReceipt,
  });

  final ReceiptRepository repository;
  final ScanReceipt scanReceipt;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nota UMKM',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: _Root(repository: repository, scanReceipt: scanReceipt),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root({required this.repository, required this.scanReceipt});

  final ReceiptRepository repository;
  final ScanReceipt scanReceipt;

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _entered = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _entered
          ? HomeShell(
              key: const ValueKey('home'),
              repository: widget.repository,
              scanReceipt: widget.scanReceipt,
            )
          : WelcomeScreen(
              key: const ValueKey('welcome'),
              onStart: () => setState(() => _entered = true),
            ),
    );
  }
}
