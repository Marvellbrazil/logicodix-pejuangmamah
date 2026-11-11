import 'package:flutter/material.dart';

import '../application/scan_receipt.dart';
import '../domain/receipt.dart';
import '../domain/user_account.dart';
import 'profile_screen.dart';
import 'receipt_list_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.repository,
    required this.scanReceipt,
    required this.account,
    required this.onSignIn,
    required this.onSignOut,
  });

  final ReceiptRepository repository;
  final ScanReceipt scanReceipt;
  final UserAccount? account;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          ReceiptListScreen(
            repository: widget.repository,
            scanReceipt: widget.scanReceipt,
          ),
          ProfileScreen(
            account: widget.account,
            onSignIn: widget.onSignIn,
            onSignOut: widget.onSignOut,
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Nota',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
