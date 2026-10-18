import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sme_financial_copilot/ai/copilot_service.dart';
import 'package:sme_financial_copilot/core/date_only.dart';
import 'package:sme_financial_copilot/core/money/currency.dart';
import 'package:sme_financial_copilot/core/money/money.dart';
import 'package:sme_financial_copilot/data/chat_repository.dart';
import 'package:sme_financial_copilot/data/database.dart';
import 'package:sme_financial_copilot/domain/entry_proposal.dart';
import 'package:sme_financial_copilot/domain/enums.dart';
import 'package:sme_financial_copilot/features/ask/ask_controller.dart';
import 'package:sme_financial_copilot/features/ask/chat_codec.dart';
import 'package:sme_financial_copilot/finance_core/ledger_math.dart';
import 'package:sme_financial_copilot/finance_core/period_math.dart';

T roundTrip<T extends ChatMessage>(ChatMessage message) =>
    decodeMessage(encodeMessage(message)!)! as T;

void main() {
  group('codec', () {
    test('user message with photo and voice flag', () {
      final m = roundTrip<UserMessage>(UserMessage(
        text: 'ទិញជី',
        image: Uint8List.fromList([1, 2, 3]),
        isVoice: true,
      ));
      expect(m.text, 'ទិញជី');
      expect(m.image, [1, 2, 3]);
      expect(m.isVoice, isTrue);
    });

    test('proposal keeps every field and the saved flag', () {
      final m = roundTrip<AssistantMessage>(AssistantMessage(
        ProposalReply(
          EntryProposal(
            type: EntryType.expense,
            source: EntrySource.receipt,
            amountText: '12.50',
            currency: Currency.usd,
            occurredOn: DateTime(2026, 10, 3),
            categoryId: 'stock',
            description: 'Rice',
            paymentMethod: PaymentMethod.cash,
            rawInput: 'receipt text',
          ),
          transcript: 'receipt text',
        ),
        saved: true,
      ));
      expect(m.saved, isTrue);
      expect(m.reply.transcript, 'receipt text');
      final p = (m.reply as ProposalReply).proposal;
      expect(p.type, EntryType.expense);
      expect(p.source, EntrySource.receipt);
      expect(p.amountText, '12.50');
      expect(p.currency, Currency.usd);
      expect(p.occurredOn, DateTime(2026, 10, 3));
      expect(p.categoryId, 'stock');
      expect(p.description, 'Rice');
      expect(p.paymentMethod, PaymentMethod.cash);
    });

    test('answer facts survive with exact money', () {
      final range = DateRange(DateTime(2026, 10), DateTime(2026, 11));
      final usd = Currency.usd;
      final m = roundTrip<AssistantMessage>(AssistantMessage(AnswerReply(
        QuestionFacts(
          topic: QuestionTopic.expenseCategories,
          period: ReportPeriod.thisMonth,
          range: range,
          summary: PeriodSummary(range, {
            usd: CurrencyTotals(
              currency: usd,
              income: Money(1000, usd),
              expense: Money(250, usd),
              ownerContribution: Money(0, usd),
              ownerWithdrawal: Money(50, usd),
              entryCount: 3,
            ),
          }),
          topExpenses: {
            usd: [MapEntry('stock', Money(200, usd)), MapEntry(null, Money(50, usd))],
          },
          cashBalances: {Currency.khr: Money(40000, Currency.khr)},
        ),
        explanation: 'ok',
      )));
      final a = m.reply as AnswerReply;
      expect(a.explanation, 'ok');
      expect(a.facts.topic, QuestionTopic.expenseCategories);
      expect(a.facts.range, range);
      expect(a.facts.summary.byCurrency[usd]!.profit, Money(750, usd));
      expect(a.facts.entryCount, 3);
      expect(a.facts.topExpenses[usd]!.last.key, isNull);
      expect(a.facts.cashBalances[Currency.khr], Money(40000, Currency.khr));
    });

    test('pending replies are not saved; bad data is skipped', () {
      expect(encodeMessage(const PendingMessage()), isNull);
      expect(decodeMessage('not json'), isNull);
      expect(
        roundTrip<FailureMessage>(const FailureMessage(AskFailure.quota)).failure,
        AskFailure.quota,
      );
    });
  });

  group('repository', () {
    late AppDatabase db;
    late ChatRepository repo;
    var now = DateTime(2026, 10, 18, 9);

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = ChatRepository(db, clock: () => now);
    });

    tearDown(() => db.close());

    test('create, update, list newest first and delete', () async {
      final a = await repo.create('first', ['a1', 'a2']);
      now = now.add(const Duration(minutes: 1));
      final b = await repo.create('second', ['b1']);
      expect((await repo.watchChats().first).map((c) => c.title),
          ['second', 'first']);

      now = now.add(const Duration(minutes: 1));
      await repo.update(a, ['a1', 'a2', 'a3']);
      expect(await repo.loadMessages(a), ['a1', 'a2', 'a3']);
      expect((await repo.watchChats().first).first.id, a);

      await repo.delete(a);
      expect((await repo.watchChats().first).map((c) => c.id), [b]);
      expect(await repo.loadMessages(a), isEmpty);
    });
  });
}
