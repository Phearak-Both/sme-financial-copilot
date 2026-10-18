import '../domain/enums.dart';
import 'database.dart';

/// Starter categories covering shops, services and farms.
/// Khmer names need review by native-speaking users.
List<CategoryRow> defaultCategories() {
  const income = [
    ('sales', 'Sales', 'ការលក់'),
    ('services', 'Services', 'សេវាកម្ម'),
    ('crop_sales', 'Crop sales', 'លក់ផលដំណាំ'),
    ('other_income', 'Other income', 'ចំណូលផ្សេងៗ'),
  ];
  const expense = [
    ('stock', 'Stock purchases', 'ទិញទំនិញស្តុក'),
    ('rent', 'Rent', 'ថ្លៃជួល'),
    ('utilities', 'Electricity & water', 'ទឹក និងភ្លើង'),
    ('wages', 'Wages', 'ប្រាក់ឈ្នួល'),
    ('transport', 'Transport', 'ដឹកជញ្ជូន'),
    ('farm_inputs', 'Fertilizer & seeds', 'ជី និងគ្រាប់ពូជ'),
    ('equipment', 'Equipment', 'ឧបករណ៍'),
    ('phone_internet', 'Phone & internet', 'ទូរស័ព្ទ និងអ៊ីនធឺណិត'),
    ('repairs', 'Repairs', 'ជួសជុល'),
    ('other_expense', 'Other expenses', 'ចំណាយផ្សេងៗ'),
  ];

  CategoryRow row(
    (String, String, String) category,
    CategoryKind kind,
    int order,
  ) =>
      CategoryRow(
        id: category.$1,
        kind: kind,
        nameEn: category.$2,
        nameKm: category.$3,
        sortOrder: order,
      );

  return [
    for (final (i, c) in income.indexed) row(c, CategoryKind.income, i),
    for (final (i, c) in expense.indexed) row(c, CategoryKind.expense, i),
  ];
}
