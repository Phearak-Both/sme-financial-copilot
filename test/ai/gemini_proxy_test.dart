import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sme_financial_copilot/ai/gemini_client.dart';

http.Response _reply(Map<String, dynamic> json) => http.Response(
      jsonEncode({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': jsonEncode(json)},
              ],
            },
          },
        ],
      }),
      200,
    );

void main() {
  final url = Uri.parse('https://project.test/functions/v1/gemini');

  Future<Map<String, dynamic>> ask(GeminiClient client) => client.generateJson(
        systemInstruction: 'sys',
        parts: const [TextPart('hello')],
        schema: const {'type': 'OBJECT'},
      );

  test('sends the request through the proxy with the user token', () async {
    late http.Request sent;
    final client = GeminiClient(
      apiKey: '',
      proxy: GeminiProxy(
        url: url,
        publishableKey: 'pk',
        accessToken: () => 'user-token',
      ),
      httpClient: MockClient((request) async {
        sent = request;
        return _reply({'ok': true});
      }),
    );
    expect(client.isConfigured, isTrue);
    expect(await ask(client), {'ok': true});

    expect(sent.url, url);
    expect(sent.headers['Authorization'], 'Bearer user-token');
    expect(sent.headers['apikey'], 'pk');
    expect(sent.headers.containsKey('x-goog-api-key'), isFalse);
    final body = jsonDecode(sent.body) as Map<String, dynamic>;
    expect(body['model'], 'gemini-flash-lite-latest');
    expect(body['request']['contents'][0]['parts'][0]['text'], 'hello');
  });

  test('quota on the first model falls back through the proxy too', () async {
    final models = <String>[];
    final client = GeminiClient(
      apiKey: '',
      proxy: GeminiProxy(url: url, publishableKey: 'pk', accessToken: () => 't'),
      httpClient: MockClient((request) async {
        final model = (jsonDecode(request.body) as Map)['model'] as String;
        models.add(model);
        return models.length == 1
            ? http.Response('{}', 429)
            : _reply({'ok': model});
      }),
    );
    expect(await ask(client), {'ok': 'gemini-flash-latest'});
    expect(models, ['gemini-flash-lite-latest', 'gemini-flash-latest']);
  });

  test('signed out: no request is sent', () async {
    var calls = 0;
    final client = GeminiClient(
      apiKey: '',
      proxy: GeminiProxy(url: url, publishableKey: 'pk', accessToken: () => null),
      httpClient: MockClient((_) async {
        calls++;
        return _reply({});
      }),
    );
    await expectLater(ask(client), throwsA(isA<AiException>()));
    expect(calls, 0);
  });
}
