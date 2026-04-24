// lib/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../theme/app_theme.dart';
import '../models/expense.dart';
import '../services/ai_service.dart';
import '../widgets/glass_card.dart';

class ReportsScreen extends StatefulWidget {
  final AIService aiService;
  final List<Expense> expenses;

  const ReportsScreen({
    super.key,
    required this.aiService,
    required this.expenses,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isGenerating = false;
  Map<String, dynamic>? _report;
  final currencyFmt =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  double get totalThisMonth {
    final now = DateTime.now();
    return widget.expenses
        .where((e) => e.date.month == now.month && e.date.year == now.year)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get taxDeductible {
    final now = DateTime.now();
    return widget.expenses
        .where((e) =>
            e.date.month == now.month &&
            e.date.year == now.year &&
            e.isTaxDeductible)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  Map<String, double> get categoryTotals {
    final now = DateTime.now();
    final map = <String, double>{};
    for (final e in widget.expenses
        .where((e) => e.date.month == now.month && e.date.year == now.year)) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);
    final now = DateTime.now();
    final result = await widget.aiService.generateMonthlyReport(
      widget.expenses,
      now.month,
      now.year,
    );
    setState(() {
      _report = result;
      _isGenerating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'Monthly Report',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isGenerating ? null : _generateReport,
            icon: const Icon(Icons.psychology_outlined,
                color: AppColors.gold, size: 16),
            label: Text(
              'Generate AI Report',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthHeader(),
            const SizedBox(height: 20),
            _buildSummaryCards(),
            const SizedBox(height: 20),
            _buildCategoryBars(),
            const SizedBox(height: 20),
            if (_isGenerating) _buildGeneratingCard(),
            if (_report != null && !_isGenerating) ...[
              _buildHealthScore(),
              const SizedBox(height: 20),
              _buildAISummary(),
              const SizedBox(height: 20),
              _buildCashFlowPrediction(),
              const SizedBox(height: 20),
              _buildRecommendations(),
            ],
            if (_report == null && !_isGenerating) _buildGeneratePrompt(),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    return FadeInDown(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(DateTime.now()).toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Financial Overview',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 28,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return FadeInUp(
      child: Row(
        children: [
          Expanded(
            child: _summaryCard(
              'Total Spent',
              currencyFmt.format(totalThisMonth),
              Icons.account_balance_wallet_outlined,
              AppColors.gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _summaryCard(
              'Tax Savings',
              currencyFmt.format(taxDeductible),
              Icons.savings_outlined,
              AppColors.teal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBars() {
    final totals = categoryTotals;
    if (totals.isEmpty) return const SizedBox.shrink();

    final maxVal = totals.values.reduce((a, b) => a > b ? a : b);
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return FadeInUp(
      delay: const Duration(milliseconds: 100),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Breakdown',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ...sorted.asMap().entries.map((entry) {
              final idx = entry.key;
              final e = entry.value;
              final pct = e.value / maxVal;
              final color =
                  AppColors.chartColors[idx % AppColors.chartColors.length];
              final catEmoji = ExpenseCategory.values
                  .firstWhere(
                    (c) => c.name == e.key,
                    orElse: () => ExpenseCategory.other,
                  )
                  .emoji;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(catEmoji,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.key,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          currencyFmt.format(e.value),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearPercentIndicator(
                      percent: pct.clamp(0.0, 1.0),
                      lineHeight: 6,
                      backgroundColor: AppColors.surfaceElevated,
                      progressColor: color,
                      barRadius: const Radius.circular(4),
                      padding: EdgeInsets.zero,
                      animation: true,
                      animationDuration: 800,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratingCard() {
    return FadeIn(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.goldGlow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your AI CFO is analyzing...',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Generating CFO-level insights from your expense data',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratePrompt() {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: _generateReport,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.gold.withOpacity(0.2),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.goldGlow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.psychology_outlined,
                    color: AppColors.gold, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'Generate AI CFO Report',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Get CFO-level insights: executive summary, cash flow prediction, tax optimization, and personalized recommendations',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppGradients.goldGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Generate Now',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.background,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthScore() {
    final score =
        (_report?['spendingHealthScore'] as num?)?.toDouble() ?? 50;
    final reason = _report?['healthScoreReason'] ?? '';
    final color = score >= 70
        ? AppColors.success
        : score >= 40
            ? AppColors.warning
            : AppColors.danger;

    return FadeInUp(
      child: GlassCard(
        child: Row(
          children: [
            CircularPercentIndicator(
              radius: 48,
              lineWidth: 6,
              percent: score / 100,
              progressColor: color,
              backgroundColor: AppColors.surfaceElevated,
              circularStrokeCap: CircularStrokeCap.round,
              center: Text(
                '${score.toInt()}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spending Health Score',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reason,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAISummary() {
    return FadeInUp(
      delay: const Duration(milliseconds: 100),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_outlined,
                    color: AppColors.gold, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Executive Summary',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _report?['aiSummary'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.goldGlow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      color: AppColors.gold, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _report?['topInsight'] ?? '',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        color: AppColors.goldLight,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashFlowPrediction() {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline_rounded,
                    color: AppColors.teal, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Cash Flow Prediction',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _report?['cashFlowPrediction'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    final recs = (_report?['recommendations'] as List?)
            ?.map((r) => r.toString())
            .toList() ??
        [];

    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CFO Recommendations',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...recs.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: AppGradients.goldGradient,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.background,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
