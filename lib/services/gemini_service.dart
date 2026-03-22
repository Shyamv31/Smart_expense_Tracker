import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:typed_data';

class GeminiService {
  static const _apiKey = '';

  GenerativeModel get _model =>
      GenerativeModel(model: 'gemini-1.5-flash-002', apiKey: _apiKey);

  Future<Map<String, dynamic>> scanReceipt(
    Uint8List imageBytes, [
    String mimeType = 'image/jpeg',
  ]) async {
    try {
      final prompt = """
Look at this receipt/bill image carefully.
Extract the information and respond ONLY with this exact JSON format:
{
  "title": "shop name or expense name",
  "amount": 150.00,
  "category": "Food",
  "note": "items bought"
}
Rules:
- title: name of shop, restaurant or what was bought
- amount: total amount as a number only, no symbols
- category: MUST be exactly one of these words only: Food, Transport, Groceries, Shopping, Health, Entertainment, Education, Other
- note: brief description
Respond with ONLY the JSON. No explanation. No markdown. No backticks.
""";

      final response = await _model.generateContent([
        Content.multi([TextPart(prompt), DataPart(mimeType, imageBytes)]),
      ]);

      String text = response.text ?? "";
      print("DEBUG RAW: \$text");
      text = text.replaceAll("```json", "").replaceAll("```", "").trim();
      print("DEBUG CLEANED: \$text");

      final jsonStart = text.indexOf("{");
      final jsonEnd = text.lastIndexOf("}") + 1;
      if (jsonStart == -1 || jsonEnd == 0) return _defaultResponse();

      final jsonStr = text.substring(jsonStart, jsonEnd);

      final title = _extractString(jsonStr, "title");
      final amountStr = _extractNumber(jsonStr, "amount");
      String category = _extractString(jsonStr, "category");
      final note = _extractString(jsonStr, "note");

      const validCategories = [
        "Food",
        "Transport",
        "Groceries",
        "Shopping",
        "Health",
        "Entertainment",
        "Education",
        "Other",
      ];
      if (!validCategories.contains(category)) {
        category = _guessCategory(title, note);
      }

      print(
        "DEBUG parsed: title=\$title amount=\$amountStr category=\$category note=\$note",
      );

      return {
        "title": title,
        "amount": double.tryParse(amountStr) ?? 0.0,
        "category": category,
        "note": note,
      };
    } catch (e) {
      print("SCAN ERROR: $e");
      return _defaultResponse();
    }
  }

  Future<String> getSpendingAdvice(
    Map<String, double> categoryTotals,
    double totalSpent,
    double budget,
  ) async {
    try {
      final prompt = """
You are a friendly financial advisor. Analyze this monthly spending and give 3 short, practical tips.

Total spent: ₹\${totalSpent.toStringAsFixed(0)}
Monthly budget: ₹\${budget.toStringAsFixed(0)}
Spending by category: \${categoryTotals.entries.map((e) => "\${e.key}: ₹\${e.value.toStringAsFixed(0)}").join(", ")}

Give advice in simple English. Be friendly and encouraging. Keep each tip to 1-2 sentences.
Format as:
1. [tip]
2. [tip]
3. [tip]
""";
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ??
          "Keep tracking your expenses daily for better financial health!";
    } catch (e) {
      return "Keep tracking your expenses daily for better financial health!";
    }
  }

  Future<String> getPrediction(
    List<Map<String, dynamic>> recentExpenses,
  ) async {
    try {
      final expenseSummary = recentExpenses
          .take(10)
          .map((e) => "${e['category']}: ₹${e['amount']}")
          .join(", ");

      final prompt = """
Based on these recent expenses: \$expenseSummary

Predict the likely spending for next week and give 1 short insight.
Keep it under 2 sentences. Be friendly and specific with numbers.
""";
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ??
          "Based on your spending pattern, try to save more this week!";
    } catch (e) {
      return "Based on your spending pattern, try to save more this week!";
    }
  }

  Future<String> chat(String prompt) async {
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "Sorry, I could not process that request.";
    } catch (e) {
      print("CHAT ERROR: $e");
      return "Sorry, something went wrong. Please try again!";
    }
  }

  String _extractString(String json, String key) {
    final regex = RegExp('"\$key"\\s*:\\s*"([^"]*)"');
    final match = regex.firstMatch(json);
    return match?.group(1)?.trim() ?? "";
  }

  String _extractNumber(String json, String key) {
    final regex = RegExp('"\$key"\\s*:\\s*([\\d.]+)');
    final match = regex.firstMatch(json);
    return match?.group(1)?.trim() ?? "0";
  }

  String _guessCategory(String title, String note) {
    final text = "\${title.toLowerCase()} \${note.toLowerCase()}";
    if (text.contains(
      RegExp(
        r"food|restaurant|hotel|cafe|lunch|dinner|breakfast|swiggy|zomato|biryani|pizza|burger",
      ),
    ))
      return "Food";
    if (text.contains(
      RegExp(r"bus|train|metro|cab|uber|ola|petrol|fuel|transport|auto|taxi"),
    ))
      return "Transport";
    if (text.contains(
      RegExp(
        r"grocery|vegetable|fruit|supermarket|bigbasket|blinkit|milk|rice",
      ),
    ))
      return "Groceries";
    if (text.contains(
      RegExp(r"shop|mall|cloth|amazon|flipkart|fashion|dress|shirt"),
    ))
      return "Shopping";
    if (text.contains(
      RegExp(r"hospital|medical|pharmacy|doctor|medicine|health|clinic"),
    ))
      return "Health";
    if (text.contains(RegExp(r"movie|cinema|game|entertainment|netflix|sport")))
      return "Entertainment";
    if (text.contains(
      RegExp(r"school|college|book|course|education|tuition|fee"),
    ))
      return "Education";
    return "Other";
  }

  Map<String, dynamic> _defaultResponse() {
    return {"title": "", "amount": 0.0, "category": "Other", "note": ""};
  }
}
