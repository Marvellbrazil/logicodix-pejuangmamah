import 'package:flutter_test/flutter_test.dart';
import 'package:pejuangmamah/domain/money.dart';
import 'package:pejuangmamah/domain/receipt.dart';
import 'package:pejuangmamah/infrastructure/sqlite_receipt_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late SqliteReceiptRepository repository;

  setUp(() async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        singleInstance: false,
        version: 1,
        onConfigure: SqliteReceiptRepository.configure,
        onCreate: SqliteReceiptRepository.createSchema,
      ),
    );
    repository = SqliteReceiptRepository(db);
  });

  Receipt sample(String merchant, DateTime date) => Receipt(
    merchant: merchant,
    date: date,
    items: const [
      LineItem(name: 'Telur', quantity: 2, unitPrice: Money(28000)),
      LineItem(name: 'Beras', quantity: 1, unitPrice: Money(65000)),
    ],
  );

  test('saves, lists newest first, and keeps line items', () async {
    await repository.save(sample('Toko A', DateTime(2026, 11, 1)));
    await repository.save(sample('Toko B', DateTime(2026, 11, 5)));

    final all = await repository.all();

    expect(all.map((r) => r.merchant), ['Toko B', 'Toko A']);
    expect(all.first.items, hasLength(2));
    expect(all.first.total, const Money(121000));
  });

  test('update replaces line items', () async {
    final saved = await repository.save(sample('Toko A', DateTime(2026, 11, 1)));

    await repository.save(
      saved.copyWith(
        merchant: 'Toko A2',
        items: const [
          LineItem(name: 'Gula', quantity: 1, unitPrice: Money(15000)),
        ],
      ),
    );

    final all = await repository.all();
    expect(all, hasLength(1));
    expect(all.single.merchant, 'Toko A2');
    expect(all.single.items.single.name, 'Gula');
  });

  test('delete cascades to line items', () async {
    final saved = await repository.save(sample('Toko A', DateTime(2026, 11, 1)));

    await repository.delete(saved.id!);

    expect(await repository.all(), isEmpty);
  });
}
