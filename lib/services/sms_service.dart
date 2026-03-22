import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:uuid/uuid.dart';

class SmsService {
  final SmsQuery _query = SmsQuery();
  final _expenseService = ExpenseService();
  final _authService = AuthService();

  // Initialize and listen for SMS
  Future<void> initialize() async {
    // SMS reading handled via scanRecentSms
  }

  // Parse SMS and extract transaction details
  Map<String, dynamic>? parseSms(String body) {
    body = body.toLowerCase();

    // Check if it's a payment SMS
    final isPayment =
        body.contains('paid') ||
        body.contains('debited') ||
        body.contains('transferred') ||
        body.contains('sent') ||
        body.contains('payment of') ||
        body.contains('transaction of');

    final isIncome =
        body.contains('credited') ||
        body.contains('received') ||
        body.contains('deposited');

    if (!isPayment && !isIncome) return null;

    // Extract amount
    double? amount;
    final amountPatterns = [
      RegExp(r'rs\.?\s*(\d+(?:\.\d{1,2})?)'),
      RegExp(r'inr\s*(\d+(?:\.\d{1,2})?)'),
      RegExp(r'₹\s*(\d+(?:\.\d{1,2})?)'),
      RegExp(r'amount\s+(?:of\s+)?(?:rs\.?\s*|inr\s*|₹\s*)(\d+(?:\.\d{1,2})?)'),
    ];

    for (final pattern in amountPatterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        amount = double.tryParse(match.group(1) ?? '');
        if (amount != null) break;
      }
    }

    if (amount == null || amount <= 0) return null;

    // Extract merchant/sender
    String title = 'SMS Transaction';
    final merchantPatterns = [
      RegExp(r'(?:to|at|from)\s+([a-z\s]+?)(?:\s+(?:via|on|for|ref|upi|id))'),
      RegExp(r'(?:paid to|transferred to)\s+([a-z\s]+?)(?:\s|$)'),
    ];

    for (final pattern in merchantPatterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        title = _capitalize(match.group(1)?.trim() ?? 'SMS Transaction');
        break;
      }
    }

    // Detect payment mode
    String paymentMode = 'upi';
    if (body.contains('credit card') || body.contains('debit card')) {
      paymentMode = 'card';
    } else if (body.contains('net banking') ||
        body.contains('neft') ||
        body.contains('imps')) {
      paymentMode = 'netbanking';
    } else if (body.contains('cash')) {
      paymentMode = 'cash';
    }

    // Detect category
    String category = _detectCategory(body, title);

    return {
      'amount': amount,
      'title': title,
      'type': isIncome ? 'income' : 'expense',
      'paymentMode': paymentMode,
      'category': category,
    };
  }

  String _detectCategory(String body, String title) {
    final text = '$body $title'.toLowerCase();
    if (text.contains(
      RegExp(
        r'zomato|swiggy|food|restaurant|cafe|hotel|lunch|dinner|breakfast',
      ),
    ))
      return 'Food';
    if (text.contains(
      RegExp(r'uber|ola|rapido|metro|bus|fuel|petrol|transport'),
    ))
      return 'Transport';
    if (text.contains(
      RegExp(r'grocery|bigbasket|blinkit|zepto|vegetables|milk'),
    ))
      return 'Groceries';
    if (text.contains(RegExp(r'amazon|flipkart|myntra|shopping|mall')))
      return 'Shopping';
    if (text.contains(
      RegExp(r'hospital|pharmacy|medical|doctor|health|medicine'),
    ))
      return 'Health';
    if (text.contains(
      RegExp(r'netflix|amazon prime|hotstar|movie|cinema|game'),
    ))
      return 'Entertainment';
    if (text.contains(RegExp(r'school|college|fees|education|course|tuition')))
      return 'Education';
    if (text.contains(RegExp(r'salary|payroll|income|credited')))
      return 'Salary';
    return 'Other';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Future<void> _processSms(String body, String sender) async {
    final parsed = parseSms(body);
    if (parsed == null) return;

    // Check if it's a bank SMS
    final bankSenders = [
      'gpay',
      'phonepe',
      'paytm',
      'axis',
      'hdfc',
      'sbi',
      'icici',
      'kotak',
      'yesbank',
      'upi',
    ];
    final isBankSms =
        bankSenders.any((bank) => sender.toLowerCase().contains(bank)) ||
        sender.startsWith('VM-') ||
        sender.startsWith('VK-') ||
        sender.startsWith('BP-') ||
        sender.startsWith('AD-');

    if (!isBankSms) return;

    final expense = ExpenseModel(
      id: const Uuid().v4(),
      userId: _authService.currentUser?.uid ?? '',
      title: parsed['title'],
      amount: parsed['amount'],
      category: parsed['category'],
      categoryIcon: '📱',
      note: 'Auto-detected from SMS',
      date: DateTime.now(),
      createdAt: DateTime.now(),
      type: parsed['type'],
      paymentMode: parsed['paymentMode'],
    );

    await _expenseService.addExpense(expense);
  }

  // Get recent bank SMS for manual scan
  Future<List<Map<String, dynamic>>> scanRecentSms() async {
    final messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
      count: 100,
    );

    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    List<Map<String, dynamic>> detected = [];

    for (var sms in messages) {
      if (sms.date != null && sms.date!.isBefore(sevenDaysAgo)) continue;
      final parsed = parseSms(sms.body ?? '');
      if (parsed != null) {
        detected.add({
          ...parsed,
          'smsBody': sms.body,
          'sender': sms.sender,
          'date': sms.date ?? DateTime.now(),
        });
      }
    }
    return detected;
  }
}
