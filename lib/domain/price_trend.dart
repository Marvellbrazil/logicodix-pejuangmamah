import 'money.dart';
import 'receipt.dart';

typedef _Observation = ({String name, Money price, DateTime date});

class PriceChange {
  const PriceChange({
    required this.name,
    required this.previous,
    required this.latest,
    required this.date,
  });

  final String name;
  final Money previous;
  final Money latest;
  final DateTime date;

  int get difference => latest.rupiah - previous.rupiah;

  double get percent => difference / previous.rupiah * 100;

  bool get isIncrease => difference > 0;
}

String normalizeItemName(String name) {
  return name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .join(' ');
}

List<PriceChange> detectPriceChanges(List<Receipt> receipts) {
  final ordered = [...receipts]
    ..sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      return byDate != 0 ? byDate : (a.id ?? 0).compareTo(b.id ?? 0);
    });

  final history = <String, List<_Observation>>{};
  for (final receipt in ordered) {
    final perReceipt = <String, _Observation>{};
    for (final item in receipt.items) {
      final key = normalizeItemName(item.name);
      if (key.isEmpty) continue;
      perReceipt[key] = (
        name: item.name,
        price: item.unitPrice,
        date: receipt.date,
      );
    }
    perReceipt.forEach(
      (key, observation) => history.putIfAbsent(key, () => []).add(observation),
    );
  }

  final changes = <PriceChange>[];
  for (final observations in history.values) {
    if (observations.length < 2) continue;
    final previous = observations[observations.length - 2];
    final latest = observations.last;
    if (previous.price == latest.price || previous.price.rupiah <= 0) continue;
    changes.add(
      PriceChange(
        name: latest.name,
        previous: previous.price,
        latest: latest.price,
        date: latest.date,
      ),
    );
  }
  changes.sort((a, b) => b.percent.abs().compareTo(a.percent.abs()));
  return changes;
}
