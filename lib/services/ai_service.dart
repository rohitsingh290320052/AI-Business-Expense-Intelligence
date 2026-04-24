// lib/services/ai_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/expense.dart';

class AIService {
  static const _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'YOUR_GEMINI_API_KEY',
  );

  late final GenerativeModel _model;
  late final GenerativeModel _visionModel;

  AIService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
    _visionModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
  }

  /// Analyze receipt image and extract expense data
  Future<Map<String, dynamic>> analyzeReceipt(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final prompt = '''
You are an intelligent expense tracking assistant for businesses in India.
Analyze this receipt image and extract structured data.

Return ONLY a valid JSON object with this exact structure:
{
  "title": "Short expense title",
  "amount": 0.00,
  "currency": "INR",
  "vendor": "Vendor/merchant name",
  "category": "one of: food, transport, software, office, marketing, utilities, salaries, travel, legal, other",
  "date": "YYYY-MM-DD",
  "paymentMethod": "cash/card/upi/netbanking/unknown",
  "isTaxDeductible": true or false,
  "taxDeductionReason": "Reason if tax deductible, else null",
  "aiInsight": "One smart business insight about this expense in 1-2 sentences",
  "description": "Brief description"
}

Be accurate with amounts. If currency is not clear, assume INR.
''';

      final response = await _visionModel.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ]),
      ]);

      final text = response.text ?? '{}';
      final jsonStr = _extractJson(text);
      return json.decode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return {
        'title': 'Unknown Expense',
        'amount': 0.0,
        'currency': 'INR',
        'vendor': 'Unknown',
        'category': 'other',
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'paymentMethod': 'unknown',
        'isTaxDeductible': false,
        'taxDeductionReason': null,
        'aiInsight': 'Could not analyze receipt automatically.',
        'description': '',
      };
    }
  }

  /// Categorize and analyze a manually entered expense
  Future<Map<String, dynamic>> analyzeExpense({
    required String title,
    required double amount,
    required String vendor,
    String? description,
  }) async {
    try {
      final prompt = '''
You are a CFO-level AI assistant for Indian SMBs and solopreneurs.
Analyze this business expense and return structured intelligence.

Expense Details:
- Title: $title
- Amount: ₹$amount
- Vendor: $vendor
- Description: ${description ?? 'N/A'}

Return ONLY valid JSON:
{
  "category": "one of: food, transport, software, office, marketing, utilities, salaries, travel, legal, other",
  "isTaxDeductible": true or false,
  "taxDeductionReason": "Explanation under Indian GST/IT rules, or null",
  "aiInsight": "Smart CFO insight about this expense — ROI, optimization tip, or benchmark comparison",
  "isAnomalous": false,
  "anomalyReason": null
}
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';
      final jsonStr = _extractJson(text);
      return json.decode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return {
        'category': 'other',
        'isTaxDeductible': false,
        'taxDeductionReason': null,
        'aiInsight': 'Expense recorded successfully.',
        'isAnomalous': false,
        'anomalyReason': null,
      };
    }
  }

  /// Detect anomalies in spending patterns
  Future<Map<String, dynamic>> detectAnomalies(
    List<Expense> recentExpenses,
    Expense newExpense,
  ) async {
    if (recentExpenses.isEmpty) {
      return {'isAnomalous': false, 'anomalyReason': null};
    }

    try {
      final history = recentExpenses
          .take(20)
          .map((e) => '${e.category}: ₹${e.amount} at ${e.vendor}')
          .join('\n');

      final prompt = '''
You are an AI anomaly detector for business expenses.

Recent expense history:
$history

New expense to evaluate:
- Category: ${newExpense.category}
- Amount: ₹${newExpense.amount}
- Vendor: ${newExpense.vendor}

Is this new expense anomalous compared to the spending pattern?
Return ONLY JSON:
{
  "isAnomalous": true or false,
  "anomalyReason": "Brief explanation if anomalous, else null",
  "confidenceScore": 0.0 to 1.0
}
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';
      return json.decode(_extractJson(text)) as Map<String, dynamic>;
    } catch (e) {
      return {'isAnomalous': false, 'anomalyReason': null, 'confidenceScore': 0};
    }
  }

  /// Generate CFO-style monthly report
  Future<Map<String, dynamic>> generateMonthlyReport(
    List<Expense> expenses,
    int month,
    int year,
  ) async {
    try {
      final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
      final taxDeductible =
          expenses.where((e) => e.isTaxDeductible).fold(0.0, (sum, e) => sum + e.amount);

      final categoryBreakdown = <String, double>{};
      for (final e in expenses) {
        categoryBreakdown[e.category] = (categoryBreakdown[e.category] ?? 0) + e.amount;
      }

      final breakdown = categoryBreakdown.entries
          .map((e) => '${e.key}: ₹${e.value.toStringAsFixed(0)}')
          .join(', ');

      final prompt = '''
You are a CFO-level AI generating a monthly expense report for an Indian SMB/solopreneur.

Month: $month/$year
Total Spent: ₹${totalSpent.toStringAsFixed(0)}
Tax Deductible: ₹${taxDeductible.toStringAsFixed(0)}
Category Breakdown: $breakdown
Total Transactions: ${expenses.length}

Generate an insightful CFO-style monthly report. Return ONLY JSON:
{
  "aiSummary": "2-3 sentences executive summary of this month's spending",
  "cashFlowPrediction": "Intelligent prediction for next month based on patterns (2 sentences)",
  "topInsight": "The single most important actionable insight for the business owner",
  "recommendations": [
    "Specific recommendation 1",
    "Specific recommendation 2", 
    "Specific recommendation 3"
  ],
  "spendingHealthScore": 0 to 100,
  "healthScoreReason": "Why this score"
}
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';
      return json.decode(_extractJson(text)) as Map<String, dynamic>;
    } catch (e) {
      return {
        'aiSummary': 'Unable to generate report at this time.',
        'cashFlowPrediction': 'Analysis unavailable.',
        'topInsight': 'Check your spending patterns.',
        'recommendations': ['Review expenses', 'Track receipts', 'Set budgets'],
        'spendingHealthScore': 50,
        'healthScoreReason': 'Insufficient data',
      };
    }
  }

  /// Chat with CFO AI assistant
  Future<String> chatWithCFO(String message, List<Expense> expenses) async {
    try {
      final context = expenses
          .take(10)
          .map((e) => '${e.title}: ₹${e.amount} (${e.category})')
          .join('\n');

      final prompt = '''
You are ExpenseStory's AI CFO assistant — a smart, direct financial advisor for Indian SMBs.
You have access to recent expense data. Answer concisely with actionable advice.

Recent expenses:
$context

User question: $message

Respond in 2-4 sentences max. Be specific, data-driven, and practical.
If asked about tax savings, reference Indian GST/IT Act rules.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'I could not process your question. Please try again.';
    } catch (e) {
      return 'AI assistant temporarily unavailable. Please try again.';
    }
  }

  String _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return text.substring(start, end + 1);
    }
    return '{}';
  }
}
