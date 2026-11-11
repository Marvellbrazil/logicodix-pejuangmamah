import 'money.dart';

class LineItem {
  const LineItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String name;
  final int quantity;
  final Money unitPrice;

  Money get subtotal => unitPrice * quantity;
}

class Receipt {
  const Receipt({
    this.id,
    required this.merchant,
    required this.date,
    required this.items,
  });

  final int? id;
  final String merchant;
  final DateTime date;
  final List<LineItem> items;

  Money get total => items.fold(Money.zero, (sum, item) => sum + item.subtotal);

  Receipt copyWith({
    int? id,
    String? merchant,
    DateTime? date,
    List<LineItem>? items,
  }) {
    return Receipt(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      items: items ?? this.items,
    );
  }
}

abstract interface class ReceiptRepository {
  Future<List<Receipt>> all();

  Future<Receipt> save(Receipt receipt);

  Future<void> delete(int id);
}
