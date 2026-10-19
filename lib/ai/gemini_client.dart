import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Set at build time: `flutter run --dart-define-from-file=env/dev.json`.
///
/// Only used without Supabase (local development). With Supabase, requests
/// go through the `gemini` Edge Function, which holds the key as a secret.
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

/// The Supabase Edge Function that forwards requests to Gemini with the
/// server-side key. Callers must be signed in.
class GeminiProxy {
  const GeminiProxy({
    required this.url,
    required this.publishableKey,
    required this.accessToken,
  });

  /// e.g. `https://<project>.supabase.co/functions/v1/gemini`.
  final Uri url;
  final String publishableKey;

  /// The signed-in user's token, or null when signed out.
  final String? Function() accessToken;
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
    this.proxy,
    String model = geminiModel,
    List<String> fallbackModels = geminiFallbackModels,
    this.modelTimeout = _modelTimeout,
    http.Client? httpClient,
  }) : models = [model, ...fallbackModels.where((m) => m != model)],
       _http = httpClient ?? http.Client();

  final String apiKey;

  /// When set, requests go through the proxy and [apiKey] is not used.
  final GeminiProxy? proxy;

  /// The preferred model first, then fallbacks.
  final List<String> models;

  /// How long one model gets before the next one is tried.
  final Duration modelTimeout;
  final http.Client _http;

  /// Index of the first model not known to be out of quota this session.
  int _current = 0;

  bool get isConfigured => proxy != null || apiKey.isNotEmpty;

  /// Sends [parts] and returns the model's JSON reply, shaped by [schema].
  ///
  /// [thinkingLevel] `minimal` suits plain tasks like transcribing: a short
  /// voice clip took about 8 s at `low` and 2 s at `minimal`. Models that
  /// don't support `minimal` are asked again at `low`.
  Future<Map<String, dynamic>> generateJson({
    required String systemInstruction,
    required List<AiPart> parts,
    required Map<String, dynamic> schema,
    String thinkingLevel = 'low',
  }) async {
    if (!isConfigured) throw const AiException('GEMINI_API_KEY is not set');

    Map<String, dynamic> requestBody(String thinkingLevel) => {
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
        'thinkingConfig': {'thinkingLevel': thinkingLevel},
        // Replies are small JSON; a cap stops a rambling model early.
        'maxOutputTokens': 2048,
        'responseMimeType': 'application/json',
        'responseSchema': schema,
      },
    };
    // Audio and images vary most: the same 8 s voice clip took 3 to 19 s.
    // Cutting them off early throws away an answer that was nearly done.
    final timeout = parts.any((p) => p is BytesPart)
        ? modelTimeout * 2
        : modelTimeout;

    var timedOut = false;
    Object? networkError;
    for (var i = _current; i < models.length; i++) {
      http.Response response;
      final watch = Stopwatch()..start();
      try {
        response = await _post(models[i], requestBody(thinkingLevel), timeout);
        if (response.statusCode == 400 &&
            thinkingLevel != 'low' &&
            response.body.contains('Thinking level')) {
          response = await _post(models[i], requestBody('low'), timeout);
        }
      } on _SlowModel {
        // Slow right now, not broken: try the next model this time only.
        debugPrint('[ai] ${models[i]} timed out');
        timedOut = true;
        continue;
      } on _NetworkFailure catch (e) {
        // A dropped connection is usually brief; the next try may get through.
        debugPrint('[ai] ${models[i]} network error: ${e.error}');
        networkError = e.error;
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
      if (response.statusCode >= 500 && i + 1 < models.length) {
        // Overloaded ("high demand") or down: try the next model this time.
        continue;
      }
      return _parse(response);
    }
    if (networkError != null) throw AiException('Network error: $networkError');
    throw timedOut
        ? const AiException('All models timed out')
        : const AiException('Rate limit reached', isQuota: true);
  }

  Future<http.Response> _post(
    String model,
    Map<String, dynamic> body,
    Duration timeout,
  ) async {
    final proxy = this.proxy;
    final Uri uri;
    final Map<String, String> headers;
    final Object payload;
    if (proxy != null) {
      final token = proxy.accessToken();
      if (token == null) throw const AiException('Sign in required');
      uri = proxy.url;
      headers = {
        'Content-Type': 'application/json',
        'apikey': proxy.publishableKey,
        'Authorization': 'Bearer $token',
      };
      payload = {'model': model, 'request': body};
    } else {
      uri = Uri.https(
        'generativelanguage.googleapis.com',
        '/v1beta/models/$model:generateContent',
      );
      headers = {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
      };
      payload = body;
    }
    try {
      return await _http
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(timeout);
    } on TimeoutException {
      throw const _SlowModel();
    } catch (e) {
      throw _NetworkFailure(e);
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

class _NetworkFailure implements Exception {
  const _NetworkFailure(this.error);
  final Object error;
}
