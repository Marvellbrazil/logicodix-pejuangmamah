import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../application/scan_receipt.dart';
import '../domain/money.dart';
import '../domain/receipt.dart';
import 'format.dart';
import 'receipt_review_screen.dart';

class ReceiptListScreen extends StatefulWidget {
  const ReceiptListScreen({
    super.key,
    required this.repository,
    required this.scanReceipt,
  });

  final ReceiptRepository repository;
  final ScanReceipt scanReceipt;

  @override
  State<ReceiptListScreen> createState() => _ReceiptListScreenState();
}

class _ReceiptListScreenState extends State<ReceiptListScreen> {
  final _picker = ImagePicker();
  List<Receipt>? _receipts;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final receipts = await widget.repository.all();
    if (!mounted) return;
    setState(() => _receipts = receipts);
  }

  Future<void> _review(Receipt receipt) async {
    final edited = await Navigator.of(context).push<Receipt>(
      MaterialPageRoute(builder: (_) => ReceiptReviewScreen(receipt: receipt)),
    );
    if (edited == null) return;
    await widget.repository.save(edited);
    await _load();
  }

  Future<void> _scan(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() => _scanning = true);
    final Receipt receipt;
    try {
      receipt = await widget.scanReceipt(picked.path);
    } catch (_) {
      if (!mounted) return;
      setState(() => _scanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membaca nota. Coba foto ulang atau input manual.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _scanning = false);
    await _review(receipt);
  }

  Future<void> _addManually() {
    return _review(
      Receipt(merchant: '', date: DateTime.now(), items: const []),
    );
  }

  Future<void> _confirmDelete(Receipt receipt) async {
    final id = receipt.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus nota?'),
        content: Text('Nota ${receipt.merchant} akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.repository.delete(id);
    await _load();
  }

  Future<void> _chooseSource() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        void pick(Future<void> Function() action) {
          Navigator.of(sheetContext).pop();
          action();
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Foto dengan kamera'),
                onTap: () => pick(() => _scan(ImageSource.camera)),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Pilih dari galeri'),
                onTap: () => pick(() => _scan(ImageSource.gallery)),
              ),
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text('Input manual'),
                onTap: () => pick(_addManually),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final receipts = _receipts;
    return Scaffold(
      appBar: AppBar(title: const Text('Nota UMKM')),
      body: Column(
        children: [
          if (_scanning)
            const LinearProgressIndicator(semanticsLabel: 'Membaca nota'),
          Expanded(
            child: receipts == null
                ? const Center(child: CircularProgressIndicator())
                : receipts.isEmpty
                ? const _EmptyState()
                : _ReceiptList(
                    receipts: receipts,
                    onOpen: _review,
                    onDelete: _confirmDelete,
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanning ? null : _chooseSource,
        icon: const Icon(Icons.document_scanner_outlined),
        label: const Text('Scan nota'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Belum ada nota', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Foto nota belanja, data barang dan harganya masuk otomatis.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptList extends StatelessWidget {
  const _ReceiptList({
    required this.receipts,
    required this.onOpen,
    required this.onDelete,
  });

  final List<Receipt> receipts;
  final ValueChanged<Receipt> onOpen;
  final ValueChanged<Receipt> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = receipts.fold(Money.zero, (sum, r) => sum + r.total);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      itemCount: receipts.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total pengeluaran', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    total.format(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${receipts.length} nota',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }
        final receipt = receipts[index - 1];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
            onTap: () => onOpen(receipt),
            title: Text(receipt.merchant),
            subtitle: Text(
              '${formatDate(receipt.date)} · ${receipt.items.length} barang',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  receipt.total.format(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                IconButton(
                  tooltip: 'Hapus nota',
                  onPressed: () => onDelete(receipt),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
