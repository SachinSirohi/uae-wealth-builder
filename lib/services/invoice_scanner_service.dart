import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class InvoiceScannerService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _imagePicker = ImagePicker();

  Future<ScannedInvoice?> scanInvoice() async {
    try {
      // 1. Pick Image
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image == null) return null;

      // 2. Process Image
      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      // 3. Parse Text
      return _parseInvoiceText(recognizedText);
    } catch (e) {
      debugPrint('Error scanning invoice: $e');
      return null;
    }
  }

  ScannedInvoice _parseInvoiceText(RecognizedText recognizedText) {
    double? totalAmount;
    DateTime? date;
    String? merchantName;

    // Simple Heuristics for Parsing
    // This can be improved with regex and more complex logic

    // 1. Find Total Amount
    // Look for lines containing "Total", "Amount", "AED", etc.
    final amountRegex = RegExp(r'(?:Total|Amount|Net|Grand Total)[\s:]*([0-9,.]+)', caseSensitive: false);
    final currencyRegex = RegExp(r'(?:AED|Dhs|USD)[\s]*([0-9,.]+)', caseSensitive: false);

    // 2. Find Date
    // Look for common date formats
    final dateRegex = RegExp(r'(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})');

    // Iterate through blocks to find merchant (usually top center)
    if (recognizedText.blocks.isNotEmpty) {
      // Assume the first block with significant text is the merchant
      for (var block in recognizedText.blocks) {
        if (block.text.length > 3 && !block.text.contains(RegExp(r'[0-9]'))) {
           merchantName ??= block.text.split('\n').first; // Take first line of block
           break;
        }
      }
    }

    // Iterate through lines for specific fields
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        String text = line.text;

        // Check for Amount
        if (totalAmount == null) {
          var match = amountRegex.firstMatch(text);
          if (match != null) {
             totalAmount = double.tryParse(match.group(1)?.replaceAll(',', '') ?? '');
          } else {
             match = currencyRegex.firstMatch(text);
             if (match != null) {
                totalAmount = double.tryParse(match.group(1)?.replaceAll(',', '') ?? '');
             }
          }
        }

        // Check for Date
        if (date == null) {
          var match = dateRegex.firstMatch(text);
          if (match != null) {
            try {
              // Try common formats
              List<String> formats = ['dd/MM/yyyy', 'dd-MM-yyyy', 'yyyy-MM-dd', 'dd/MM/yy'];
              for (var format in formats) {
                try {
                  date = DateFormat(format).parse(match.group(1)!);
                  break;
                } catch (_) {}
              }
            } catch (_) {}
          }
        }
      }
    }

    return ScannedInvoice(
      merchantName: merchantName ?? 'Unknown Merchant',
      amount: totalAmount ?? 0.0,
      date: date ?? DateTime.now(),
      rawText: recognizedText.text,
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}

class ScannedInvoice {
  final String merchantName;
  final double amount;
  final DateTime date;
  final String rawText;

  ScannedInvoice({
    required this.merchantName,
    required this.amount,
    required this.date,
    required this.rawText,
  });
}
