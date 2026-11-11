import 'package:flutter/material.dart';

import '../domain/price_trend.dart';
import 'format.dart';

class PriceChangesCard extends StatelessWidget {
  const PriceChangesCard({super.key, required this.changes});

  final List<PriceChange> changes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Perubahan harga', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final change in changes) _PriceChangeRow(change: change),
          ],
        ),
      ),
    );
  }
}

class _PriceChangeRow extends StatelessWidget {
  const _PriceChangeRow({required this.change});

  final PriceChange change;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = change.isIncrease
        ? theme.colorScheme.error
        : theme.colorScheme.primary;
    final label =
        '${change.isIncrease ? 'Naik' : 'Turun'} ${formatPercent(change.percent)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Semantics(
        label:
            '${change.name}, harga ${label.toLowerCase()}, dari ${change.previous.format()} menjadi ${change.latest.format()}',
        excludeSemantics: true,
        child: Row(
          children: [
            Icon(
              change.isIncrease ? Icons.trending_up : Icons.trending_down,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(change.name, style: theme.textTheme.bodyLarge),
                  Text(
                    '${change.previous.format()} → ${change.latest.format()}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
