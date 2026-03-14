import 'package:provider/provider.dart';
import 'package:expense_tracker/services/theme_provider.dart';
import 'package:expense_tracker/services/gemini_service.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/screens/login_screen.dart';
import 'package:expense_tracker/utils/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  final _budgetController = TextEditingController();
  final _geminiService = GeminiService();
  final _expenseService = ExpenseService();
  String _userName = '';
  String _userEmail = '';
  String _aiAdvice = '';
  String _aiPrediction = '';
  double _monthlyBudget = 0.0;
  bool _isLoading = false;
  bool _isLoadingAdvice = false;
  bool _isLoadingPrediction = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    setState(() {
      _userName = doc['name'] ?? 'User';
      _userEmail = user.email ?? '';
      _monthlyBudget = (doc['monthlyBudget'] ?? 0.0).toDouble();
      _budgetController.text =
          _monthlyBudget > 0 ? _monthlyBudget.toStringAsFixed(0) : '';
    });
  }

  Future<void> _getAIAdvice() async {
  setState(() => _isLoadingAdvice = true);
  
  // Get category totals
  final expenses = await _expenseService.getExpenses().first;
  final now = DateTime.now();
  final monthExpenses = expenses.where((e) =>
      e.date.month == now.month && e.date.year == now.year).toList();
  
  Map<String, double> categoryTotals = {};
  for (var e in monthExpenses) {
    categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
  }
  final totalSpent = monthExpenses.fold(0.0, (sum, e) => sum + e.amount);
  
  final advice = await _geminiService.getSpendingAdvice(
    categoryTotals, totalSpent, _monthlyBudget);
  
  setState(() {
    _aiAdvice = advice;
    _isLoadingAdvice = false;
  });
}

  Future<void> _getAIPrediction() async {
  setState(() => _isLoadingPrediction = true);
  
  final expenses = await _expenseService.getExpenses().first;
  final recentExpenses = expenses.take(10).map((e) => {
    'category': e.category,
    'amount': e.amount,
    'date': e.date.toIso8601String(),
  }).toList();
  
  final prediction = await _geminiService.getPrediction(recentExpenses);
  
  setState(() {
    _aiPrediction = prediction;
    _isLoadingPrediction = false;
  });
}

  Future<void> _saveBudget() async {
    final budget = double.tryParse(_budgetController.text);
    if (budget == null || budget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid budget amount')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .update({'monthlyBudget': budget});
    setState(() {
      _monthlyBudget = budget;
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Budget saved successfully! ✅'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _authService.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: Text(
                      _userName.isNotEmpty
                          ? _userName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _userEmail,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

// Dark Mode Toggle
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(16),
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
          color: const Color(0xFF8B5CF6).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.dark_mode,
          color: Color(0xFF8B5CF6),
        ),
      ),
      const SizedBox(width: 16),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dark Mode',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            Text(
              'Switch between light and dark theme',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => Switch(
          value: themeProvider.isDarkMode,
          onChanged: (_) => themeProvider.toggleTheme(),
          activeColor: const Color(0xFF8B5CF6),
        ),
      ),
    ],
  ),
),

  const SizedBox(height: 16),

// Daily Reminder Toggle
StatefulBuilder(
  builder: (context, setLocalState) {
    return FutureBuilder<bool>(
      future: NotificationService().isReminderEnabled(),
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? false;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.notifications_active,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Reminder',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Get reminded to log expenses daily',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isEnabled,
                    onChanged: (value) async {
                      await NotificationService().setReminderEnabled(value);
                      if (value) {
                        final hour = await NotificationService().getReminderHour();
                        final minute = await NotificationService().getReminderMinute();
                        await NotificationService().scheduleDailyReminder(hour, minute);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Daily reminder enabled! 🔔'),
                            backgroundColor: AppColors.secondary,
                          ),
                        );
                      } else {
                        await NotificationService().cancelReminder();
                      }
                      setLocalState(() {});
                      setState(() {});
                    },
                    activeColor: AppColors.secondary,
                  ),
                ],
              ),
              if (isEnabled) ...[
                const SizedBox(height: 16),
                FutureBuilder<int>(
                  future: NotificationService().getReminderHour(),
                  builder: (context, hourSnap) {
                    return FutureBuilder<int>(
                      future: NotificationService().getReminderMinute(),
                      builder: (context, minSnap) {
                        final hour = hourSnap.data ?? 20;
                        final minute = minSnap.data ?? 0;
                        final time = TimeOfDay(hour: hour, minute: minute);
                        return GestureDetector(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: time,
                            );
                            if (picked != null) {
                              await NotificationService().setReminderTime(
                                  picked.hour, picked.minute);
                              await NotificationService()
                                  .scheduleDailyReminder(
                                      picked.hour, picked.minute);
                              setLocalState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Reminder set for ${picked.format(context)}! ✅'),
                                  backgroundColor: AppColors.secondary,
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.secondary.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.access_time,
                                    color: AppColors.secondary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Remind me at: ${time.format(context)}',
                                  style: TextStyle(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.edit,
                                    color: AppColors.secondary, size: 16),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  },
),

const SizedBox(height: 8),
SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: () async {
      await NotificationService().testNotification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification in 10 seconds! ⏱️'),
          backgroundColor: AppColors.secondary,
        ),
      );
    },
    icon: const Icon(Icons.notification_add),
    label: const Text('Test (fires in 10 sec)'),
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),

            // Budget Section
            const Text(
              'Monthly Budget',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _monthlyBudget > 0
                        ? 'Current Budget: ₹${_monthlyBudget.toStringAsFixed(0)}'
                        : 'No budget set yet',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Set Monthly Budget (₹)',
                      prefixIcon: const Icon(Icons.account_balance_wallet,
                          color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveBudget,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text('Save Budget'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // App Info Section
            const Text(
              'App Info',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInfoTile(Icons.info_outline, 'Version', '1.0.0'),
                  _buildDivider(),
                  _buildInfoTile(
                      Icons.storage, 'Database', 'Firebase Firestore'),
                  _buildDivider(),
                  _buildInfoTile(Icons.cloud, 'Cloud Sync', 'Enabled ✅'),
                ],
              ),
            ),

            const SizedBox(height: 24),

// AI Section
const Text(
  '🤖 AI Assistant',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  ),
),
const SizedBox(height: 12),
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 8,
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Smart Advice
      SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: _isLoadingAdvice ? null : _getAIAdvice,
          icon: _isLoadingAdvice
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.lightbulb_outline),
          label: const Text('Get Smart Advice'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      if (_aiAdvice.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withOpacity(0.3),
            ),
          ),
          child: Text(
            _aiAdvice,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],

      const SizedBox(height: 16),

      // AI Prediction
      SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: _isLoadingPrediction ? null : _getAIPrediction,
          icon: _isLoadingPrediction
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.trending_up),
          label: const Text('Predict Next Week'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      if (_aiPrediction.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.secondary.withOpacity(0.3),
            ),
          ),
          child: Text(
            _aiPrediction,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    ],
  ),
),

const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey.shade200,
      indent: 16,
      endIndent: 16,
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }
}