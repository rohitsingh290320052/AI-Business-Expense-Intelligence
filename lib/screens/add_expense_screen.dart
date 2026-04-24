// lib/screens/add_expense_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/expense.dart';
import '../services/ai_service.dart';
import '../widgets/glass_card.dart';

class AddExpenseScreen extends StatefulWidget {
  final AIService aiService;
  final Function(Expense) onSave;
  final bool startWithCamera;

  const AddExpenseScreen({
    super.key,
    required this.aiService,
    required this.onSave,
    this.startWithCamera = false,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _vendorController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedCategory = 'other';
  DateTime _selectedDate = DateTime.now();
  String _paymentMethod = 'upi';
  bool _isTaxDeductible = false;
  String? _taxReason;
  String? _aiInsight;
  File? _receiptImage;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  late AnimationController _shimmerController;

  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    if (widget.startWithCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scanReceipt());
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _vendorController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _scanReceipt() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final xFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (xFile == null) return;

    setState(() {
      _receiptImage = File(xFile.path);
      _isAnalyzing = true;
    });

    try {
      final result = await widget.aiService.analyzeReceipt(_receiptImage!);
      setState(() {
        _titleController.text = result['title'] ?? '';
        _amountController.text =
            (result['amount'] as num?)?.toStringAsFixed(0) ?? '';
        _vendorController.text = result['vendor'] ?? '';
        _selectedCategory = result['category'] ?? 'other';
        _paymentMethod = result['paymentMethod'] ?? 'upi';
        _isTaxDeductible = result['isTaxDeductible'] ?? false;
        _taxReason = result['taxDeductionReason'];
        _aiInsight = result['aiInsight'];
        if (result['date'] != null) {
          try {
            _selectedDate = DateTime.parse(result['date']);
          } catch (_) {}
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI analysis failed. Please fill manually.',
                style: GoogleFonts.inter()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Scan Receipt',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI will automatically extract all details',
              style: GoogleFonts.inter(
                  color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _sourceButton(
                    'Camera',
                    Icons.camera_alt_outlined,
                    AppColors.gold,
                    () => Navigator.pop(context, ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _sourceButton(
                    'Gallery',
                    Icons.photo_library_outlined,
                    AppColors.teal,
                    () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sourceButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _analyzeManually() async {
    if (_titleController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _vendorController.text.isEmpty) return;

    setState(() => _isAnalyzing = true);
    try {
      final result = await widget.aiService.analyzeExpense(
        title: _titleController.text,
        amount: double.tryParse(_amountController.text) ?? 0,
        vendor: _vendorController.text,
        description: _descController.text,
      );
      setState(() {
        _selectedCategory = result['category'] ?? _selectedCategory;
        _isTaxDeductible = result['isTaxDeductible'] ?? false;
        _taxReason = result['taxDeductionReason'];
        _aiInsight = result['aiInsight'];
      });
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();

    final expense = Expense()
      ..title = _titleController.text
      ..amount = double.tryParse(_amountController.text) ?? 0
      ..currency = 'INR'
      ..category = _selectedCategory
      ..date = _selectedDate
      ..vendor = _vendorController.text
      ..description = _descController.text
      ..receiptImagePath = _receiptImage?.path
      ..isTaxDeductible = _isTaxDeductible
      ..taxDeductionReason = _taxReason
      ..aiInsight = _aiInsight
      ..paymentMethod = _paymentMethod
      ..createdAt = DateTime.now();

    widget.onSave(expense);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'Add Expense',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary, size: 20),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: Text(
              'Save',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReceiptSection(),
              const SizedBox(height: 20),
              if (_isAnalyzing) _buildAnalyzingCard(),
              if (_aiInsight != null && !_isAnalyzing) _buildAIInsightCard(),
              const SizedBox(height: 4),
              _buildFormFields(),
              const SizedBox(height: 20),
              _buildCategorySelector(),
              const SizedBox(height: 20),
              _buildPaymentMethod(),
              const SizedBox(height: 20),
              _buildTaxSection(),
              const SizedBox(height: 32),
              _buildSaveButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptSection() {
    return FadeInDown(
      child: GestureDetector(
        onTap: _scanReceipt,
        child: Container(
          width: double.infinity,
          height: _receiptImage != null ? 220 : 120,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _receiptImage != null
                  ? AppColors.gold.withOpacity(0.4)
                  : const Color(0xFF2A2A3E),
              style: _receiptImage != null
                  ? BorderStyle.solid
                  : BorderStyle.solid,
            ),
          ),
          child: _receiptImage != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(
                        _receiptImage!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.background.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.edit_outlined,
                            size: 16, color: AppColors.gold),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.goldGlow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.document_scanner_outlined,
                          color: AppColors.gold, size: 28),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Scan Receipt with AI',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Auto-fills all fields instantly',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAnalyzingCard() {
    return FadeIn(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.goldGlow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'AI is analyzing your receipt...',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.gold,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIInsightCard() {
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.teal.withOpacity(0.08),
              AppColors.teal.withOpacity(0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.teal.withOpacity(0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.psychology_outlined,
                color: AppColors.teal, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Insight',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.teal,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _aiInsight!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return FadeInUp(
      delay: const Duration(milliseconds: 100),
      child: GlassCard(
        child: Column(
          children: [
            _inputField(
              controller: _titleController,
              label: 'Expense Title',
              hint: 'e.g. Team lunch at Barbeque Nation',
              icon: Icons.receipt_outlined,
              onChanged: (_) {},
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _inputField(
                    controller: _amountController,
                    label: 'Amount (₹)',
                    hint: '0',
                    icon: Icons.currency_rupee_rounded,
                    keyboardType: TextInputType.number,
                    onChanged: (_) {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: const Color(0xFF2A2A3E)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM d, y').format(_selectedDate),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _inputField(
              controller: _vendorController,
              label: 'Vendor / Merchant',
              hint: 'e.g. Swiggy, Amazon, Canva',
              icon: Icons.storefront_outlined,
              onChanged: (_) {},
            ),
            const SizedBox(height: 16),
            _inputField(
              controller: _descController,
              label: 'Description (Optional)',
              hint: 'Add context for better AI insights',
              icon: Icons.notes_outlined,
              maxLines: 2,
              onChanged: (_) {},
            ),
            const SizedBox(height: 8),
            if (!_isAnalyzing && _aiInsight == null)
              GestureDetector(
                onTap: _analyzeManually,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.tealDim,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.teal.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.psychology_outlined,
                            size: 16, color: AppColors.teal),
                        const SizedBox(width: 8),
                        Text(
                          'Get AI Insights',
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.teal,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon:
                Icon(icon, size: 18, color: AppColors.textMuted),
          ),
          validator: (v) =>
              v?.isEmpty == true ? 'Required' : null,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExpenseCategory.values.map((cat) {
              final isSelected = _selectedCategory == cat.name;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat.name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.goldGlow
                        : AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.gold
                          : const Color(0xFF2A2A3E),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(cat.emoji,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        cat.label,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          color: isSelected
                              ? AppColors.gold
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    final methods = [
      ('upi', 'UPI', Icons.phone_android_outlined),
      ('card', 'Card', Icons.credit_card_outlined),
      ('cash', 'Cash', Icons.money_outlined),
      ('netbanking', 'Net Banking', Icons.account_balance_outlined),
    ];

    return FadeInUp(
      delay: const Duration(milliseconds: 250),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Method',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: methods.map((m) {
              final isSelected = _paymentMethod == m.$1;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _paymentMethod = m.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.goldGlow
                            : AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.gold
                              : const Color(0xFF2A2A3E),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(m.$3,
                              size: 18,
                              color: isSelected
                                  ? AppColors.gold
                                  : AppColors.textMuted),
                          const SizedBox(height: 4),
                          Text(
                            m.$2,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              color: isSelected
                                  ? AppColors.gold
                                  : AppColors.textMuted,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxSection() {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: GlassCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tax Deductible',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (_taxReason != null)
                    Text(
                      _taxReason!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    )
                  else
                    Text(
                      'Under Indian GST / IT Act',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            Switch(
              value: _isTaxDeductible,
              onChanged: (v) => setState(() => _isTaxDeductible = v),
              activeColor: AppColors.teal,
              inactiveThumbColor: AppColors.textMuted,
              inactiveTrackColor: AppColors.surfaceElevated,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.background,
                  ),
                )
              : Text(
                  'Save Expense',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.background,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.gold,
            surface: AppColors.surfaceCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }
}
