import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/screens/add_expense_screen.dart';
import 'package:expense_tracker/screens/history_screen.dart';
import 'package:expense_tracker/screens/reports_screen.dart';
import 'package:expense_tracker/screens/settings_screen.dart';
import 'package:expense_tracker/utils/constants.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _expenseService = ExpenseService();
  int _currentIndex = 0;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final name = await _authService.getUserName();
    setState(() => _userName = name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _currentIndex == 0
          ? _buildHomePage()
          : _currentIndex == 1
              ? const HistoryScreen()
              : _currentIndex == 2
                  ? const ReportsScreen()
                  : const SettingsScreen(),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                );
                setState(() {});
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
    );
  }

  Widget _buildHomePage() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $_userName! 👋',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, MMM d').format(DateTime.now()),
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Total Spending Card
            StreamBuilder<List<ExpenseModel>>(
              stream: _expenseService.getExpenses(),
              builder: (context, snapshot) {
                final expenses = snapshot.data ?? [];
                final now = DateTime.now();

                final monthExpenses = expenses
                    .where((e) =>
                        e.date.month == now.month && e.date.year == now.year)
                    .toList();

                final todayExpenses = expenses
                    .where((e) =>
                        e.date.day == now.day &&
                        e.date.month == now.month &&
                        e.date.year == now.year)
                    .toList();

                final monthTotal =
                    monthExpenses.fold(0.0, (sum, e) => sum + e.amount);
                final todayTotal =
                    todayExpenses.fold(0.0, (sum, e) => sum + e.amount);

                return Column(
                  children: [
                    // Month Total Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'This Month Total',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${monthTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildMiniStat('Today',
                                  '₹${todayTotal.toStringAsFixed(0)}'),
                              const SizedBox(width: 24),
                              _buildMiniStat('Transactions',
                                  '${monthExpenses.length}'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Budget Alert ← ADD FROM HERE
                    _buildBudgetAlert(monthTotal),
                    const SizedBox(height: 8),
                    // ← ADD UNTIL HERE

                    _buildCategorySummary(monthExpenses),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _currentIndex = 1),
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    expenses.isEmpty
                        ? _buildEmptyState()
                        : Column(
                            children: expenses
                                .take(5)
                                .map((e) => _buildExpenseCard(e))
                                .toList(),
                          ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCategorySummary(List<ExpenseModel> expenses) {
    Map<String, double> categoryTotals = {};
    for (var e in expenses) {
      categoryTotals[e.category] =
          (categoryTotals[e.category] ?? 0) + e.amount;
    }
    if (categoryTotals.isEmpty) return const SizedBox();
    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Categories',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: top.map((entry) {
            final cat = AppCategories.categories.firstWhere(
              (c) => c['name'] == entry.key,
              orElse: () => AppCategories.categories.last,
            );
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(cat['icon'], style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(
                      entry.key,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '₹${entry.value.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExpenseCard(ExpenseModel expense) {
    final cat = AppCategories.categories.firstWhere(
      (c) => c['name'] == expense.category,
      orElse: () => AppCategories.categories.last,
    );
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Expense'),
            content: Text('Delete "${expense.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        await _expenseService.deleteExpense(expense.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense deleted!'),
            backgroundColor: AppColors.error,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: (cat['color'] as Color).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(cat['icon'],
                    style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      fontSize: 15,
                    ),
                  ),
                  if (expense.note.isNotEmpty)
                    Text(
                      expense.note,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  Text(
                    '${expense.category} • ${DateFormat('MMM d').format(expense.date)}',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  '-₹${expense.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                // Edit button
                GestureDetector(
                  onTap: () => _showEditDialog(expense),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _showEditDialog(ExpenseModel expense) async {
    final titleController = TextEditingController(text: expense.title);
    final amountController = TextEditingController(text: expense.amount.toStringAsFixed(0));
    final noteController = TextEditingController(text: expense.note);
    String selectedCategory = expense.category;
    String selectedIcon = expense.categoryIcon;
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Edit Expense", style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, decoration: InputDecoration(labelText: "Title", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 12),
                  TextField(controller: amountController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Amount", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 12),
                  TextField(controller: noteController, decoration: InputDecoration(labelText: "Note", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text) ?? expense.amount;
                  final updated = ExpenseModel(id: expense.id, userId: expense.userId, title: titleController.text.trim().isEmpty ? expense.title : titleController.text.trim(), amount: amount, category: selectedCategory, categoryIcon: selectedIcon, note: noteController.text.trim(), date: expense.date, createdAt: expense.createdAt);
                  await _expenseService.updateExpense(updated);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Expense updated! ✅"), backgroundColor: Color(0xFF10B981)));
                },
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2563EB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: const [
          SizedBox(height: 40),
          Text('💸', style: TextStyle(fontSize: 60)),
          SizedBox(height: 16),
          Text(
            'No expenses yet!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap + to add your first expense',
            style: TextStyle(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetAlert(double monthTotal) {
  return FutureBuilder<double>(
    future: _getBudget(),
    builder: (context, snapshot) {
      final budget = snapshot.data ?? 0.0;
      if (budget <= 0) return const SizedBox();

      final percentage = monthTotal / budget;
      final remaining = budget - monthTotal;

      Color alertColor;
      String alertMessage;
      IconData alertIcon;

      if (percentage >= 1.0) {
        alertColor = AppColors.error;
        alertMessage = '⚠️ Budget exceeded by ₹${(monthTotal - budget).toStringAsFixed(0)}!';
        alertIcon = Icons.warning_rounded;
      } else if (percentage >= 0.8) {
        alertColor = AppColors.warning;
        alertMessage = '🔔 80% of budget used! ₹${remaining.toStringAsFixed(0)} remaining';
        alertIcon = Icons.notifications_active;
      } else {
        alertColor = AppColors.secondary;
        alertMessage = '✅ On track! ₹${remaining.toStringAsFixed(0)} remaining this month';
        alertIcon = Icons.check_circle_outline;
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: alertColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: alertColor.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(alertIcon, color: alertColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alertMessage,
                    style: TextStyle(
                      color: alertColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage > 1.0 ? 1.0 : percentage,
                      backgroundColor: alertColor.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(alertColor),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${monthTotal.toStringAsFixed(0)} / ₹${budget.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: alertColor.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<double> _getBudget() async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_authService.currentUser!.uid)
        .get();
    return (doc['monthlyBudget'] ?? 0.0).toDouble();
  } catch (e) {
    return 0.0;
  }
}

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textLight,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart), label: 'Reports'),
        BottomNavigationBarItem(
            icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}