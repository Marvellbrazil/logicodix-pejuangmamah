import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/money.dart';
import '../domain/receipt.dart';
import 'format.dart';

class ReceiptReviewScreen extends StatefulWidget {
  const ReceiptReviewScreen({super.key, required this.receipt});

  final Receipt receipt;

  @override
  State<ReceiptReviewScreen> createState() => _ReceiptReviewScreenState();
}

class _ItemDraft {
  _ItemDraft([LineItem? item])
    : name = TextEditingController(text: item?.name ?? ''),
      quantity = TextEditingController(text: '${item?.quantity ?? 1}'),
      price = TextEditingController(
        text: item == null ? '' : '${item.unitPrice.rupiah}',
      );

  final TextEditingController name;
  final TextEditingController quantity;
  final TextEditingController price;

  bool get isBlank =>
      name.text.trim().isEmpty &&
      price.text.trim().isEmpty &&
      quantity.text.trim() == '1';

  LineItem? toItem() {
    final label = name.text.trim();
    final qty = int.tryParse(quantity.text.trim());
    final unit = int.tryParse(price.text.trim());
    if (label.isEmpty || qty == null || qty < 1 || unit == null || unit < 1) {
      return null;
    }
    return LineItem(name: label, quantity: qty, unitPrice: Money(unit));
  }

  void dispose() {
    name.dispose();
    quantity.dispose();
    price.dispose();
  }
}

class _ReceiptReviewScreenState extends State<ReceiptReviewScreen> {
  late final TextEditingController _merchant;
  late final List<_ItemDraft> _drafts;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final receipt = widget.receipt;
    _merchant = TextEditingController(text: receipt.merchant);
    _date = receipt.date;
    _drafts = [for (final item in receipt.items) _ItemDraft(item)];
    if (_drafts.isEmpty) _drafts.add(_ItemDraft());
  }

  @override
  void dispose() {
    _merchant.dispose();
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Money get _total => _drafts
      .map((draft) => draft.toItem())
      .whereType<LineItem>()
      .fold(Money.zero, (sum, item) => sum + item.subtotal);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _addItem() => setState(() => _drafts.add(_ItemDraft()));

  void _removeItem(int index) {
    setState(() => _drafts.removeAt(index).dispose());
    if (_drafts.isEmpty) _addItem();
  }

  void _warn(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _save() {
    if (_merchant.text.trim().isEmpty) return _warn('Isi nama toko dulu.');
    final filled = _drafts.where((draft) => !draft.isBlank).toList();
    final items = filled.map((draft) => draft.toItem()).toList();
    if (filled.isEmpty || items.contains(null)) {
      return _warn('Lengkapi nama, jumlah, dan harga setiap barang.');
    }
    Navigator.of(context).pop(
      widget.receipt.copyWith(
        merchant: _merchant.text.trim(),
        date: _date,
        items: items.whereType<LineItem>().toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Periksa nota')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            'Cek hasil baca otomatis. Perbaiki yang salah sebelum disimpan.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _merchant,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nama toko'),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Tanggal',
                suffixIcon: Icon(Icons.calendar_today_outlined),
              ),
              child: Text(formatDate(_date)),
            ),
          ),
          const SizedBox(height: 24),
          Text('Barang', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          for (var i = 0; i < _drafts.length; i++) ...[
            if (i > 0) const Divider(height: 28),
            _ItemFields(
              draft: _drafts[i],
              onChanged: () => setState(() {}),
              onRemove: () => _removeItem(i),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: const Text('Tambah barang'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: theme.textTheme.titleMedium),
                  Text(
                    _total.format(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _save, child: const Text('Simpan')),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemFields extends StatelessWidget {
  const _ItemFields({
    required this.draft,
    required this.onChanged,
    required this.onRemove,
  });

  final _ItemDraft draft;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final digits = [FilteringTextInputFormatter.digitsOnly];
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: draft.name,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => onChanged(),
                decoration: const InputDecoration(labelText: 'Nama barang'),
              ),
            ),
            IconButton(
              tooltip: 'Hapus barang',
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: 88,
              child: TextField(
                controller: draft.quantity,
                keyboardType: TextInputType.number,
                inputFormatters: digits,
                onChanged: (_) => onChanged(),
                decoration: const InputDecoration(labelText: 'Jumlah'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: draft.price,
                keyboardType: TextInputType.number,
                inputFormatters: digits,
                onChanged: (_) => onChanged(),
                decoration: const InputDecoration(
                  labelText: 'Harga satuan',
                  prefixText: 'Rp ',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
