import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/receipt_data.dart';

class ReceiptScannerService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<ReceiptData?> scanReceipt(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    try {
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      return ReceiptData(rawText: recognizedText.text, confidence: 0.0);
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
