import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Khmer speech-to-text service (`services/whisper`), running
/// `1morecupofhottea/whisper-turbo-khmer-v9`. Set at build time, e.g.
/// `"WHISPER_URL": "http://127.0.0.1:7860"` in `env/dev.json`.
const whisperUrl = String.fromEnvironment('WHISPER_URL');
const whisperToken = String.fromEnvironment('WHISPER_TOKEN');

class WhisperException implements Exception {
  const WhisperException(this.message);
  final String message;

  @override
  String toString() => 'WhisperException($message)';
}

class WhisperClient {
  WhisperClient({
    this.baseUrl = whisperUrl,
    this.token = whisperToken,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final String token;
  final http.Client _http;

  bool get isConfigured => baseUrl.isNotEmpty;

  /// Returns the transcript of [audio], with the model's `;` separators
  /// already removed by the service. [live] asks for a fast, rougher
  /// preview to show while the user is still talking. [languageCode] is
  /// `km` (Khmer model) or `en` (English model).
  Future<String> transcribe(
    Uint8List audio,
    String mimeType, {
    bool live = false,
    String languageCode = 'km',
  }) async {
    if (!isConfigured) throw const WhisperException('WHISPER_URL is not set');
    final http.Response response;
    try {
      response = await _http
          .post(
            Uri.parse('$baseUrl/transcribe').replace(
              queryParameters: {
                'lang': languageCode == 'en' ? 'en' : 'km',
                if (live) 'live': '1',
              },
            ),
            headers: {
              'Content-Type': mimeType,
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: audio,
          )
          // A sleeping free Space can take a while to wake up.
          .timeout(const Duration(seconds: 90));
    } catch (e) {
      throw WhisperException('Network error: $e');
    }
    if (response.statusCode != 200) {
      throw WhisperException('HTTP ${response.statusCode}: ${response.body}');
    }
    final text = (jsonDecode(utf8.decode(response.bodyBytes)) as Map)['text'];
    if (text is! String) throw const WhisperException('No text in response');
    return text.trim();
  }

  void close() => _http.close();
}
