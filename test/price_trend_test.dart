import 'package:flutter_test/flutter_test.dart';
import 'package:pejuangmamah/domain/money.dart';
import 'package:pejuangmamah/domain/price_trend.dart';
import 'package:pejuangmamah/domain/receipt.dart';

Receipt receipt(int id, DateTime date, Map<String, int> prices) => Receipt(
  id: id,
  merchant: 'Toko',
  date: date,
  items: [
    for (final entry in prices.entries)
      LineItem(name: entry.key, quantity: 1, unitPrice: Money(entry.value)),
  ],
);

void main() {
  test('detects increase between the two latest receipts', () {
    final changes = detectPriceChanges([
      receipt(2, DateTime(2026, 11, 8), {'Telur': 30000}),
      receipt(1, DateTime(2026, 11, 1), {'Telur': 25000}),
    ]);

    expect(changes, hasLength(1));
    expect(changes.single.name, 'Telur');
    expect(changes.single.previous, const Money(25000));
    expect(changes.single.latest, const Money(30000));
    expect(changes.single.isIncrease, isTrue);
    expect(changes.single.percent, closeTo(20, 0.001));
  });

  test('matches names ignoring case and punctuation', () {
    final changes = detectPriceChanges([
      receipt(1, DateTime(2026, 11, 1), {'Telur Ayam': 28000}),
      receipt(2, DateTime(2026, 11, 8), {'TELUR  AYAM.': 26000}),
    ]);

    expect(changes.single.isIncrease, isFalse);
    expect(changes.single.percent, closeTo(-7.142, 0.01));
  });

  test('ignores unchanged prices and single sightings', () {
    final changes = detectPriceChanges([
      receipt(1, DateTime(2026, 11, 1), {'Gula': 15000, 'Beras': 65000}),
      receipt(2, DateTime(2026, 11, 8), {'Gula': 15000}),
    ]);

    expect(changes, isEmpty);
  });

  test('compares only the latest pair and sorts by largest move', () {
    final changes = detectPriceChanges([
      receipt(1, DateTime(2026, 11, 1), {'Telur': 20000, 'Gula': 10000}),
      receipt(2, DateTime(2026, 11, 5), {'Telur': 25000, 'Gula': 10000}),
      receipt(3, DateTime(2026, 11, 9), {'Telur': 26000, 'Gula': 12000}),
    ]);

    expect(changes.map((c) => c.name), ['Gula', 'Telur']);
    expect(changes.last.previous, const Money(25000));
  });

  test('normalizeItemName collapses whitespace and symbols', () {
    expect(normalizeItemName('  Minyak-Goreng  1L! '), 'minyak goreng 1l');
    expect(normalizeItemName('***'), isEmpty);
  });
}
