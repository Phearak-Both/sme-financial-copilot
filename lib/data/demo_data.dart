import '../core/date_only.dart';
import '../core/money/currency.dart';
import '../domain/entry_draft.dart';
import '../domain/enums.dart';
import 'ledger_repository.dart';

/// Example records for demos: about 90 days of a small shop that also
/// sells produce, in both USD and KHR. Deterministic, so every demo looks
/// the same. Every entry goes through the normal validated save path.
Future<int> loadDemoData(LedgerRepository repo, {DateTime? today}) async {
  final end = dateOnly(today ?? DateTime.now());
  final start = addDays(end, -89);
  var count = 0;

  Future<void> add(
    EntryType type,
    int amountMinor,
    Currency currency,
    DateTime date, {
    String? category,
    String description = '',
    PaymentMethod? paidBy,
  }) async {
    await repo.create(EntryDraft(
      type: type,
      amountMinor: amountMinor,
      currency: currency,
      occurredOn: date,
      categoryId: category,
      categoryKind: type.categoryKind,
      description: description,
      paymentMethod: paidBy,
    ));
    count++;
  }

  for (var i = 0; i < 90; i++) {
    final day = addDays(start, i);
    final weekday = day.weekday;

    // Daily shop sales: USD from larger customers, KHR from small purchases.
    final usdSales = 3500 + (i * 37 % 2500) + (weekday >= 6 ? 2000 : 0);
    await add(EntryType.income, usdSales, Currency.usd, day,
        category: 'sales', description: 'Shop sales', paidBy: PaymentMethod.cash);
    if (i % 2 == 0) {
      final khrSales = 60000 + (i * 1300 % 50000);
      await add(EntryType.income, khrSales - khrSales % 100, Currency.khr, day,
          category: 'sales', description: 'Small sales (riel)', paidBy: PaymentMethod.cash);
    }

    // Weekly stock purchase on Mondays, paid by bank/mobile wallet.
    if (weekday == DateTime.monday) {
      await add(EntryType.expense, 18000 + (i * 53 % 6000), Currency.usd, day,
          category: 'stock', description: 'Restock from supplier',
          paidBy: PaymentMethod.mobileWallet);
    }

    // Transport every few days, in riel.
    if (i % 3 == 1) {
      await add(EntryType.expense, 15000 + (i % 4) * 5000, Currency.khr, day,
          category: 'transport', description: 'Tuk-tuk delivery',
          paidBy: PaymentMethod.cash);
    }

    // Monthly costs on the 1st and 5th.
    if (day.day == 1) {
      await add(EntryType.expense, 15000, Currency.usd, day,
          category: 'rent', description: 'Shop rent', paidBy: PaymentMethod.bank);
    }
    if (day.day == 5) {
      await add(EntryType.expense, 180000 + day.month * 7000, Currency.khr, day,
          category: 'utilities', description: 'Electricity (EDC)',
          paidBy: PaymentMethod.mobileWallet);
      await add(EntryType.expense, 5000, Currency.usd, day,
          category: 'phone_internet', description: 'Phone & internet top-up',
          paidBy: PaymentMethod.mobileWallet);
    }

    // Helper wages twice a month.
    if (day.day == 15 || day.day == 28) {
      await add(EntryType.expense, 6000, Currency.usd, day,
          category: 'wages', description: 'Shop helper wages', paidBy: PaymentMethod.cash);
    }

    // Small farm plot: fertilizer early in the period, harvest sale later.
    if (i == 10 || i == 40) {
      await add(EntryType.expense, 9500, Currency.usd, day,
          category: 'farm_inputs', description: 'Fertilizer (2 bags)',
          paidBy: PaymentMethod.cash);
    }
    if (i == 70) {
      await add(EntryType.income, 1200000, Currency.khr, day,
          category: 'crop_sales', description: 'Vegetable harvest sale',
          paidBy: PaymentMethod.cash);
    }

    // Owner takes money home for the family each month.
    if (day.day == 20) {
      await add(EntryType.ownerWithdrawal, 10000, Currency.usd, day,
          description: 'Family expenses', paidBy: PaymentMethod.cash);
    }
  }

  await repo.setOpeningBalance(Currency.usd, 50000, start);
  await repo.setOpeningBalance(Currency.khr, 400000, start);
  return count;
}
