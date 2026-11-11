import 'package:flutter_test/flutter_test.dart';
import 'package:pejuangmamah/application/receipt_parser.dart';
import 'package:pejuangmamah/domain/money.dart';

void main() {
  final parser = ReceiptParser();
  final fallback = DateTime(2026, 11, 11);

  test('parses merchant, date, items and ignores summary rows', () {
    final receipt = parser.parse([
      'TOKO MAJU JAYA',
      'Jl. Merdeka No. 5',
      '12/11/2026 10:21',
      'Telur Ayam 2 x 28.000 56.000',
      'Beras 5kg 65.000',
      'Minyak Goreng 1 18.500',
      'Subtotal 139.500',
      'Total 139.500',
      'Tunai 150.000',
    ], fallbackDate: fallback);

    expect(receipt.merchant, 'TOKO MAJU JAYA');
    expect(receipt.date, DateTime(2026, 11, 12));
    expect(receipt.items.map((i) => i.name), [
      'Telur Ayam',
      'Beras 5kg',
      'Minyak Goreng',
    ]);
    expect(receipt.items[0].quantity, 2);
    expect(receipt.items[0].unitPrice, const Money(28000));
    expect(receipt.items[1].subtotal, const Money(65000));
    expect(receipt.total, const Money(139500));
  });

  test('handles leading quantity and Rp prefix', () {
    final receipt = parser.parse([
      'Warung Bu Sri',
      '3 Gula Pasir Rp 45.000',
    ], fallbackDate: fallback);

    expect(receipt.items.single.name, 'Gula Pasir');
    expect(receipt.items.single.quantity, 3);
    expect(receipt.items.single.unitPrice, const Money(15000));
  });

  test('falls back to defaults when nothing recognisable', () {
    final receipt = parser.parse(['???', ''], fallbackDate: fallback);

    expect(receipt.items, isEmpty);
    expect(receipt.date, fallback);
    expect(receipt.merchant, 'Nota');
  });

  test('rejects impossible dates', () {
    final receipt = parser.parse([
      'Toko A',
      '31/02/2026',
      'Kopi 12.000',
    ], fallbackDate: fallback);

    expect(receipt.date, fallback);
    expect(receipt.items.single.name, 'Kopi');
  });

  test('Money formats rupiah with dot grouping', () {
    expect(const Money(1250000).format(), 'Rp 1.250.000');
    expect(const Money(500).format(), 'Rp 500');
    expect(Money.zero.format(), 'Rp 0');
  });
}
