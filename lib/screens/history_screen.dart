import 'package:flutter/material.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/utils/constants.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _expenseService = ExpenseService();
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Transaction History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            color: AppColors.primary,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  ...AppCategories.categories
                      .map((c) => _buildFilterChip(c['name'])),
                ],
              ),
            ),
          ),

          // Expense List
          Expanded(
            child: StreamBuilder<List<ExpenseModel>>(
              stream: _expenseService.getExpenses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final allExpenses = snapshot.data ?? [];
                final expenses = _selectedCategory == 'All'
                    ? allExpenses
                    : allExpenses
                        .where((e) => e.category == _selectedCategory)
                        .toList();

                if (expenses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('💸', style: TextStyle(fontSize: 50)),
                        SizedBox(height: 12),
                        Text(
                          'No transactions found',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Group by date
                Map<String, List<ExpenseModel>> grouped = {};
                for (var e in expenses) {
                  final key = DateFormat('MMM d, yyyy').format(e.date);
                  grouped[key] = [...(grouped[key] ?? []), e];
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: grouped.keys.length,
                  itemBuilder: (context, index) {
                    final date = grouped.keys.elementAt(index);
                    final dayExpenses = grouped[date]!;
                    final dayTotal = dayExpenses.fold(
                        0.0, (sum, e) => sum + e.amount);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Header
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                date,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '-₹${dayTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Expenses for this date
                        ...dayExpenses.map((expense) =>
                            _buildExpenseCard(expense)),

                        const SizedBox(height: 8),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(ExpenseModel expense) async {
    final titleController = TextEditingController(text: expense.title);
    final amountController =
        TextEditingController(text: expense.amount.toStringAsFixed(0));
    final noteController = TextEditingController(text: expense.note);
    String selectedCategory = expense.category;
    String selectedIcon = expense.categoryIcon;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Edit Expense',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Amount
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount (₹)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Note
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: 'Note',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Category',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.9,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: AppCategories.categories.length,
                    itemBuilder: (context, index) {
                      final cat = AppCategories.categories[index];
                      final isSelected = selectedCategory == cat['name'];
                      return GestureDetector(
                        onTap: () => setDialogState(() {
                          selectedCategory = cat['name'];
                          selectedIcon = cat['icon'];
                        }),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (cat['color'] as Color).withOpacity(0.2)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected
                                ? Border.all(
                                    color: cat['color'] as Color, width: 2)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(cat['icon'],
                                  style: const TextStyle(fontSize: 20)),
                              Text(
                                cat['name'],
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isSelected
                                      ? cat['color'] as Color
                                      : AppColors.textLight,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final amount =
                      double.tryParse(amountController.text) ?? expense.amount;
                  final updated = ExpenseModel(
                    id: expense.id,
                    userId: expense.userId,
                    title: titleController.text.trim().isEmpty
                        ? expense.title
                        : titleController.text.trim(),
                    amount: amount,
                    category: selectedCategory,
                    categoryIcon: selectedIcon,
                    note: noteController.text.trim(),
                    date: expense.date,
                    createdAt: expense.createdAt,
                  );
                  await _expenseService.updateExpense(updated);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Expense updated! ✅'),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.white,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
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
              crossAxisAlignment: CrossAxisAlignment.end,
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
}