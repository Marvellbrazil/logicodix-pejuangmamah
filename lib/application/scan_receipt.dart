import '../domain/receipt.dart';
import 'receipt_parser.dart';

abstract interface class ReceiptTextReader {
  Future<List<String>> readRows(String imagePath);
}

class ScanReceipt {
  ScanReceipt(this._reader, this._parser);

  final ReceiptTextReader _reader;
  final ReceiptParser _parser;

  Future<Receipt> call(String imagePath, {DateTime? today}) async {
    final rows = await _reader.readRows(imagePath);
    return _parser.parse(rows, fallbackDate: today ?? DateTime.now());
  }
}
