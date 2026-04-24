// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/expense.dart';
import '../widgets/glass_card.dart';
import '../widgets/stat_chip.dart';
import '../widgets/spending_ring.dart';

class DashboardScreen extends StatefulWidget {
  final List<Expense> expenses;
  final VoidCallback onAddExpense;
  final VoidCallback onScanReceipt;

  const DashboardScreen({
    super.key,
    required this.expenses,
    required this.onAddExpense,
    required this.onScanReceipt,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  double get totalThisMonth {
    final now = DateTime.now();
    return widget.expenses
        .where((e) => e.date.month == now.month && e.date.year == now.year)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get taxDeductibleThisMonth {
    final now = DateTime.now();
    return widget.expenses
        .where((e) =>
            e.date.month == now.month &&
            e.date.year == now.year &&
            e.isTaxDeductible)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  int get anomaliesCount =>
      widget.expenses.where((e) => e.isAnomalous).length;

  Map<String, double> get categoryTotals {
    final map = <String, double>{};
    final now = DateTime.now();
    for (final e in widget.expenses.where(
        (e) => e.date.month == now.month && e.date.year == now.year)) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  List<FlSpot> get weeklySpots {
    final spots = <FlSpot>[];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime.now().subtract(Duration(days: i));
      final total = widget.expenses
          .where((e) =>
              e.date.year == day.year &&
              e.date.month == day.month &&
              e.date.day == day.day)
          .fold(0.0, (sum, e) => sum + e.amount);
      spots.add(FlSpot((6 - i).toDouble(), total));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                _buildHeroCard(),
                const SizedBox(height: 20),
                _buildQuickStats(),
                const SizedBox(height: 24),
                _buildWeeklyChart(),
                const SizedBox(height: 24),
                _buildCategoryBreakdown(),
                const SizedBox(height: 24),
                _buildRecentExpenses(),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      backgroundColor: AppColors.background,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: FadeInDown(
          duration: const Duration(milliseconds: 600),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXPENSE',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold,
                      letterSpacing: 3,
                    ),
                  ),
                  Text(
                    'Story',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Row(
                  children: [
                    if (anomaliesCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.danger.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                size: 12, color: AppColors.danger),
                            const SizedBox(width: 4),
                            Text(
                              '$anomaliesCount alerts',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF2A2A3E)),
                        ),
                        child: const Icon(Icons.notifications_outlined,
                            size: 18, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return FadeInUp(
      duration: const Duration(milliseconds: 700),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1420), Color(0xFF201830), Color(0xFF1A1420)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: AppColors.gold.withOpacity(0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.08),
              blurRadius: 40,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(DateTime.now()),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Spent',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.goldGlow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.auto_graph_rounded,
                        color: AppColors.gold,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppGradients.goldGradient.createShader(bounds),
              child: Text(
                currencyFormat.format(totalThisMonth),
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(height: 1, color: const Color(0xFF2A2A3E)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    '₹${NumberFormat.compact(locale: 'en_IN').format(taxDeductibleThisMonth)}',
                    'Tax Deductible',
                    Icons.receipt_long_outlined,
                    AppColors.teal,
                  ),
                ),
                Container(
                    width: 1, height: 40, color: const Color(0xFF2A2A3E)),
                Expanded(
                  child: _buildMiniStat(
                    widget.expenses.length.toString(),
                    'Transactions',
                    Icons.swap_horiz_rounded,
                    AppColors.info,
                  ),
                ),
                Container(
                    width: 1, height: 40, color: const Color(0xFF2A2A3E)),
                Expanded(
                  child: _buildMiniStat(
                    '${((taxDeductibleThisMonth / (totalThisMonth == 0 ? 1 : totalThisMonth)) * 100).toStringAsFixed(0)}%',
                    'Savings Rate',
                    Icons.trending_up_rounded,
                    AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(
      String value, String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Row(
        children: [
          Expanded(
            child: StatChip(
              label: 'Scan Receipt',
              icon: Icons.document_scanner_outlined,
              color: AppColors.gold,
              onTap: widget.onScanReceipt,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatChip(
              label: 'Add Manual',
              icon: Icons.add_circle_outline_rounded,
              color: AppColors.teal,
              onTap: widget.onAddExpense,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatChip(
              label: 'AI Report',
              icon: Icons.psychology_outlined,
              color: AppColors.info,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final spots = weeklySpots;
    final maxY = spots.isEmpty
        ? 1000.0
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.3;

    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weekly Overview',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.goldGlow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Last 7 days',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  backgroundColor: Colors.transparent,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: const Color(0xFF2A2A3E),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final day = DateTime.now()
                              .subtract(Duration(days: 6 - value.toInt()));
                          return Text(
                            DateFormat('E').format(day).substring(0, 1),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: maxY == 0 ? 1000 : maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots.isEmpty
                          ? [const FlSpot(0, 0), const FlSpot(6, 0)]
                          : spots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: AppColors.gold,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.gold,
                          strokeWidth: 2,
                          strokeColor: AppColors.background,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.gold.withOpacity(0.2),
                            AppColors.gold.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: AppColors.surfaceCard,
                      tooltipBorder: const BorderSide(color: AppColors.gold, width: 0.5),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '₹${spot.y.toStringAsFixed(0)}',
                            GoogleFonts.spaceGrotesk(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final totals = categoryTotals;
    if (totals.isEmpty) return const SizedBox.shrink();

    final total = totals.values.fold(0.0, (a, b) => a + b);
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Breakdown',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                SpendingRing(categoryData: totals),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: sorted.take(4).toList().asMap().entries.map((entry) {
                      final idx = entry.key;
                      final e = entry.value;
                      final pct = (e.value / total * 100).toStringAsFixed(1);
                      final color =
                          AppColors.chartColors[idx % AppColors.chartColors.length];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.key,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '$pct%',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentExpenses() {
    final recent = widget.expenses.take(5).toList();
    if (recent.isEmpty) {
      return FadeInUp(
        delay: const Duration(milliseconds: 500),
        child: GlassCard(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'No expenses yet',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Scan a receipt or add manually to get started',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return FadeInUp(
      delay: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Expenses',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'View all',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimationLimiter(
            child: Column(
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 400),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 20,
                  child: FadeInAnimation(child: widget),
                ),
                children: recent.map((e) => _buildExpenseTile(e)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseTile(Expense expense) {
    final categoryEmoji = ExpenseCategory.values
        .firstWhere(
          (c) => c.name == expense.category,
          orElse: () => ExpenseCategory.other,
        )
        .emoji;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: expense.isAnomalous
              ? AppColors.danger.withOpacity(0.4)
              : const Color(0xFF2A2A3E),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(categoryEmoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        expense.title,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (expense.isAnomalous)
                      const Icon(Icons.warning_amber_rounded,
                          size: 14, color: AppColors.danger),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${expense.vendor} · ${DateFormat('MMM d').format(expense.date)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${NumberFormat('#,##,###').format(expense.amount)}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (expense.isTaxDeductible)
                Text(
                  'Tax ✓',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    color: AppColors.teal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
