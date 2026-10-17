/// Calendar dates for transactions, stored as `yyyy-MM-dd` strings.
///
/// Transactions happen on a day, not at an instant, so storing a plain date
/// avoids time-zone shifts and keeps string comparison equal to date order.
library;

String toDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime fromDateKey(String key) {
  final parts = key.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

DateTime dateOnly(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month, dateTime.day);

/// Calendar-day arithmetic that is safe across daylight-saving changes
/// (unlike adding a `Duration`).
DateTime addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

/// Whole calendar days from [from] to [to].
int daysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day)
        .difference(DateTime.utc(from.year, from.month, from.day))
        .inDays;

/// A range of calendar days: [start] inclusive, [end] exclusive.
class DateRange {
  DateRange(DateTime start, DateTime end)
      : start = dateOnly(start),
        end = dateOnly(end);

  factory DateRange.monthOf(DateTime date) => DateRange(
        DateTime(date.year, date.month),
        DateTime(date.year, date.month + 1),
      );

  factory DateRange.previousMonthOf(DateTime date) => DateRange(
        DateTime(date.year, date.month - 1),
        DateTime(date.year, date.month),
      );

  final DateTime start;
  final DateTime end;

  String get startKey => toDateKey(start);
  String get endKey => toDateKey(end);

  bool containsKey(String dateKey) =>
      dateKey.compareTo(startKey) >= 0 && dateKey.compareTo(endKey) < 0;

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}
