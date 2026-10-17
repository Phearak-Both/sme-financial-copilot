import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Set at build time: `flutter run --dart-define-from-file=env/dev.json`.
///
/// Development only. Before real users, the key moves behind the Supabase
/// Edge Function proxy so it never ships inside the app.
const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
// Flash-Lite answers in about a second; Flash sometimes took 15-60 s.
const geminiModel = String.fromEnvironment(
  'GEMINI_MODEL',
  defaultValue: 'gemini-flash-lite-latest',
);

/// Tried in order when the previous model is out of free quota or too slow.
/// Each model has its own daily request quota (as low as 20 a day).
const geminiFallbackModels = ['gemini-flash-latest', 'gemini-3.5-flash'];

/// How long to wait before trying the next model instead.
const _modelTimeout = Duration(seconds: 15);

/// One piece of a request: text, or inline bytes such as audio or an image.
sealed class AiPart {
  const AiPart();
}

class TextPart extends AiPart {
  const TextPart(this.text);
  final String text;
}

class BytesPart extends AiPart {
  const BytesPart(this.bytes, this.mimeType);
  final Uint8List bytes;
  final String mimeType;
}

class AiException implements Exception {
  const AiException(this.message, {this.isQuota = false});

  final String message;

  /// True when the free-tier rate limit was hit.
  final bool isQuota;

  @override
  String toString() => 'AiException($message)';
}

/// Minimal Gemini REST client that returns structured JSON.
class GeminiClient {
  GeminiClient({
    this.apiKey = geminiApiKey,
    String model = geminiModel,
    List<String> fallbackModels = geminiFallbackModels,
    this.modelTimeout = _modelTimeout,
    http.Client? httpClient,
  }) : models = [model, ...fallbackModels.where((m) => m != model)],
       _http = httpClient ?? http.Client();

  final String apiKey;

  /// The preferred model first, then fallbacks.
  final List<String> models;

  /// How long one model gets before the next one is tried.
  final Duration modelTimeout;
  final http.Client _http;

  /// Index of the first model not known to be out of quota this session.
  int _current = 0;

  bool get isConfigured => apiKey.isNotEmpty;

  /// Sends [parts] and returns the model's JSON reply, shaped by [schema].
  Future<Map<String, dynamic>> generateJson({
    required String systemInstruction,
    required List<AiPart> parts,
    required Map<String, dynamic> schema,
  }) async {
    if (!isConfigured) throw const AiException('GEMINI_API_KEY is not set');

    final body = {
      'systemInstruction': {
        'parts': [
          {'text': systemInstruction},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [for (final part in parts) _encodePart(part)],
        },
      ],
      'generationConfig': {
        // Low thinking keeps replies to a few seconds; default can take 30s+.
        'thinkingConfig': {'thinkingLevel': 'low'},
        // Replies are small JSON; a cap stops a rambling model early.
        'maxOutputTokens': 2048,
        'responseMimeType': 'application/json',
        'responseSchema': schema,
      },
    };

    var timedOut = false;
    for (var i = _current; i < models.length; i++) {
      final http.Response response;
      final watch = Stopwatch()..start();
      try {
        response = await _post(models[i], body);
      } on _SlowModel {
        // Slow right now, not broken: try the next model this time only.
        debugPrint('[ai] ${models[i]} timed out');
        timedOut = true;
        continue;
      }
      debugPrint(
        '[ai] ${models[i]} -> ${response.statusCode} '
        'in ${watch.elapsedMilliseconds} ms',
      );
      if (response.statusCode == 429) {
        // Out of quota: skip this model for the rest of the session.
        _current = i + 1 < models.length ? i + 1 : _current;
        continue;
      }
      return _parse(response);
    }
    throw timedOut
        ? const AiException('All models timed out')
        : const AiException('Rate limit reached', isQuota: true);
  }

  Future<http.Response> _post(String model, Map<String, dynamic> body) async {
    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$model:generateContent',
    );
    try {
      return await _http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey,
            },
            body: jsonEncode(body),
          )
          .timeout(modelTimeout);
    } on TimeoutException {
      throw const _SlowModel();
    } catch (e) {
      throw AiException('Network error: $e');
    }
  }

  Map<String, dynamic> _parse(http.Response response) {
    if (response.statusCode != 200) {
      throw AiException('HTTP ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final text =
        (((decoded['candidates'] as List?)?.firstOrNull
                    as Map?)?['content']?['parts']
                as List?)
            ?.whereType<Map>()
            .map((p) => p['text'])
            .whereType<String>()
            .join();
    if (text == null || text.isEmpty) {
      throw const AiException('Empty response');
    }
    try {
      return jsonDecode(text) as Map<String, dynamic>;
    } on FormatException {
      throw const AiException('Response was not valid JSON');
    }
  }

  Map<String, dynamic> _encodePart(AiPart part) => switch (part) {
    TextPart(:final text) => {'text': text},
    BytesPart(:final bytes, :final mimeType) => {
      'inlineData': {'mimeType': mimeType, 'data': base64Encode(bytes)},
    },
  };

  void close() => _http.close();
}

class _SlowModel implements Exception {
  const _SlowModel();
}
