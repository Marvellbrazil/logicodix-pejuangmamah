import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../application/scan_receipt.dart';

class MlKitReceiptTextReader implements ReceiptTextReader {
  @override
  Future<List<String>> readRows(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      final lines = [for (final block in result.blocks) ...block.lines]
        ..sort(
          (a, b) => a.boundingBox.center.dy.compareTo(b.boundingBox.center.dy),
        );

      final rows = <List<TextLine>>[];
      for (final line in lines) {
        if (rows.isNotEmpty) {
          final anchor = rows.last.first.boundingBox;
          final gap = (line.boundingBox.center.dy - anchor.center.dy).abs();
          if (gap < anchor.height * 0.6) {
            rows.last.add(line);
            continue;
          }
        }
        rows.add([line]);
      }

      return [
        for (final row in rows)
          (row..sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left)))
              .map((line) => line.text)
              .join(' '),
      ];
    } finally {
      await recognizer.close();
    }
  }
}
