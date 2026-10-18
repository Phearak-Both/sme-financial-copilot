import 'dart:convert';

import '../../ai/copilot_service.dart';
import '../../core/date_only.dart';
import '../../core/money/currency.dart';
import '../../core/money/money.dart';
import '../../domain/entry_proposal.dart';
import '../../domain/enums.dart';
import '../../finance_core/ledger_math.dart';
import '../../finance_core/period_math.dart';
import 'ask_controller.dart';

/// JSON for saved chats. Money stays in integer minor units.
///
/// Returns null for messages that aren't kept (a pending reply).
String? encodeMessage(ChatMessage message) => switch (message) {
      UserMessage(:final text, :final image, :final isVoice) => jsonEncode({
          'kind': 'user',
          'text': ?text,
          if (image != null) 'image': base64Encode(image),
          if (isVoice) 'voice': true,
        }),
      AssistantMessage(:final reply, :final saved) => jsonEncode({
          'kind': 'assistant',
          if (saved) 'saved': true,
          'reply': _reply(reply),
        }),
      FailureMessage(:final failure) =>
        jsonEncode({'kind': 'failure', 'failure': failure.name}),
      PendingMessage() => null,
    };

/// Null if [data] can't be read, e.g. written by a newer version.
ChatMessage? decodeMessage(String data) {
  try {
    final json = jsonDecode(data) as Map<String, dynamic>;
    return switch (json['kind']) {
      'user' => UserMessage(
          text: json['text'] as String?,
          image: json['image'] == null
              ? null
              : base64Decode(json['image'] as String),
          isVoice: json['voice'] == true,
        ),
      'assistant' => AssistantMessage(
          _readReply(json['reply'] as Map<String, dynamic>),
          saved: json['saved'] == true,
        ),
      'failure' => FailureMessage(
          AskFailure.values.byName(json['failure'] as String),
        ),
      _ => null,
    };
  } catch (_) {
    return null;
  }
}

Map<String, dynamic> _reply(CopilotReply reply) => {
      'transcript': ?reply.transcript,
      ...switch (reply) {
        ProposalReply(:final proposal) => {
            'type': 'proposal',
            'proposal': _proposal(proposal),
          },
        AnswerReply(:final facts, :final explanation) => {
            'type': 'answer',
            'explanation': ?explanation,
            'facts': _facts(facts),
          },
        MessageReply(:final message) => {'type': 'message', 'message': message},
      },
    };

CopilotReply _readReply(Map<String, dynamic> json) {
  final transcript = json['transcript'] as String?;
  return switch (json['type']) {
    'proposal' => ProposalReply(
        _readProposal(json['proposal'] as Map<String, dynamic>),
        transcript: transcript,
      ),
    'answer' => AnswerReply(
        _readFacts(json['facts'] as Map<String, dynamic>),
        explanation: json['explanation'] as String?,
        transcript: transcript,
      ),
    _ => MessageReply(json['message'] as String, transcript: transcript),
  };
}

Map<String, dynamic> _proposal(EntryProposal p) => {
      'type': p.type.name,
      'source': p.source.name,
      'amount': ?p.amountText,
      'currency': ?p.currency?.code,
      if (p.occurredOn != null) 'date': toDateKey(p.occurredOn!),
      'category': ?p.categoryId,
      'description': p.description,
      'payment': ?p.paymentMethod?.name,
      'raw': ?p.rawInput,
    };

EntryProposal _readProposal(Map<String, dynamic> json) => EntryProposal(
      type: EntryType.values.byName(json['type'] as String),
      source: EntrySource.values.byName(json['source'] as String),
      amountText: json['amount'] as String?,
      currency: json['currency'] == null
          ? null
          : Currency.fromCode(json['currency'] as String),
      occurredOn:
          json['date'] == null ? null : fromDateKey(json['date'] as String),
      categoryId: json['category'] as String?,
      description: json['description'] as String? ?? '',
      paymentMethod: json['payment'] == null
          ? null
          : PaymentMethod.values.byName(json['payment'] as String),
      rawInput: json['raw'] as String?,
    );

Map<String, dynamic> _range(DateRange r) => {'from': r.startKey, 'to': r.endKey};

DateRange _readRange(Map<String, dynamic> json) => DateRange(
      fromDateKey(json['from'] as String),
      fromDateKey(json['to'] as String),
    );

Map<String, dynamic> _facts(QuestionFacts f) => {
      'topic': f.topic.name,
      'period': f.period.name,
      'range': _range(f.range),
      'summary': {
        'range': _range(f.summary.range),
        'totals': [
          for (final t in f.summary.byCurrency.values)
            {
              'currency': t.currency.code,
              'income': t.income.minor,
              'expense': t.expense.minor,
              'contribution': t.ownerContribution.minor,
              'withdrawal': t.ownerWithdrawal.minor,
              'count': t.entryCount,
            },
        ],
      },
      'topExpenses': {
        for (final MapEntry(key: c, value: list) in f.topExpenses.entries)
          c.code: [
            for (final e in list) {'category': e.key, 'amount': e.value.minor},
          ],
      },
      'cash': {
        for (final MapEntry(key: c, value: m) in f.cashBalances.entries)
          c.code: m.minor,
      },
    };

QuestionFacts _readFacts(Map<String, dynamic> json) {
  final summary = json['summary'] as Map<String, dynamic>;
  return QuestionFacts(
    topic: QuestionTopic.values.byName(json['topic'] as String),
    period: ReportPeriod.values.byName(json['period'] as String),
    range: _readRange(json['range'] as Map<String, dynamic>),
    summary: PeriodSummary(
      _readRange(summary['range'] as Map<String, dynamic>),
      {
        for (final t in (summary['totals'] as List).cast<Map<String, dynamic>>())
          Currency.fromCode(t['currency'] as String): _readTotals(t),
      },
    ),
    topExpenses: {
      for (final MapEntry(key: code, value: list)
          in (json['topExpenses'] as Map<String, dynamic>).entries)
        Currency.fromCode(code): [
          for (final e in (list as List).cast<Map<String, dynamic>>())
            MapEntry(
              e['category'] as String?,
              Money(e['amount'] as int, Currency.fromCode(code)),
            ),
        ],
    },
    cashBalances: {
      for (final MapEntry(key: code, value: minor)
          in (json['cash'] as Map<String, dynamic>).entries)
        Currency.fromCode(code): Money(minor as int, Currency.fromCode(code)),
    },
  );
}

CurrencyTotals _readTotals(Map<String, dynamic> t) {
  final c = Currency.fromCode(t['currency'] as String);
  return CurrencyTotals(
    currency: c,
    income: Money(t['income'] as int, c),
    expense: Money(t['expense'] as int, c),
    ownerContribution: Money(t['contribution'] as int, c),
    ownerWithdrawal: Money(t['withdrawal'] as int, c),
    entryCount: t['count'] as int,
  );
}
