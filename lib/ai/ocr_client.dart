import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'whisper_client.dart';

class OcrException implements Exception {
  const OcrException(this.message);
  final String message;

  @override
  String toString() => 'OcrException($message)';
}

/// Reads the text on a photo (receipt, invoice) with Tesseract (Khmer +
/// English models), served by the same service as speech-to-text
/// (`services/whisper`, `POST /ocr`).
class OcrClient {
  OcrClient({
    this.baseUrl = whisperUrl,
    this.token = whisperToken,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final String token;
  final http.Client _http;

  bool get isConfigured => baseUrl.isNotEmpty;

  /// Returns all text found in [image], line by line, or an empty string
  /// when there is none.
  Future<String> detectText(Uint8List image) async {
    if (!isConfigured) throw const OcrException('WHISPER_URL is not set');
    final http.Response response;
    try {
      response = await _http
          .post(
            Uri.parse('$baseUrl/ocr'),
            headers: {
              'Content-Type': 'application/octet-stream',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: image,
          )
          // A sleeping free Space can take a while to wake up.
          .timeout(const Duration(seconds: 90));
    } catch (e) {
      throw OcrException('Network error: $e');
    }
    if (response.statusCode != 200) {
      throw OcrException('HTTP ${response.statusCode}: ${response.body}');
    }
    final text = (jsonDecode(utf8.decode(response.bodyBytes)) as Map)['text'];
    if (text is! String) throw const OcrException('No text in response');
    return text.trim();
  }

  void close() => _http.close();
}
