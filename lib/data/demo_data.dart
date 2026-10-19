import '../core/date_only.dart';
import '../core/money/currency.dart';
import '../domain/entry_draft.dart';
import '../domain/enums.dart';
import 'ledger_repository.dart';

/// Months of sample history, so seasonality has two harvests to compare.
const demoMonths = 24;

/// Example records for demos: two years of a small shop whose family also
/// farms rice, in both USD and KHR. Deterministic, so every demo looks the
/// same, and shaped so each dashboard view has something to show:
///
/// - shop sales are recorded per item, strongest on weekends and weakest
///   on Tuesdays;
/// - rice is sold in November and December, and April-May is the lean season;
/// - rent, a stall fee, electricity, internet, a loan payment and wages
///   repeat monthly;
/// - fuel costs jump this month, so a spending alert appears;
/// - in the lean months, and this month, the owner takes out more than the
///   business makes.
///
/// Every entry goes through the normal validated save path.
Future<int> loadDemoData(LedgerRepository repo, {DateTime? today}) async {
  final drafts = demoDrafts(today ?? DateTime.now());
  await repo.createAll(drafts);
  final start = drafts.first.occurredOn;
  await repo.setOpeningBalance(Currency.usd, 50000, start);
  await repo.setOpeningBalance(Currency.khr, 400000, start);
  return drafts.length;
}

/// The entries [loadDemoData] saves, oldest first.
List<EntryDraft> demoDrafts(DateTime today) {
  final end = dateOnly(today);
  final start = DateTime(end.year, end.month - demoMonths + 1);
  final thisMonth = DateTime(end.year, end.month);
  final drafts = <EntryDraft>[];

  void add(
    EntryType type,
    int amountMinor,
    Currency currency,
    DateTime date, {
    String? category,
    String description = '',
    PaymentMethod? paidBy,
  }) {
    if (date.isAfter(end)) return;
    drafts.add(EntryDraft(
      type: type,
      amountMinor: amountMinor,
      currency: currency,
      occurredOn: date,
      categoryId: category,
      categoryKind: type.categoryKind,
      description: description,
      paymentMethod: paidBy,
    ));
  }

  // Average shop takings in cents, Monday first.
  const weekdaySales = [4000, 2800, 3600, 4000, 5000, 6800, 5800];

  for (var day = start; !day.isAfter(end); day = addDays(day, 1)) {
    final i = daysBetween(start, day);
    final month = day.month;
    final lean = month == 4 || month == 5;
    final isThisMonth = !day.isBefore(thisMonth);

    // Daily shop sales: USD from larger customers, KHR from small purchases.
    var usdSales = weekdaySales[day.weekday - 1] + (i * 37 % 1200);
    if (lean) usdSales = usdSales * 7 ~/ 10;
    if (month >= 10) usdSales = usdSales * 11 ~/ 10;
    // The shop grows about 10% a year.
    usdSales = usdSales * (100 + 10 * (day.year - start.year)) ~/ 100;
    // Recorded per item: rice and drinks every day, and one of the smaller
    // lines in turn. Drinks sell more in the hot season, and snacks have
    // picked up this month since school started.
    final rice = usdSales * 40 ~/ 100;
    final drinks = usdSales * (month >= 3 && month <= 5 ? 35 : 25) ~/ 100;
    final (other, otherName) = switch (i % 3) {
      0 => (usdSales - rice - drinks, 'Cooking oil'),
      1 => (usdSales - rice - drinks + (isThisMonth ? 1500 : 0), 'Snacks'),
      _ => (usdSales - rice - drinks, 'Phone top-up cards'),
    };
    for (final (amount, name) in [
      (rice, 'Rice (by the bag)'),
      (drinks, 'Drinks'),
      (other, otherName),
    ]) {
      add(EntryType.income, amount, Currency.usd, day,
          category: 'sales', description: name, paidBy: PaymentMethod.cash);
    }
    if (i % 2 == 0) {
      final khrSales = 60000 + (i * 1300 % 50000);
      add(EntryType.income, khrSales - khrSales % 100, Currency.khr, day,
          category: 'sales',
          description: i % 4 == 0 ? 'Vegetables' : 'Ice & drinking water',
          paidBy: PaymentMethod.cash);
    }

    // Phone charging and small repairs on market days.
    if (day.weekday == DateTime.wednesday || day.weekday == DateTime.saturday) {
      add(EntryType.income, 1200 + (i * 29 % 900), Currency.usd, day,
          category: 'services', description: 'Phone repair & charging',
          paidBy: PaymentMethod.cash);
    }

    // Weekly stock purchase on Mondays.
    if (day.weekday == DateTime.monday) {
      add(EntryType.expense, 14000 + (i * 53 % 4000), Currency.usd, day,
          category: 'stock', description: 'Restock from supplier',
          paidBy: PaymentMethod.mobileWallet);
    }

    // Motorbike fuel on Thursdays; prices jumped this month.
    if (day.weekday == DateTime.thursday) {
      add(EntryType.expense, (isThisMonth ? 2200 : 1200) + (i % 3) * 50,
          Currency.usd, day,
          category: 'transport', description: 'Fuel for motorbike',
          paidBy: PaymentMethod.cash);
    }

    // Tuk-tuk deliveries every few days, in riel.
    if (i % 3 == 1) {
      add(EntryType.expense, 15000 + (i % 4) * 5000, Currency.khr, day,
          category: 'transport', description: 'Tuk-tuk delivery',
          paidBy: PaymentMethod.cash);
    }

    // Regular monthly bills.
    switch (day.day) {
      case 1:
        add(EntryType.expense, 15000, Currency.usd, day,
            category: 'rent', description: 'Shop rent', paidBy: PaymentMethod.bank);
      case 5:
        add(EntryType.expense, 180000 + month * 7000, Currency.khr, day,
            category: 'utilities', description: 'Electricity (EDC)',
            paidBy: PaymentMethod.mobileWallet);
        add(EntryType.expense, 500, Currency.usd, day,
            category: 'phone_internet', description: 'Phone & internet top-up',
            paidBy: PaymentMethod.mobileWallet);
      case 10:
        add(EntryType.expense, 8000, Currency.usd, day,
            category: 'other_expense', description: 'Microfinance loan payment',
            paidBy: PaymentMethod.bank);
      case 15:
        add(EntryType.expense, 6000, Currency.usd, day,
            category: 'wages', description: 'Shop helper wages (1st half)',
            paidBy: PaymentMethod.cash);
      case 22:
        add(EntryType.expense, 1000, Currency.usd, day,
            category: 'rent', description: 'Market stall fee',
            paidBy: PaymentMethod.cash);
      case 28:
        add(EntryType.expense, 6000, Currency.usd, day,
            category: 'wages', description: 'Shop helper wages (2nd half)',
            paidBy: PaymentMethod.cash);
    }

    // Rice field: seeds and fertilizer at planting, a harvest in Nov-Dec,
    // vegetables from the same land between rice seasons.
    if (month == 5 && day.day == 20) {
      add(EntryType.expense, 4000, Currency.usd, day,
          category: 'farm_inputs', description: 'Rice seed', paidBy: PaymentMethod.cash);
    }
    if ((month == 6 || month == 8) && day.day == 12) {
      add(EntryType.expense, 9500, Currency.usd, day,
          category: 'farm_inputs', description: 'Fertilizer (2 bags)',
          paidBy: PaymentMethod.cash);
    }
    if (month == 11 && day.day == 8) {
      add(EntryType.expense, 12000, Currency.usd, day,
          category: 'wages', description: 'Harvest labour', paidBy: PaymentMethod.cash);
    }
    if ((month == 11 || month == 12) && (day.day == 12 || day.day == 26)) {
      add(EntryType.income, 30000 + (i % 5) * 1000, Currency.usd, day,
          category: 'crop_sales', description: 'Rice sold to miller',
          paidBy: PaymentMethod.bank);
      add(EntryType.income, 800000, Currency.khr, day,
          category: 'crop_sales', description: 'Rice sold at market',
          paidBy: PaymentMethod.cash);
    }
    if ((month <= 3 || (month >= 7 && month <= 9)) && day.day == 18) {
      add(EntryType.income, 250000, Currency.khr, day,
          category: 'crop_sales', description: 'Vegetable sale',
          paidBy: PaymentMethod.cash);
    }

    // The owner takes money home on the 20th; more in the lean season, and
    // school fees early this month.
    if (day.day == 20) {
      add(EntryType.ownerWithdrawal, lean ? 30000 : 10000, Currency.usd, day,
          description: 'Family expenses', paidBy: PaymentMethod.cash);
    }
    if (isThisMonth && day.day == 3) {
      add(EntryType.ownerWithdrawal, 80000, Currency.usd, day,
          description: 'School fees and uniforms', paidBy: PaymentMethod.cash);
    }
    if (month == 5 && day.day == 25) {
      add(EntryType.ownerContribution, 20000, Currency.usd, day,
          description: 'Savings put back into the shop', paidBy: PaymentMethod.cash);
    }
  }
  return drafts;
}
