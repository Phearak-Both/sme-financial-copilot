import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sme_financial_copilot/data/cloud_store.dart';
import 'package:sme_financial_copilot/ai/copilot_service.dart';
import 'package:sme_financial_copilot/ai/gemini_client.dart';
import 'package:sme_financial_copilot/core/money/currency.dart';
import 'package:sme_financial_copilot/data/ledger_repository.dart';
import 'package:sme_financial_copilot/domain/entry_draft.dart';
import 'package:sme_financial_copilot/domain/enums.dart';

/// Wraps [json] the way the Gemini API returns structured output.
http.Response geminiReply(Map<String, dynamic> json) => http.Response.bytes(
  utf8.encode(
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
  ),
  200,
);

void main() {
  late MemoryCloudStore db;
  late LedgerRepository repo;
  final now = DateTime(2026, 10, 16, 9);

  setUp(() {
    db = MemoryCloudStore();
    repo = LedgerRepository(db, clock: () => now);
  });


  CopilotService service(List<Map<String, dynamic>> replies) {
    final queue = [...replies];
    final client = GeminiClient(
      apiKey: 'test',
      httpClient: MockClient((_) async => geminiReply(queue.removeAt(0))),
    );
    return CopilotService(client, repo, clock: () => now);
  }

  test('a spoken expense becomes a proposal, never a saved entry', () async {
    final copilot = service([
      {
        'intent': 'record',
        'language': 'km',
        'transcript': 'ទិញជី ៥០ ដុល្លារ',
        'entry': {
          'type': 'expense',
          'amount': '៥០',
          'currency': 'USD',
          'categoryId': 'farm_inputs',
          'description': 'ទិញជី',
          'date': '2026-10-15',
        },
      },
    ]);

    final reply = await copilot.handle(
      VoiceInput(Uint8List.fromList([0]), 'audio/wav'),
      categories: await repo.watchCategories().first,
      languageCode: 'km',
    );

    final proposal = (reply as ProposalReply).proposal;
    expect(proposal.amountText, '50');
    expect(proposal.currency, Currency.usd);
    expect(proposal.categoryId, 'farm_inputs');
    expect(proposal.source, EntrySource.voice);
    expect(proposal.occurredOn, DateTime(2026, 10, 15));
    expect(reply.transcript, 'ទិញជី ៥០ ដុល្លារ');
    expect(await repo.watchEntries(const LedgerFilter()).first, isEmpty);
  });

  test('drops unknown currency and future dates; wrong-kind category becomes other', () async {
    final copilot = service([
      {
        'intent': 'record',
        'language': 'en',
        'entry': {
          'type': 'income',
          'amount': '20',
          'currency': 'UNKNOWN',
          'categoryId': 'farm_inputs',
          'date': '2026-12-01',
        },
      },
    ]);

    final reply = await copilot.handle(
      const TextInput('sold rice 20'),
      categories: await repo.watchCategories().first,
      languageCode: 'en',
    );

    final proposal = (reply as ProposalReply).proposal;
    expect(proposal.currency, isNull);
    expect(proposal.categoryId, 'other_income');
    expect(proposal.occurredOn, isNull);
    expect(proposal.rawInput, 'sold rice 20');
  });

  test(
    'answers use app-calculated totals and reject invented numbers',
    () async {
      await repo.create(
        EntryDraft(
          type: EntryType.expense,
          amountMinor: 5000,
          currency: Currency.usd,
          occurredOn: DateTime(2026, 10, 10),
          categoryId: 'farm_inputs',
          categoryKind: CategoryKind.expense,
        ),
      );
      final categories = await repo.watchCategories().first;
      const question = {
        'intent': 'question',
        'language': 'en',
        'question': {'topic': 'summary', 'period': 'thisMonth'},
      };

      final grounded =
          await service([
            question,
            {'answer': 'You spent \$50.00 this month, from 1 record.'},
          ]).handle(
            const TextInput('spent?'),
            categories: categories,
            languageCode: 'en',
          );
      final answer = grounded as AnswerReply;
      expect(
        answer.facts.summary.byCurrency[Currency.usd]!.expense.minor,
        5000,
      );
      expect(answer.explanation, contains('50.00'));

      final invented =
          await service([
            question,
            {'answer': 'You spent \$75 this month.'},
          ]).handle(
            const TextInput('spent?'),
            categories: categories,
            languageCode: 'en',
          );
      expect((invented as AnswerReply).explanation, isNull);
    },
  );

  test('Gemini listens to a voice message and reads a receipt', () async {
    final bodies = <String>[];
    final copilot = CopilotService(
      GeminiClient(
        apiKey: 'test',
        httpClient: MockClient((request) async {
          bodies.add(request.body);
          return geminiReply({
            'intent': 'record',
            'language': 'km',
            'transcript': 'ហាងលក់ជី សរុប 50,000 ៛',
            'entry': {'type': 'expense', 'amount': '50000', 'currency': 'KHR'},
          });
        }),
      ),
      repo,
      clock: () => now,
    );
    final categories = await repo.watchCategories().first;

    final voice = await copilot.handle(
      VoiceInput(Uint8List.fromList([1, 2, 3]), 'audio/wav'),
      categories: categories,
      languageCode: 'km',
    );
    final photo = await copilot.handle(
      PhotoInput(Uint8List.fromList([1, 2]), 'image/jpeg'),
      categories: categories,
      languageCode: 'km',
    );

    expect((voice as ProposalReply).proposal.source, EntrySource.voice);
    final proposal = (photo as ProposalReply).proposal;
    expect(proposal.source, EntrySource.receipt);
    expect(proposal.rawInput, 'ហាងលក់ជី សរុប 50,000 ៛');
    expect(bodies, everyElement(contains('inlineData')));
  });

  test('switches to the next model when one runs out of free quota', () async {
    final asked = <String>[];
    final client = GeminiClient(
      apiKey: 'test',
      model: 'a',
      fallbackModels: const ['b', 'c'],
      httpClient: MockClient((request) async {
        final model = request.url.path.split('/').last.split(':').first;
        asked.add(model);
        return model == 'a'
            ? http.Response('quota', 429)
            : geminiReply({'ok': true});
      }),
    );
    Future<void> ask() => client.generateJson(
      systemInstruction: '',
      parts: const [TextPart('hi')],
      schema: const {},
    );

    await ask();
    await ask();
    expect(asked, ['a', 'b', 'b']);
  });

  test('transcribes a recording into the text box', () async {
    final copilot = CopilotService(
      GeminiClient(
        apiKey: 'test',
        httpClient: MockClient(
          (_) async => geminiReply({'transcript': 'ទិញ ជី ប្រាំ ម៉ឺន រៀល'}),
        ),
      ),
      repo,
    );
    expect(
      await copilot.transcribe(Uint8List.fromList([1]), 'audio/wav'),
      'ទិញ ជី ប្រាំ ម៉ឺន រៀល',
    );
  });

  test('a sent transcript is recorded as a voice entry', () async {
    final reply =
        await service([
          {
            'intent': 'record',
            'language': 'km',
            'entry': {'type': 'expense', 'amount': '10', 'currency': 'USD'},
          },
        ]).handle(
          const TextInput('ទិញ សាំង ដប់ ដុល្លារ', source: EntrySource.voice),
          categories: await repo.watchCategories().first,
          languageCode: 'km',
        );
    expect((reply as ProposalReply).proposal.source, EntrySource.voice);
    expect(reply.transcript, isNull);
  });

  test('tries the next model when one is too slow', () async {
    final client = GeminiClient(
      apiKey: 'test',
      model: 'slow',
      fallbackModels: const ['fast'],
      modelTimeout: const Duration(milliseconds: 50),
      httpClient: MockClient((request) async {
        if (request.url.path.contains('slow')) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
        return geminiReply({'model': request.url.pathSegments.last});
      }),
    );
    final result = await client.generateJson(
      systemInstruction: '',
      parts: const [TextPart('hi')],
      schema: const {},
    );
    expect(result['model'], 'fast:generateContent');
  });

  test('tries the next model when one is overloaded, this time only',
      () async {
    final asked = <String>[];
    var overloaded = true;
    final client = GeminiClient(
      apiKey: 'test',
      model: 'a',
      fallbackModels: const ['b'],
      httpClient: MockClient((request) async {
        final model = request.url.path.split('/').last.split(':').first;
        asked.add(model);
        return model == 'a' && overloaded
            ? http.Response('high demand', 503)
            : geminiReply({'ok': true});
      }),
    );
    Future<void> ask() => client.generateJson(
      systemInstruction: '',
      parts: const [TextPart('hi')],
      schema: const {},
    );

    await ask();
    overloaded = false;
    await ask();
    expect(asked, ['a', 'b', 'a']);
  });

  test('transcribing asks Gemini for minimal thinking', () async {
    final bodies = <Map<String, dynamic>>[];
    final copilot = CopilotService(
      GeminiClient(
        apiKey: 'test',
        httpClient: MockClient((request) async {
          bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
          return geminiReply({'transcript': 'hi'});
        }),
      ),
      repo,
    );
    await copilot.transcribe(Uint8List.fromList([1]), 'audio/wav');
    expect(
      bodies.single['generationConfig']['thinkingConfig']['thinkingLevel'],
      'minimal',
    );
  });

  test('asks the next model too when one is slow; the first answer wins',
      () async {
    final asked = <String>[];
    final client = GeminiClient(
      apiKey: 'test',
      model: 'slow',
      fallbackModels: const ['quick'],
      hedgeDelay: const Duration(milliseconds: 50),
      httpClient: MockClient((request) async {
        final model = request.url.path.split('/').last.split(':').first;
        asked.add(model);
        if (model == 'slow') {
          await Future<void>.delayed(const Duration(milliseconds: 400));
        }
        return geminiReply({'model': model});
      }),
    );
    final watch = Stopwatch()..start();
    final result = await client.generateJson(
      systemInstruction: '',
      parts: const [TextPart('hi')],
      schema: const {},
    );
    expect(result['model'], 'quick');
    expect(asked, ['slow', 'quick']);
    expect(watch.elapsedMilliseconds, lessThan(400));
  });

  test('tries every model once more after a pause when all are busy',
      () async {
    var calls = 0;
    final client = GeminiClient(
      apiKey: 'test',
      model: 'a',
      fallbackModels: const ['b'],
      retryDelay: Duration.zero,
      httpClient: MockClient((_) async {
        calls++;
        return calls <= 2
            ? http.Response('high demand', 503)
            : geminiReply({'ok': true});
      }),
    );
    final result = await client.generateJson(
      systemInstruction: '',
      parts: const [TextPart('hi')],
      schema: const {},
    );
    expect(result['ok'], isTrue);
    expect(calls, 3);
  });

  test('says the assistant is busy when every model stays busy', () async {
    final client = GeminiClient(
      apiKey: 'test',
      model: 'a',
      fallbackModels: const ['b'],
      retryDelay: Duration.zero,
      httpClient: MockClient((_) async => http.Response('high demand', 503)),
    );
    await expectLater(
      client.generateJson(
        systemInstruction: '',
        parts: const [TextPart('hi')],
        schema: const {},
      ),
      throwsA(isA<AiException>().having((e) => e.isBusy, 'isBusy', isTrue)),
    );
  });

  test('tries the next model when the connection drops', () async {
    final client = GeminiClient(
      apiKey: 'test',
      model: 'a',
      fallbackModels: const ['b'],
      httpClient: MockClient((request) async {
        if (request.url.path.contains('/a:')) {
          throw http.ClientException('Connection terminated during handshake');
        }
        return geminiReply({'ok': true});
      }),
    );
    final result = await client.generateJson(
      systemInstruction: '',
      parts: const [TextPart('hi')],
      schema: const {},
    );
    expect(result['ok'], isTrue);
  });

  test('asks again at low thinking when a model has no minimal level',
      () async {
    final levels = <String>[];
    final client = GeminiClient(
      apiKey: 'test',
      httpClient: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final level =
            body['generationConfig']['thinkingConfig']['thinkingLevel'];
        levels.add(level as String);
        return level == 'minimal'
            ? http.Response(
                'Thinking level MINIMAL is not supported for this model.',
                400,
              )
            : geminiReply({'ok': true});
      }),
    );
    final result = await client.generateJson(
      systemInstruction: '',
      parts: const [TextPart('hi')],
      schema: const {},
      thinkingLevel: 'minimal',
    );
    expect(result['ok'], isTrue);
    expect(levels, ['minimal', 'low']);
  });

  group('scope', () {
    test('off-topic requests get the fixed refusal, not model text', () async {
      for (final (lang, refusal) in [
        ('km', 'សុំទោស ខ្ញុំអាចជួយបានតែលើហិរញ្ញវត្ថុអាជីវកម្មរបស់អ្នកប៉ុណ្ណោះ។'),
        ('en', 'Sorry, I can only help with your business finances.'),
      ]) {
        final reply = await service([
          {
            'intent': 'outOfScope',
            'language': lang,
            'reply': 'Sure! Here is your essay...',
          },
        ]).handle(
          const TextInput('write my homework essay'),
          categories: await repo.watchCategories().first,
          languageCode: lang,
        );
        expect((reply as MessageReply).message, refusal);
        expect(reply.declined, isNull);
      }
    });

    test('a mixed message keeps the allowed part and declines the rest',
        () async {
      final reply = await service([
        {
          'intent': 'record',
          'language': 'en',
          'alsoOutOfScope': true,
          'entry': {'type': 'income', 'amount': '20', 'currency': 'USD'},
        },
      ]).handle(
        const TextInput('sold rice 20 dollars, and who won the football?'),
        categories: await repo.watchCategories().first,
        languageCode: 'en',
      );
      expect((reply as ProposalReply).proposal.amountText, '20');
      expect(reply.declined,
          'Sorry, I can only help with your business finances.');
    });

    test('the prompt carries the scope rules and business details', () async {
      String? prompt;
      final client = GeminiClient(
        apiKey: 'test',
        httpClient: MockClient((request) async {
          prompt = request.body;
          return geminiReply({'intent': 'other', 'language': 'en', 'reply': 'Hi!'});
        }),
      );
      await CopilotService(client, repo, clock: () => now).handle(
        const TextInput('hello'),
        categories: await repo.watchCategories().first,
        languageCode: 'en',
        businessName: 'Sokha Shop',
        defaultCurrency: Currency.khr,
      );
      expect(prompt, contains('Business name: Sokha Shop'));
      expect(prompt, contains('Default currency: KHR'));
      expect(prompt, contains('Current date: 2026-10-16'));
      expect(prompt, contains('Scope enforcement'));
    });
  });
}
