import '../domain/money.dart';
import '../domain/receipt.dart';

class ReceiptParser {
  static final _price = RegExp(
    r'(?<![\w.,])(?:Rp\.?\s*)?(\d{1,3}(?:[.,]\d{3})+|\d{3,})(?:[.,]\d{2})?(?!\w)',
    caseSensitive: false,
  );
  static final _skip = RegExp(
    r'\b(total|subtotal|jumlah|bayar|tunai|cash|kembali|kembalian|change|ppn|pajak|tax|diskon|discount|npwp|telp|tel|kasir|invoice)\b',
    caseSensitive: false,
  );
  static final _isoDate = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})');
  static final _dmyDate = RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})');
  static final _trailingQty = RegExp(r'(\d{1,3})\s*[xX@]\s*$');
  static final _leadingQty = RegExp(r'^(\d{1,3})\s*[xX]?\s+(?=\D)');
  static final _trailingBare = RegExp(r'\s(\d{1,3})$');
  static final _edgeNoise = RegExp(r'^[\s\-:*.,]+|[\s\-:*.,]+$');
  static final _letter = RegExp(r'[A-Za-z]');

  Receipt parse(List<String> rows, {required DateTime fallbackDate}) {
    DateTime? date;
    String? merchant;
    final items = <LineItem>[];

    for (final raw in rows) {
      final row = raw.trim();
      if (row.isEmpty) continue;

      final parsedDate = _tryDate(row);
      if (parsedDate != null) {
        date ??= parsedDate;
        continue;
      }
      if (_skip.hasMatch(row)) continue;

      final item = _tryItem(row);
      if (item != null) {
        items.add(item);
        continue;
      }
      if (merchant == null && items.isEmpty && _isMerchant(row)) {
        merchant = row;
      }
    }

    return Receipt(
      merchant: merchant ?? 'Nota',
      date: date ?? fallbackDate,
      items: items,
    );
  }

  bool _isMerchant(String row) {
    return row.length >= 3 && _letter.hasMatch(row) && !_price.hasMatch(row);
  }

  DateTime? _tryDate(String row) {
    final iso = _isoDate.firstMatch(row);
    if (iso != null) {
      return _validDate(
        int.parse(iso[1]!),
        int.parse(iso[2]!),
        int.parse(iso[3]!),
      );
    }
    final dmy = _dmyDate.firstMatch(row);
    if (dmy != null) {
      var year = int.parse(dmy[3]!);
      if (year < 100) year += 2000;
      return _validDate(year, int.parse(dmy[2]!), int.parse(dmy[1]!));
    }
    return null;
  }

  DateTime? _validDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final date = DateTime(year, month, day);
    return date.month == month ? date : null;
  }

  int _amount(RegExpMatch match) {
    return int.parse(match[1]!.replaceAll(RegExp(r'[.,]'), ''));
  }

  LineItem? _tryItem(String row) {
    final matches = _price.allMatches(row).toList();
    if (matches.isEmpty) return null;

    final amounts = matches.map(_amount).toList();
    final total = amounts.last;
    final unit = amounts.length >= 2 ? amounts[amounts.length - 2] : null;

    var name = row.substring(0, matches.first.start).trim();
    int? explicitQty;
    var leading = false;

    final trailing = _trailingQty.firstMatch(name);
    if (trailing != null) {
      explicitQty = int.parse(trailing[1]!);
      name = name.substring(0, trailing.start);
    } else {
      final lead = _leadingQty.firstMatch(name);
      if (lead != null) {
        explicitQty = int.parse(lead[1]!);
        leading = true;
        name = name.substring(lead.end);
      }
    }

    int quantity;
    int unitPrice;
    if (unit != null && unit > 0 && total % unit == 0) {
      quantity = total ~/ unit;
      unitPrice = unit;
      if (explicitQty == null) {
        final bare = _trailingBare.firstMatch(name);
        if (bare != null && int.parse(bare[1]!) == quantity) {
          name = name.substring(0, bare.start);
        }
      }
    } else {
      var totalIsLine = leading;
      if (explicitQty == null) {
        final bare = _trailingBare.firstMatch(name);
        if (bare != null) {
          explicitQty = int.parse(bare[1]!);
          name = name.substring(0, bare.start);
          totalIsLine = true;
        }
      }
      quantity = explicitQty ?? 1;
      unitPrice = totalIsLine && quantity > 1 && total % quantity == 0
          ? total ~/ quantity
          : total;
    }

    name = name.replaceAll(_edgeNoise, '');
    if (!_letter.hasMatch(name) || quantity < 1 || unitPrice <= 0) return null;

    return LineItem(
      name: name,
      quantity: quantity,
      unitPrice: Money(unitPrice),
    );
  }
}
