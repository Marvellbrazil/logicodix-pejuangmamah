import 'package:flutter/material.dart';

import '../application/scan_receipt.dart';
import '../domain/receipt.dart';
import 'app_theme.dart';
import 'receipt_list_screen.dart';

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
      home: ReceiptListScreen(
        repository: repository,
        scanReceipt: scanReceipt,
      ),
    );
  }
}
