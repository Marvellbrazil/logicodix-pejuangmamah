import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'application/receipt_parser.dart';
import 'application/scan_receipt.dart';
import 'infrastructure/google_auth_repository.dart';
import 'infrastructure/ml_kit_receipt_text_reader.dart';
import 'infrastructure/sqlite_receipt_repository.dart';
import 'presentation/app.dart';

const _googleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue:
      '162964532692-lal2n4ttfdt7ffh5koj4qbrssvbnh9fn.apps.googleusercontent.com',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await SqliteReceiptRepository.open(
    p.join(await getDatabasesPath(), 'pejuangmamah.db'),
  );
  runApp(
    PejuangMamahApp(
      repository: SqliteReceiptRepository(db),
      scanReceipt: ScanReceipt(MlKitReceiptTextReader(), ReceiptParser()),
      auth: GoogleAuthRepository(serverClientId: _googleServerClientId),
    ),
  );
}
