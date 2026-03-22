import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/models/goal_model.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;

  CollectionReference get _collection => _firestore
      .collection('users')
      .doc(_authService.currentUser!.uid)
      .collection('goals');

  final List<Map<String, dynamic>> _goalTemplates = [
    {'name': 'New Vehicle', 'icon': '🚗', 'color': '0xFF0EA5E9'},
    {'name': 'New Home', 'icon': '🏠', 'color': '0xFFF59E0B'},
    {'name': 'Holiday Trip', 'icon': '✈️', 'color': '0xFF10B981'},
    {'name': 'Education', 'icon': '🎓', 'color': '0xFF8B5CF6'},
    {'name': 'Emergency Fund', 'icon': '🛡️', 'color': '0xFFEC4899'},
    {'name': 'Health Care', 'icon': '🏥', 'color': '0xFFEF4444'},
    {'name': 'New Phone', 'icon': '📱', 'color': '0xFF6366F1'},
    {'name': 'Wedding', 'icon': '💍', 'color': '0xFFE879F9'},
    {'name': 'Business', 'icon': '💼', 'color': '0xFF14B8A6'},
    {'name': 'Custom', 'icon': '🎯', 'color': '0xFF2563EB'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          '🎯 Savings Goals',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGoalDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _collection.orderBy('createdAt', descending: false).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 16),
                  const Text(
                    'No goals yet!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set a savings goal and track\nyour progress towards it!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final goal = GoalModel.fromMap(
                docs[index].data() as Map<String, dynamic>,
              );
              return _buildGoalCard(goal, docs[index].id);
            },
          );
        },
      ),
    );
  }

  Widget _buildGoalCard(GoalModel goal, String docId) {
    final color = Color(int.parse(goal.color));
    final daysLeft = goal.deadline.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Text(goal.icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        goal.isCompleted
                            ? '🎉 Goal Completed!'
                            : '$daysLeft days left',
                        style: TextStyle(
                          color: goal.isCompleted
                              ? AppColors.secondary
                              : Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${goal.savedAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'of ₹${goal.targetAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Progress
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(goal.progress * 100).toStringAsFixed(1)}% achieved',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '₹${goal.remaining.toStringAsFixed(0)} remaining',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: goal.progress,
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddMoneyDialog(goal, docId),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Money'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _deleteGoal(docId, goal.name),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddGoalDialog() async {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    final savedController = TextEditingController(text: '0');
    final noteController = TextEditingController();
    DateTime selectedDeadline = DateTime.now().add(const Duration(days: 365));
    String selectedIcon = '🎯';
    String selectedColor = '0xFF2563EB';
    String? selectedTemplate;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              '🎯 New Savings Goal',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Templates
                    const Text(
                      'Choose a goal:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: GridView.builder(
                        scrollDirection: Axis.horizontal,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 1,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.8,
                            ),
                        itemCount: _goalTemplates.length,
                        itemBuilder: (context, index) {
                          final template = _goalTemplates[index];
                          final isSelected =
                              selectedTemplate == template['name'];
                          final color = Color(int.parse(template['color']));
                          return GestureDetector(
                            onTap: () => setDialogState(() {
                              selectedTemplate = template['name'];
                              selectedIcon = template['icon'];
                              selectedColor = template['color'];
                              if (template['name'] != 'Custom') {
                                nameController.text = template['name'];
                              }
                            }),
                            child: Container(
                              width: 80,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withOpacity(0.2)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(color: color, width: 2)
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    template['icon'],
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    template['name'],
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isSelected ? color : Colors.grey,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Goal Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: targetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Target Amount (₹)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: savedController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Already Saved (₹)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDeadline,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDeadline = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Deadline: ${DateFormat('MMM d, yyyy').format(selectedDeadline)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
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
                  if (nameController.text.trim().isEmpty ||
                      targetController.text.trim().isEmpty)
                    return;
                  final id = const Uuid().v4();
                  final goal = GoalModel(
                    id: id,
                    userId: _authService.currentUser!.uid,
                    name: nameController.text.trim(),
                    targetAmount: double.tryParse(targetController.text) ?? 0.0,
                    savedAmount: double.tryParse(savedController.text) ?? 0.0,
                    deadline: selectedDeadline,
                    icon: selectedIcon,
                    color: selectedColor,
                    note: noteController.text.trim(),
                    createdAt: DateTime.now(),
                  );
                  await _collection.doc(id).set(goal.toMap());
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Goal created! 🎯'),
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
                child: const Text('Create Goal'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddMoneyDialog(GoalModel goal, String docId) async {
    final amountController = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add Money to ${goal.name}'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Amount (₹)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount <= 0) return;
              final newSaved = goal.savedAmount + amount;
              await _collection.doc(docId).update({'savedAmount': newSaved});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('₹${amount.toStringAsFixed(0)} added! 💰'),
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
      ),
    );
  }

  Future<void> _deleteGoal(String docId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Delete "$name"?'),
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
      await _collection.doc(docId).delete();
    }
  }
}
