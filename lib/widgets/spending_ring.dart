// lib/widgets/spending_ring.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class SpendingRing extends StatelessWidget {
  final Map<String, double> categoryData;

  const SpendingRing({super.key, required this.categoryData});

  @override
  Widget build(BuildContext context) {
    final total = categoryData.values.fold(0.0, (a, b) => a + b);
    final sorted = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SizedBox(
      width: 120,
      height: 120,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 30,
          sections: sorted.asMap().entries.map((entry) {
            final idx = entry.key;
            final e = entry.value;
            final color =
                AppColors.chartColors[idx % AppColors.chartColors.length];
            return PieChartSectionData(
              value: e.value,
              color: color,
              radius: 28,
              showTitle: false,
            );
          }).toList(),
        ),
      ),
    );
  }
}
