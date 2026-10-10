import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'comparison.dart';
class Draft {
  Draft(this.text, {this.price = '', this.quantity = '', this.unit = Unit.gram});
  final String text;
  final String price, quantity;
  final Unit unit;
}
Draft parseDraft(String text) {
  final weight = RegExp(r'(\d+(?:[.,]\d+)?)\s*(кг|kg|мл|ml|г|g|л|l|шт)\b', caseSensitive: false).firstMatch(text);
  Unit unit = Unit.gram;
  if (weight != null) {
    unit = switch (weight.group(2)!.toLowerCase()) {
      'кг' || 'kg' => Unit.kilogram,
      'мл' || 'ml' => Unit.milliliter,
      'л' || 'l' => Unit.liter,
      'шт' => Unit.piece,
      _ => Unit.gram,
    };
  }
  // Only explicitly marked currency values; multiple prices require manual selection.
  final prices = RegExp(r'(\d+(?:[.,]\d{1,2})?)\s*(?:₽|руб\.?|rub|р\.)', caseSensitive: false).allMatches(text).toList();
  return Draft(text, price: prices.length == 1 ? prices.single.group(1)! : '',
      quantity: weight?.group(1) ?? '', unit: unit);
}
abstract class LabelScanner {
  Future<List<Draft>> scan(String path, {required bool multiple});
}
class MlKitScanner implements LabelScanner {
  @override
  Future<List<Draft>> scan(String path, {required bool multiple}) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(path));
      if (result.text.trim().isEmpty) return [];
      // A text block is not guaranteed to be a label. All candidates require review.
      if (multiple) return result.blocks.map((b) => parseDraft(b.text)).toList();
      return [parseDraft(result.text)];
    } finally {
      await recognizer.close();
    }
  }
}
