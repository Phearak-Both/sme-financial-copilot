import 'package:flutter/foundation.dart';

import '../core/date_only.dart';
import '../core/money/currency.dart';
import '../core/money/money.dart';
import '../core/money/money_parser.dart';
import '../data/database.dart';
import '../data/ledger_repository.dart';
import '../domain/entry_proposal.dart';
import '../domain/enums.dart';
import '../finance_core/ledger_math.dart';
import '../finance_core/period_math.dart';
import 'gemini_client.dart';
import 'ocr_client.dart';
import 'whisper_client.dart';

/// What the user gave the assistant.
sealed class CopilotInput {
  const CopilotInput();
}

class TextInput extends CopilotInput {
  const TextInput(this.text, {this.source = EntrySource.text});
  final String text;

  /// [EntrySource.voice] when the text is a transcript the user checked.
  final EntrySource source;
}

class VoiceInput extends CopilotInput {
  const VoiceInput(this.bytes, this.mimeType);
  final Uint8List bytes;
  final String mimeType;
}

class PhotoInput extends CopilotInput {
  const PhotoInput(this.bytes, this.mimeType, {this.caption});
  final Uint8List bytes;
  final String mimeType;
  final String? caption;
}

/// The assistant's reply. [transcript] is what it heard or read, when the
/// input was voice or a photo.
sealed class CopilotReply {
  const CopilotReply({this.transcript});
  final String? transcript;
}

class ProposalReply extends CopilotReply {
  const ProposalReply(this.proposal, {super.transcript});
  final EntryProposal proposal;
}

class AnswerReply extends CopilotReply {
  const AnswerReply(this.facts, {this.explanation, super.transcript});

  /// Calculated by the app. Shown as-is; the model never changes these.
  final QuestionFacts facts;

  /// The model's wording, or null if it failed the number check.
  final String? explanation;
}

class MessageReply extends CopilotReply {
  const MessageReply(this.message, {super.transcript});
  final String message;
}

enum QuestionTopic { summary, expenseCategories, cashBalance }

/// Deterministic figures that answer a question, from `finance_core`.
class QuestionFacts {
  const QuestionFacts({
    required this.topic,
    required this.period,
    required this.range,
    required this.summary,
    required this.topExpenses,
    required this.cashBalances,
  });

  final QuestionTopic topic;
  final ReportPeriod period;
  final DateRange range;
  final PeriodSummary summary;
  final Map<Currency, List<MapEntry<String?, Money>>> topExpenses;

  /// Empty when no opening balance is set.
  final Map<Currency, Money> cashBalances;

  int get entryCount => summary.entryCount;
}

/// Turns typed text, speech or a receipt photo into either a proposed entry
/// or a grounded answer about the ledger.
class CopilotService {
  CopilotService(
    this._client,
    this._repo, {
    this._whisper,
    this._ocr,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final GeminiClient _client;
  final LedgerRepository _repo;
  final WhisperClient? _whisper;
  final OcrClient? _ocr;
  final DateTime Function() _clock;

  bool get isConfigured => _client.isConfigured;

  /// Whether live previews can be shown while recording.
  bool get canTranscribeLive => _whisper?.isConfigured ?? false;

  /// A quick preview of what's been said so far, or null if it isn't
  /// available. Whisper only: previews would use up the Gemini quota.
  Future<String?> transcribeLive(
    Uint8List wav, {
    String languageCode = 'km',
  }) async {
    final whisper = _whisper;
    if (whisper == null || !whisper.isConfigured) return null;
    try {
      return await whisper.transcribe(
        wav,
        'audio/wav',
        live: true,
        languageCode: languageCode,
      );
    } on WhisperException {
      return null;
    }
  }

  /// Turns a voice recording into text for the user to check before
  /// sending, in the app's language ([languageCode] `km` or `en`). Uses the
  /// Whisper service, or Gemini if it's unavailable.
  Future<String> transcribe(
    Uint8List audio,
    String mimeType, {
    String languageCode = 'km',
  }) async {
    final whisper = _whisper;
    if (whisper != null && whisper.isConfigured) {
      try {
        return await whisper.transcribe(
          audio,
          mimeType,
          languageCode: languageCode,
        );
      } on WhisperException {
        // Fall through to Gemini.
      }
    }
    final result = await _client.generateJson(
      systemInstruction: languageCode == 'en'
          ? 'Transcribe the voice message exactly as spoken, in English. '
                'Write amounts as digits. Output only the transcript.'
          : 'Transcribe the voice message exactly as spoken, in Khmer '
                'script. Write numbers the way they were said. Output only '
                'the transcript.',
      parts: [BytesPart(audio, mimeType)],
      schema: const {
        'type': 'OBJECT',
        'properties': {
          'transcript': {'type': 'STRING'},
        },
        'required': ['transcript'],
      },
    );
    return _nonEmpty(result['transcript']) ?? '';
  }

  Future<CopilotReply> handle(
    CopilotInput input, {
    required List<CategoryRow> categories,
    required String languageCode,
  }) async {
    final today = dateOnly(_clock());

    // Voice goes to the Khmer Whisper model when it's configured, and the
    // transcript is read as text. If the service can't be reached, Gemini
    // listens to the audio instead so recording still works.
    String? heard;
    final whisper = _whisper;
    if (input is VoiceInput && whisper != null && whisper.isConfigured) {
      try {
        heard = await whisper.transcribe(input.bytes, input.mimeType);
      } on WhisperException {
        heard = null;
      }
      if (heard != null && heard.isEmpty) {
        return MessageReply(
          languageCode == 'en'
              ? "I couldn't hear anything. Please try again."
              : 'ខ្ញុំមិនឮអ្វីទេ។ សូមព្យាយាមម្តងទៀត។',
        );
      }
    }

    // Photos are read by Tesseract OCR when the service is configured.
    // Gemini then gets both the OCR text and the image, to check one
    // against the other.
    String? ocrText;
    final ocr = _ocr;
    if (input is PhotoInput && ocr != null && ocr.isConfigured) {
      try {
        debugPrint('[ai] OCR on ${input.bytes.length} bytes');
        ocrText = _nonEmpty(await ocr.detectText(input.bytes));
        debugPrint('[ai] OCR read ${ocrText?.length ?? 0} chars');
      } on OcrException catch (e) {
        debugPrint('[ai] OCR failed: $e');
        ocrText = null;
      }
    }

    final result = await _client.generateJson(
      systemInstruction: _interpretPrompt(categories, today, languageCode),
      parts: switch (input) {
        _ when heard != null => [
          TextPart(
            'Transcript of the user\'s voice message from a Khmer '
            'speech recognizer:\n$heard',
          ),
        ],
        PhotoInput(:final bytes, :final mimeType, :final caption)
            when ocrText != null =>
          [
            TextPart(
              'The user photographed this, most likely a receipt or invoice. '
              'Text read from it by OCR (mostly right, but it can misread '
              'symbols, e.g. ៛ as ៖, or digits; check against the image, and '
              'use the image for layout, e.g. which number is the total):\n'
              '$ocrText',
            ),
            BytesPart(bytes, mimeType),
            if (caption != null && caption.isNotEmpty) TextPart(caption),
          ],
        _ => _parts(input),
      },
      schema: _interpretSchema,
    );

    final transcript =
        heard ??
        switch (input) {
          TextInput() => null,
          _ => _nonEmpty(result['transcript']),
        };
    final language = result['language'] == 'en' ? 'en' : 'km';

    switch (result['intent']) {
      case 'record':
        final proposal = _toProposal(
          result['entry'],
          input: input,
          transcript: transcript,
          ocrText: ocrText,
          categories: categories,
          today: today,
        );
        if (proposal != null) {
          return ProposalReply(proposal, transcript: transcript);
        }
      case 'question':
        return _answer(result['question'], language, transcript);
    }
    return MessageReply(
      _nonEmpty(result['reply']) ??
          (language == 'en'
              ? 'Sorry, I didn\'t understand. Try "Sold rice 20 dollars" or "How much did I spend this month?"'
              : 'សូមទោស ខ្ញុំមិនយល់ទេ។ សាកល្បង «លក់អង្ករ ២០ ដុល្លារ» ឬ «ខែនេះខ្ញុំចំណាយប៉ុន្មាន?»'),
      transcript: transcript,
    );
  }

  List<AiPart> _parts(CopilotInput input) => switch (input) {
    TextInput(:final text) => [TextPart(text)],
    VoiceInput(:final bytes, :final mimeType) => [
      const TextPart('The user recorded this voice message.'),
      BytesPart(bytes, mimeType),
    ],
    PhotoInput(:final bytes, :final mimeType, :final caption) => [
      const TextPart(
        'The user photographed this, most likely a receipt or invoice.',
      ),
      BytesPart(bytes, mimeType),
      if (caption != null && caption.isNotEmpty) TextPart(caption),
    ],
  };

  EntryProposal? _toProposal(
    Object? raw, {
    required CopilotInput input,
    required String? transcript,
    required List<CategoryRow> categories,
    required DateTime today,
    String? ocrText,
  }) {
    if (raw is! Map) return null;
    final type =
        EntryType.values.where((t) => t.name == raw['type']).firstOrNull ??
        EntryType.expense;
    final currency = Currency.values
        .where((c) => c.code == raw['currency'])
        .firstOrNull;

    // Keep the amount only if the app's own parser accepts it.
    final amountText = _nonEmpty(raw['amount']);
    final amountOk =
        amountText != null &&
        parseAmount(amountText, currency ?? Currency.usd).isOk;

    // When nothing fits, fall back to the "other" category of the right
    // kind, so the entry can be saved straight from the chat.
    final ofKind = categories.where((c) => c.kind == type.categoryKind);
    final category =
        ofKind.where((c) => c.id == raw['categoryId']).firstOrNull ??
        ofKind.where((c) => c.id.startsWith('other_')).firstOrNull ??
        ofKind.firstOrNull;

    DateTime? date;
    final dateText = _nonEmpty(raw['date']);
    if (dateText != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateText)) {
      final parsed = fromDateKey(dateText);
      if (!parsed.isAfter(today)) date = parsed;
    }

    return EntryProposal(
      type: type,
      source: switch (input) {
        TextInput(:final source) => source,
        VoiceInput() => EntrySource.voice,
        PhotoInput() => EntrySource.receipt,
      },
      amountText: amountOk ? normalizeDigits(amountText) : null,
      currency: currency,
      occurredOn: date,
      categoryId: category?.id,
      description: _nonEmpty(raw['description']) ?? '',
      paymentMethod: PaymentMethod.values
          .where((m) => m.name == raw['paymentMethod'])
          .firstOrNull,
      rawInput: switch (input) {
        TextInput(:final text) => text,
        // Keep the receipt's text with the entry, without flooding the note.
        PhotoInput() when ocrText != null =>
          ocrText.length > 500 ? '${ocrText.substring(0, 500)}…' : ocrText,
        _ => transcript,
      },
    );
  }

  Future<CopilotReply> _answer(
    Object? raw,
    String language,
    String? transcript,
  ) async {
    final map = raw is Map ? raw : const {};
    final topic =
        QuestionTopic.values.where((t) => t.name == map['topic']).firstOrNull ??
        QuestionTopic.summary;
    final period =
        ReportPeriod.values.where((p) => p.name == map['period']).firstOrNull ??
        ReportPeriod.thisMonth;

    final facts = await _facts(topic, period);
    String? explanation;
    try {
      final phrased = await _client.generateJson(
        systemInstruction: _answerPrompt(language),
        parts: [
          TextPart(
            'Question: ${transcript ?? map['text'] ?? ''}\n'
            'FACTS:\n${_factsText(facts)}',
          ),
        ],
        schema: const {
          'type': 'OBJECT',
          'properties': {
            'answer': {'type': 'STRING'},
          },
          'required': ['answer'],
        },
      );
      final answer = _nonEmpty(phrased['answer']);
      if (answer != null && numbersAreGrounded(answer, facts)) {
        explanation = answer;
      }
    } on AiException {
      // The facts card still answers the question without the wording.
    }
    return AnswerReply(facts, explanation: explanation, transcript: transcript);
  }

  Future<QuestionFacts> _facts(QuestionTopic topic, ReportPeriod period) async {
    final today = _clock();
    final range = rangeFor(period, today);
    final entries = await _repo.watchLedgerEntries(range).first;

    var balances = const <Currency, Money>{};
    if (topic == QuestionTopic.cashBalance) {
      final openings = await _repo.watchOpeningBalances().first;
      if (openings.isNotEmpty) {
        final earliest = openings
            .map((o) => o.asOf)
            .reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
        final since = await _repo
            .watchLedgerEntries(
              DateRange(fromDateKey(earliest), addDays(dateOnly(today), 1)),
            )
            .first;
        balances = cashBalances(openings, since);
      }
    }

    return QuestionFacts(
      topic: topic,
      period: period,
      range: range,
      summary: summarize(entries, range),
      topExpenses: {
        for (final MapEntry(key: currency, value: list) in expensesByCategory(
          entries,
          range,
        ).entries)
          currency: list.take(3).toList(),
      },
      cashBalances: balances,
    );
  }

  String _factsText(QuestionFacts facts) {
    final buffer = StringBuffer()
      ..writeln(
        'period: ${facts.period.name} '
        '(${toDateKey(facts.range.start)} to before '
        '${toDateKey(facts.range.end)})',
      )
      ..writeln('records: ${facts.entryCount}');
    if (facts.summary.isEmpty) buffer.writeln('No records in this period.');
    for (final t in facts.summary.byCurrency.values) {
      final c = t.currency.code;
      buffer
        ..writeln('$c money in: ${_major(t.income)}')
        ..writeln('$c money out: ${_major(t.expense)}')
        ..writeln('$c profit (cash): ${_major(t.profit)}');
    }
    for (final MapEntry(key: currency, value: list)
        in facts.topExpenses.entries) {
      for (final e in list) {
        buffer.writeln(
          '${currency.code} top expense category '
          '${e.key ?? 'uncategorized'}: ${_major(e.value)}',
        );
      }
    }
    if (facts.topic == QuestionTopic.cashBalance) {
      if (facts.cashBalances.isEmpty) {
        buffer.writeln('Cash on hand unknown: no opening balance set.');
      }
      for (final MapEntry(key: currency, value: money)
          in facts.cashBalances.entries) {
        buffer.writeln('${currency.code} cash on hand now: ${_major(money)}');
      }
    }
    return buffer.toString();
  }

  static String? _nonEmpty(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
}

String _major(Money money) =>
    (money.isNegative ? '-' : '') +
    minorToInputString(money.minor.abs(), money.currency);

/// Strips grouping and trailing decimal zeros so "1,250.00" equals "1250".
String _canonicalNumber(String number) {
  var n = number.replaceAll(',', '');
  if (n.contains('.')) {
    n = n.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return n;
}

/// True when every number in [answer] comes from [facts], so the model can't
/// introduce figures of its own. Small counts (like "top 3") are allowed.
bool numbersAreGrounded(String answer, QuestionFacts facts) {
  final allowed = <String>{
    facts.entryCount.toString(),
    for (final t in facts.summary.byCurrency.values) ...[
      _major(t.income),
      _major(t.expense),
      _major(t.profit),
      _major(t.profit).replaceFirst('-', ''),
      t.entryCount.toString(),
    ],
    for (final list in facts.topExpenses.values)
      for (final e in list) _major(e.value),
    for (final money in facts.cashBalances.values) ...[
      _major(money),
      _major(money).replaceFirst('-', ''),
    ],
    for (final d in [facts.range.start, addDays(facts.range.end, -1)]) ...[
      d.year.toString(),
      d.month.toString(),
      d.day.toString(),
    ],
  }.map(_canonicalNumber).toSet();

  final numbers = RegExp(r'\d[\d,]*(?:\.\d+)?')
      .allMatches(normalizeDigits(answer))
      .map((m) => _canonicalNumber(m.group(0)!));
  return numbers.every(
    (n) => allowed.contains(n) || (int.tryParse(n) ?? 99) <= 10,
  );
}

String _interpretPrompt(
  List<CategoryRow> categories,
  DateTime today,
  String languageCode,
) =>
    '''
You are the assistant inside a bookkeeping app for small businesses in Cambodia.
Users write or speak Khmer or English, often mixed. Today is ${toDateKey(today)}.
The app's interface language is ${languageCode == 'en' ? 'English' : 'Khmer'}.

Decide what the user wants:
- "record": they describe money that came in or went out (a sale, a purchase, a bill, a receipt photo).
- "question": they ask about their figures (totals, spending, profit, top expenses, cash on hand).
- "other": anything else, or too unclear. Put a short helpful reply in "reply".

Always set "language" to the language the user used ("km" or "en"); reply in that language.
For voice or photo input, put what you heard or the key text you read in "transcript" (keep it short).

Speech-recognizer transcripts are split into words with spaces and contain typical mistakes. Read them by sound:
"រាល"/"រា" next to an amount means រៀល (riel); "ព័ន្ធ"/"ពន្ធ" after a number means ពាន់ (thousand);
"មឿន"/"ម៉ឿន" means ម៉ឺន; "ដ៏" before a number word usually means ដប់ (ten); "ដុល ឡារ"/"រឡា" means ដុល្លារ.
When spelled-out number words and digits disagree, trust the number words.

For "record", fill "entry":
- type: income (sales, money received), expense (business purchases and bills), ownerContribution (owner puts personal money in), ownerWithdrawal (owner takes money for personal use).
- amount: the amount in major units as plain ASCII digits with "." for decimals, no separators or symbols.
  Convert Khmer digits (០-៩) and Khmer number words: ពាន់ = 1,000, ម៉ឺន = 10,000, សែន = 100,000, លាន = 1,000,000.
  The amount stated is the total. Quantities like "3 bags" (បីបាវ) are not multipliers; only multiply if the user says a price per item (e.g. ក្នុងមួយ, "each").
  For a receipt use the final total actually paid. Leave empty if no amount is given.
- currency: USD for dollars/ដុល្លារ/\$; KHR for riel/រៀល/៛. If not stated, use UNKNOWN. Never guess.
- date: YYYY-MM-DD only if a date is stated or printed (resolve "yesterday"/"ម្សិលមិញ"); otherwise empty.
- description: a few words describing it, in the user's language.
- categoryId: the best matching id from this list for the entry's kind, or empty if none fits:
${categories.map((c) => '  ${c.id} | ${c.kind.name} | ${c.nameEn} | ${c.nameKm}').join('\n')}
- paymentMethod: cash, bank, mobileWallet (ABA, Wing, KHQR, etc.), other, or empty if unknown.

For "question", fill "question":
- topic: summary (money in/out, profit), expenseCategories (where money went), or cashBalance (cash on hand).
- period: thisMonth, lastMonth, last3Months or thisYear (default thisMonth).
- text: the question restated briefly.
''';

String _answerPrompt(String language) =>
    '''
You answer a small-business owner's question using ONLY the FACTS given.
Reply in ${language == 'en' ? 'English' : 'Khmer'}, in 1 to 3 short, plain sentences.
Rules:
- Use only numbers that appear in FACTS. Do not calculate new numbers.
- Never add KHR and USD together; give each currency separately.
- If there are no records, say so plainly and suggest recording some.
- Category ids in FACTS are internal; describe them in words (e.g. "rent").
- Write numbers with ASCII digits.
''';

const _interpretSchema = {
  'type': 'OBJECT',
  'properties': {
    'intent': {
      'type': 'STRING',
      'enum': ['record', 'question', 'other'],
    },
    'language': {
      'type': 'STRING',
      'enum': ['km', 'en'],
    },
    'transcript': {'type': 'STRING'},
    'reply': {'type': 'STRING'},
    'entry': {
      'type': 'OBJECT',
      'properties': {
        'type': {
          'type': 'STRING',
          'enum': ['income', 'expense', 'ownerContribution', 'ownerWithdrawal'],
        },
        'amount': {'type': 'STRING'},
        'currency': {
          'type': 'STRING',
          'enum': ['USD', 'KHR', 'UNKNOWN'],
        },
        'date': {'type': 'STRING'},
        'description': {'type': 'STRING'},
        'categoryId': {'type': 'STRING'},
        'paymentMethod': {'type': 'STRING'},
      },
      'required': ['type', 'amount', 'currency'],
    },
    'question': {
      'type': 'OBJECT',
      'properties': {
        'topic': {
          'type': 'STRING',
          'enum': ['summary', 'expenseCategories', 'cashBalance'],
        },
        'period': {
          'type': 'STRING',
          'enum': ['thisMonth', 'lastMonth', 'last3Months', 'thisYear'],
        },
        'text': {'type': 'STRING'},
      },
      'required': ['topic', 'period'],
    },
  },
  'required': ['intent', 'language'],
};
