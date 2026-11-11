import 'package:sqflite/sqflite.dart';

import '../domain/money.dart';
import '../domain/receipt.dart';

class SqliteReceiptRepository implements ReceiptRepository {
  SqliteReceiptRepository(this._db);

  final Database _db;

  static Future<Database> open(String path) {
    return openDatabase(
      path,
      version: 1,
      onConfigure: configure,
      onCreate: createSchema,
    );
  }

  static Future<void> configure(Database db) {
    return db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE receipts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        merchant TEXT NOT NULL,
        date INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE line_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        receipt_id INTEGER NOT NULL REFERENCES receipts(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price INTEGER NOT NULL
      )
    ''');
  }

  @override
  Future<List<Receipt>> all() async {
    final receiptRows = await _db.query(
      'receipts',
      orderBy: 'date DESC, id DESC',
    );
    final itemRows = await _db.query('line_items', orderBy: 'id ASC');

    final itemsByReceipt = <int, List<LineItem>>{};
    for (final row in itemRows) {
      itemsByReceipt
          .putIfAbsent(row['receipt_id']! as int, () => [])
          .add(
            LineItem(
              name: row['name']! as String,
              quantity: row['quantity']! as int,
              unitPrice: Money(row['unit_price']! as int),
            ),
          );
    }

    return [
      for (final row in receiptRows)
        Receipt(
          id: row['id']! as int,
          merchant: row['merchant']! as String,
          date: DateTime.fromMillisecondsSinceEpoch(row['date']! as int),
          items: itemsByReceipt[row['id']! as int] ?? const [],
        ),
    ];
  }

  @override
  Future<Receipt> save(Receipt receipt) {
    return _db.transaction((txn) async {
      final values = {
        'merchant': receipt.merchant,
        'date': receipt.date.millisecondsSinceEpoch,
      };
      final existingId = receipt.id;
      final int id;
      if (existingId == null) {
        id = await txn.insert('receipts', values);
      } else {
        await txn.update(
          'receipts',
          values,
          where: 'id = ?',
          whereArgs: [existingId],
        );
        await txn.delete(
          'line_items',
          where: 'receipt_id = ?',
          whereArgs: [existingId],
        );
        id = existingId;
      }
      for (final item in receipt.items) {
        await txn.insert('line_items', {
          'receipt_id': id,
          'name': item.name,
          'quantity': item.quantity,
          'unit_price': item.unitPrice.rupiah,
        });
      }
      return receipt.copyWith(id: id);
    });
  }

  @override
  Future<void> delete(int id) async {
    await _db.delete('receipts', where: 'id = ?', whereArgs: [id]);
  }
}
