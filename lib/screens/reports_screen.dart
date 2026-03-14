import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/utils/constants.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _expenseService = ExpenseService();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Reports & Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<List<ExpenseModel>>(
        stream: _expenseService.getExpenses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final allExpenses = snapshot.data ?? [];
          final expenses = allExpenses
              .where((e) =>
                  e.date.month == _selectedMonth &&
                  e.date.year == _selectedYear)
              .toList();

          final total = expenses.fold(0.0, (sum, e) => sum + e.amount);

          // Category totals
          Map<String, double> categoryTotals = {};
          for (var e in expenses) {
            categoryTotals[e.category] =
                (categoryTotals[e.category] ?? 0) + e.amount;
          }

          // Weekly totals
          Map<int, double> weeklyTotals = {1: 0, 2: 0, 3: 0, 4: 0};
          for (var e in expenses) {
            final week = ((e.date.day - 1) / 7).floor() + 1;
            final weekNum = week > 4 ? 4 : week;
            weeklyTotals[weekNum] = (weeklyTotals[weekNum] ?? 0) + e.amount;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month Selector
                _buildMonthSelector(),
                const SizedBox(height: 20),

                // Total Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Total Spending',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMMM yyyy')
                            .format(DateTime(_selectedYear, _selectedMonth)),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                if (expenses.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Text('📊', style: TextStyle(fontSize: 50)),
                          SizedBox(height: 12),
                          Text(
                            'No data for this month',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  // Pie Chart
                  _buildPieChart(categoryTotals, total),
                  const SizedBox(height: 24),

                  // Bar Chart
                  _buildBarChart(weeklyTotals),
                  const SizedBox(height: 24),

                  // Category Breakdown
                  _buildCategoryBreakdown(categoryTotals, total),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                if (_selectedMonth == 1) {
                  _selectedMonth = 12;
                  _selectedYear--;
                } else {
                  _selectedMonth--;
                }
              });
            },
            icon: const Icon(Icons.chevron_left, color: AppColors.primary),
          ),
          Text(
            DateFormat('MMMM yyyy')
                .format(DateTime(_selectedYear, _selectedMonth)),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                if (_selectedMonth == 12) {
                  _selectedMonth = 1;
                  _selectedYear++;
                } else {
                  _selectedMonth++;
                }
              });
            },
            icon: const Icon(Icons.chevron_right, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> categoryTotals, double total) {
    final entries = categoryTotals.entries.toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending by Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 20),
          _PieChartWidget(entries: entries, total: total),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: entries.map((entry) {
              final cat = AppCategories.categories.firstWhere(
                (c) => c['name'] == entry.key,
                orElse: () => AppCategories.categories.last,
              );
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: cat['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<int, double> weeklyTotals) {
    final maxY = weeklyTotals.values.isEmpty
        ? 100.0
        : weeklyTotals.values.reduce((a, b) => a > b ? a : b) * 1.2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Spending',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY == 0 ? 100 : maxY,
                barGroups: weeklyTotals.entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        color: AppColors.primary,
                        width: 30,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
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
                        const weeks = ['Wk1', 'Wk2', 'Wk3', 'Wk4'];
                        final index = value.toInt() - 1;
                        if (index < 0 || index >= weeks.length) {
                          return const SizedBox();
                        }
                        return Text(
                          weeks[index],
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(
      Map<String, double> categoryTotals, double total) {
    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          ...sorted.map((entry) {
            final cat = AppCategories.categories.firstWhere(
              (c) => c['name'] == entry.key,
              orElse: () => AppCategories.categories.last,
            );
            final percentage = total > 0 ? entry.value / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(cat['icon'],
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '₹${entry.value.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(percentage * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          cat['color'] as Color),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PieChartWidget extends StatefulWidget {
  final List<MapEntry<String, double>> entries;
  final double total;

  const _PieChartWidget({
    required this.entries,
    required this.total,
  });

  @override
  State<_PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<_PieChartWidget> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (event, response) {
              setState(() {
                if (response == null || response.touchedSection == null) {
                  _touchedIndex = -1;
                } else {
                  _touchedIndex =
                      response.touchedSection!.touchedSectionIndex;
                }
              });
            },
          ),
          sections: widget.entries.asMap().entries.map((entry) {
            final i = entry.key;
            final cat = AppCategories.categories.firstWhere(
              (c) => c['name'] == entry.value.key,
              orElse: () => AppCategories.categories.last,
            );
            final isTouched = i == _touchedIndex;
            final percentage = (entry.value.value / widget.total * 100);
            return PieChartSectionData(
              color: cat['color'] as Color,
              value: entry.value.value,
              title: '${percentage.toStringAsFixed(1)}%',
              radius: isTouched ? 70 : 55,
              titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
          borderData: FlBorderData(show: false),
          centerSpaceRadius: 40,
        ),
      ),
    );
  }
}