import 'package:flutter/material.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/utils/constants.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:image_picker/image_picker.dart';                        
import 'package:expense_tracker/services/gemini_service.dart';          

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _expenseService = ExpenseService();
  final SpeechToText _speech = SpeechToText();

  String _selectedCategory = 'Food';
  String _selectedIcon = '🍔';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;

  // Voice
  bool _isListening = false;
  bool _speechAvailable = false;
  String _voiceLocale = 'en_IN'; // Default English
  String _voiceStatus = '';

  // Receipt Scanner   ← ADD FROM HERE
  final _geminiService = GeminiService();
  final _imagePicker = ImagePicker();
  bool _isScanningReceipt = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        setState(() => _voiceStatus = status);
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        setState(() {
          _isListening = false;
          _voiceStatus = 'Error: ${error.errorMsg}';
        });
      },
    );
    setState(() {});
  }

  Future<void> _startListening(String field) async {
    if (!_speechAvailable) {
      setState(() => _voiceStatus = 'Speech not available');
      return;
    }
    setState(() {
      _isListening = true;
      _voiceStatus = 'Listening...';
    });
    await _speech.listen(
      localeId: _voiceLocale,
      onResult: (result) {
        final text = result.recognizedWords;
        setState(() {
          if (field == 'title') {
            _titleController.text = text;
          } else if (field == 'amount') {
            // Extract numbers from voice
            final numbers = RegExp(r'\d+').firstMatch(text);
            if (numbers != null) {
              _amountController.text = numbers.group(0)!;
            }
          } else if (field == 'note') {
            _noteController.text = text;
          }
        });
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  // ← ADD FROM HERE
  Future<void> _scanReceipt() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => _isScanningReceipt = true);
final bytes = await picked.readAsBytes();
    final mimeType = picked.path.toLowerCase().endsWith('.png') 
        ? 'image/png' 
        : 'image/jpeg';
    final result = await _geminiService.scanReceipt(bytes, mimeType);
    print('DEBUG RESULT: $result');
    setState(() {
      _isScanningReceipt = false;
      if (result['title'] != '') {
        _titleController.text = result['title'];
      }
      if (result['amount'] != 0.0) {
        _amountController.text = result['amount'].toStringAsFixed(0);
      }
      if (result['note'] != '') {
        _noteController.text = result['note'];
      }
      final category = result['category'];
      final cat = AppCategories.categories.firstWhere(
        (c) => c['name'] == category,
        orElse: () => AppCategories.categories.last,
      );
      _selectedCategory = cat['name'];
      _selectedIcon = cat['icon'];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt scanned successfully! ✅'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveExpense() async {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill title and amount');
      return;
    }
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final expense = ExpenseModel(
        id: const Uuid().v4(),
        userId: '',
        title: _titleController.text.trim(),
        amount: amount,
        category: _selectedCategory,
        categoryIcon: _selectedIcon,
        note: _noteController.text.trim(),
        date: _selectedDate,
        createdAt: DateTime.now(),
      );
      await _expenseService.addExpense(expense);
      Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to save. Try again.');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Add Expense',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
                    // Camera/Receipt Scanner button  ← ADD FROM HERE
          if (_isScanningReceipt)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            )
          else
            IconButton(
              onPressed: _scanReceipt,
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              tooltip: 'Scan Receipt',
            ),
          // ← ADD UNTIL HERE
        
          // Language Toggle
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _voiceLocale =
                      _voiceLocale == 'en_IN' ? 'ta_IN' : 'en_IN';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _voiceLocale == 'en_IN'
                          ? '🇬🇧 Switched to English'
                          : '🇮🇳 Tamil மொழிக்கு மாறியது',
                    ),
                    duration: const Duration(seconds: 1),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _voiceLocale == 'en_IN' ? '🇬🇧 EN' : '🇮🇳 TA',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Voice Status Banner
              if (_isListening)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.secondary),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mic, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Text(
                        _voiceLocale == 'en_IN'
                            ? '🎤 Listening in English...'
                            : '🎤 தமிழில் கேட்கிறேன்...',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              // Amount Input
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
                  children: [
                    const Text(
                      'Amount (₹)',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '0.00',
                              hintStyle: TextStyle(
                                  color: Colors.white38, fontSize: 40),
                            ),
                          ),
                        ),
                        // Voice button for amount
                        GestureDetector(
                          onTap: () => _isListening
                              ? _stopListening()
                              : _startListening('amount'),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isListening ? Icons.stop : Icons.mic,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Details Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Title with voice
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g. Lunch, Bus ticket...',
                        prefixIcon: const Icon(Icons.title,
                            color: AppColors.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isListening ? Icons.stop : Icons.mic,
                            color: _isListening
                                ? AppColors.error
                                : AppColors.primary,
                          ),
                          onPressed: () => _isListening
                              ? _stopListening()
                              : _startListening('title'),
                        ),
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

                    const SizedBox(height: 16),

                    // Date Picker
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: AppColors.primary),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('EEEE, MMM d yyyy')
                                  .format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Note with voice
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Note (optional)',
                        hintText: 'Add a note...',
                        prefixIcon: const Icon(Icons.note_outlined,
                            color: AppColors.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isListening ? Icons.stop : Icons.mic,
                            color: _isListening
                                ? AppColors.error
                                : AppColors.primary,
                          ),
                          onPressed: () => _isListening
                              ? _stopListening()
                              : _startListening('note'),
                        ),
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
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Category Selector
              const Text(
                'Select Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: AppCategories.categories.length,
                itemBuilder: (context, index) {
                  final cat = AppCategories.categories[index];
                  final isSelected = _selectedCategory == cat['name'];
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedCategory = cat['name'];
                      _selectedIcon = cat['icon'];
                    }),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (cat['color'] as Color).withOpacity(0.2)
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(
                                color: cat['color'] as Color, width: 2)
                            : Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(cat['icon'],
                              style: const TextStyle(fontSize: 26)),
                          const SizedBox(height: 4),
                          Text(
                            cat['name'],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? cat['color'] as Color
                                  : AppColors.textLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ],

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save),
                            SizedBox(width: 8),
                            Text(
                              'Save Expense',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _speech.stop();
    super.dispose();
  }
}