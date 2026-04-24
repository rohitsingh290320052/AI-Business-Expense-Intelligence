// lib/models/expense.dart
import 'package:isar/isar.dart';

part 'expense.g.dart';

@collection
class Expense {
  Id id = Isar.autoIncrement;

  late String title;
  late double amount;
  late String currency;
  late String category;
  late DateTime date;
  late String vendor;
  String? description;
  String? receiptImagePath;
  bool isTaxDeductible = false;
  String? taxDeductionReason;
  String? aiInsight;
  String? paymentMethod;
  bool isAnomalous = false;
  String? anomalyReason;

  @Index()
  late DateTime createdAt;

  Expense();
}

enum ExpenseCategory {
  food('Food & Dining', '🍽️'),
  transport('Transport', '🚗'),
  software('Software & Tools', '💻'),
  office('Office Supplies', '📦'),
  marketing('Marketing', '📢'),
  utilities('Utilities', '⚡'),
  salaries('Salaries', '👥'),
  travel('Business Travel', '✈️'),
  legal('Legal & Compliance', '⚖️'),
  other('Other', '📋');

  final String label;
  final String emoji;
  const ExpenseCategory(this.label, this.emoji);
}

@collection
class MonthlyReport {
  Id id = Isar.autoIncrement;

  late int month;
  late int year;
  late double totalSpent;
  late double totalTaxDeductible;
  late String aiSummary;
  late String cashFlowPrediction;
  late String topInsight;
  late List<String> recommendations;
  late DateTime generatedAt;

  MonthlyReport();
}
