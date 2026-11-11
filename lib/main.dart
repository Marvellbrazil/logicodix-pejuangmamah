import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'application/receipt_parser.dart';
import 'application/scan_receipt.dart';
import 'infrastructure/ml_kit_receipt_text_reader.dart';
import 'infrastructure/sqlite_receipt_repository.dart';
import 'presentation/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await SqliteReceiptRepository.open(
    p.join(await getDatabasesPath(), 'pejuangmamah.db'),
  );
  runApp(
    PejuangMamahApp(
      repository: SqliteReceiptRepository(db),
      scanReceipt: ScanReceipt(MlKitReceiptTextReader(), ReceiptParser()),
    ),
  );
}
