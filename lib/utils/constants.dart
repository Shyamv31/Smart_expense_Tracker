import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2563EB);
  static const secondary = Color(0xFF10B981);
  static const background = Color(0xFFF1F5F9);
  static const card = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF1E293B);
  static const textLight = Color(0xFF64748B);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);

  // Category Colors
  static const food = Color(0xFFFF6B6B);
  static const transport = Color(0xFF4ECDC4);
  static const groceries = Color(0xFF45B7D1);
  static const shopping = Color(0xFF96CEB4);
  static const health = Color(0xFFFF8B94);
  static const entertainment = Color(0xFFA8E6CF);
  static const education = Color(0xFFFFD93D);
  static const other = Color(0xFFB8B8B8);
}

class AppCategories {
  static const List<Map<String, dynamic>> categories = [
    {'name': 'Food', 'icon': '🍔', 'color': AppColors.food},
    {'name': 'Transport', 'icon': '🚗', 'color': AppColors.transport},
    {'name': 'Groceries', 'icon': '🛒', 'color': AppColors.groceries},
    {'name': 'Shopping', 'icon': '🛍️', 'color': AppColors.shopping},
    {'name': 'Health', 'icon': '💊', 'color': AppColors.health},
    {'name': 'Entertainment', 'icon': '🎬', 'color': AppColors.entertainment},
    {'name': 'Education', 'icon': '📚', 'color': AppColors.education},
    {'name': 'Other', 'icon': '📦', 'color': AppColors.other},
  ];
}

class IncomeCategories {
  static const List<Map<String, dynamic>> categories = [
    {'name': 'Salary', 'icon': '💼', 'color': Color(0xFF10B981)},
    {'name': 'Freelance', 'icon': '💻', 'color': Color(0xFF0EA5E9)},
    {'name': 'Business', 'icon': '🏪', 'color': Color(0xFF8B5CF6)},
    {'name': 'Investment', 'icon': '📈', 'color': Color(0xFFF59E0B)},
    {'name': 'Gift', 'icon': '🎁', 'color': Color(0xFFEC4899)},
    {'name': 'Refund', 'icon': '↩️', 'color': Color(0xFF06B6D4)},
    {'name': 'Other', 'icon': '💰', 'color': Color(0xFF6B7280)},
  ];
}

class AppStrings {
  static const appName = 'Smart Expense Tracker';
  static const currency = '₹';
}
