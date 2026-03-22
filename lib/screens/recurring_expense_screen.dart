import 'package:flutter/material.dart';
import 'package:expense_tracker/models/recurring_expense_model.dart';
import 'package:expense_tracker/services/recurring_expense_service.dart';
import 'package:expense_tracker/utils/constants.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class RecurringExpenseScreen extends StatefulWidget {
  const RecurringExpenseScreen({super.key});

  @override
  State<RecurringExpenseScreen> createState() => _RecurringExpenseScreenState();
}

class _RecurringExpenseScreenState extends State<RecurringExpenseScreen> {
  final _service = RecurringExpenseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          '🔄 Recurring Expenses',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Recurring'),
      ),
      body: StreamBuilder<List<RecurringExpenseModel>>(
        stream: _service.getRecurringExpenses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final expenses = snapshot.data ?? [];
          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔄', style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 16),
                  const Text(
                    'No recurring expenses yet!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add rent, subscriptions, recharges\nthat repeat automatically!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: expenses.length,
            itemBuilder: (context, index) => _buildCard(expenses[index]),
          );
        },
      ),
    );
  }

  Widget _buildCard(RecurringExpenseModel expense) {
    final cat = AppCategories.categories.firstWhere(
      (c) => c['name'] == expense.category,
      orElse: () => AppCategories.categories.last,
    );
    final frequencyColor = expense.frequency == 'daily'
        ? AppColors.error
        : expense.frequency == 'weekly'
        ? AppColors.warning
        : AppColors.secondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
        border: Border.all(
          color: expense.isActive
              ? AppColors.primary.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: (cat['color'] as Color).withOpacity(
                expense.isActive ? 0.15 : 0.05,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(cat['icon'], style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: expense.isActive ? null : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: frequencyColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        expense.frequency.toUpperCase(),
                        style: TextStyle(
                          color: frequencyColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Next: ${DateFormat('MMM d').format(expense.nextDueDate)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${expense.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: expense.isActive ? AppColors.error : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _service.toggleActive(expense),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: expense.isActive
                            ? AppColors.secondary.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        expense.isActive ? 'ON' : 'OFF',
                        style: TextStyle(
                          color: expense.isActive
                              ? AppColors.secondary
                              : Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Recurring Expense'),
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
                      if (confirm == true) {
                        await _service.deleteRecurringExpense(expense.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Recurring expense deleted!'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog() async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedCategory = 'Food';
    String selectedIcon = '🍔';
    String selectedFrequency = 'monthly';

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              '🔄 Add Recurring Expense',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Title (e.g. Jio Recharge)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: 'Note (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Frequency',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['daily', 'weekly', 'monthly'].map((freq) {
                        final isSelected = selectedFrequency == freq;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setDialogState(() => selectedFrequency = freq),
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                freq[0].toUpperCase() + freq.substring(1),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Category',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: GridView.builder(
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
                                        color: cat['color'] as Color,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    cat['icon'],
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  Text(
                                    cat['name'],
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isSelected
                                          ? cat['color'] as Color
                                          : Colors.grey,
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
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty ||
                      amountController.text.trim().isEmpty)
                    return;
                  final now = DateTime.now();
                  final expense = RecurringExpenseModel(
                    id: const Uuid().v4(),
                    userId: '',
                    title: titleController.text.trim(),
                    amount: double.tryParse(amountController.text) ?? 0.0,
                    category: selectedCategory,
                    categoryIcon: selectedIcon,
                    note: noteController.text.trim(),
                    frequency: selectedFrequency,
                    startDate: now,
                    nextDueDate: now,
                    isActive: true,
                  );
                  await _service.addRecurringExpense(expense);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Recurring expense added! 🔄'),
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
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }
}
