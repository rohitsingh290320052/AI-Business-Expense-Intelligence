// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'models/expense.dart';
import 'services/ai_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/cfo_chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const ExpenseStoryApp());
}

class ExpenseStoryApp extends StatelessWidget {
  const ExpenseStoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExpenseStory',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // In production, use Isar DB. For demo, using in-memory list.
  final List<Expense> _expenses = _generateSampleExpenses();
  final _aiService = AIService();

  void _addExpense(Expense expense) {
    setState(() => _expenses.insert(0, expense));
  }

  void _openAddExpense({bool withCamera = false}) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => AddExpenseScreen(
          aiService: _aiService,
          onSave: _addExpense,
          startWithCamera: withCamera,
        ),
        transitionsBuilder: (_, anim, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        expenses: _expenses,
        onAddExpense: _openAddExpense,
        onScanReceipt: () => _openAddExpense(withCamera: true),
      ),
      ReportsScreen(
        aiService: _aiService,
        expenses: _expenses,
      ),
      CFOChatScreen(
        aiService: _aiService,
        expenses: _expenses,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _openAddExpense,
              backgroundColor: AppColors.gold,
              elevation: 0,
              child: const Icon(Icons.add_rounded,
                  color: AppColors.background, size: 28),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: Color(0xFF2A2A3E), width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.grid_view_rounded, 'Dashboard'),
              _navItem(1, Icons.bar_chart_rounded, 'Reports'),
              const SizedBox(width: 56), // FAB space
              _navItem(2, Icons.psychology_outlined, 'AI CFO'),
              _navItem(3, Icons.person_outline_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 3) return; // Profile placeholder
        HapticFeedback.selectionClick();
        setState(() => _currentIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.goldGlow : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? AppColors.gold
                  : AppColors.textMuted,
            ),
            const SizedBox(height: 2),
            Text(
              label,
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
    );
  }
}

/// Generate realistic sample data for demo purposes
List<Expense> _generateSampleExpenses() {
  final now = DateTime.now();
  return [
    Expense()
      ..title = 'AWS EC2 Instance'
      ..amount = 12450
      ..currency = 'INR'
      ..category = 'software'
      ..date = now.subtract(const Duration(days: 1))
      ..vendor = 'Amazon Web Services'
      ..isTaxDeductible = true
      ..taxDeductionReason = 'Business infrastructure cost - GST deductible'
      ..aiInsight =
          'Consider Reserved Instances to save up to 40% on this monthly AWS bill.'
      ..paymentMethod = 'card'
      ..createdAt = DateTime.now(),
    Expense()
      ..title = 'Team Lunch'
      ..amount = 3200
      ..currency = 'INR'
      ..category = 'food'
      ..date = now.subtract(const Duration(days: 2))
      ..vendor = 'Barbeque Nation'
      ..isTaxDeductible = true
      ..taxDeductionReason = 'Business entertainment expense'
      ..aiInsight =
          'Business meals are 50% deductible under Indian IT Act. Keep the receipt.'
      ..paymentMethod = 'upi'
      ..createdAt = DateTime.now(),
    Expense()
      ..title = 'Figma Pro Plan'
      ..amount = 1650
      ..currency = 'INR'
      ..category = 'software'
      ..date = now.subtract(const Duration(days: 3))
      ..vendor = 'Figma Inc'
      ..isTaxDeductible = true
      ..taxDeductionReason = 'Design software subscription'
      ..aiInsight =
          'Annual Figma billing would save you ₹4,500/year vs monthly payments.'
      ..paymentMethod = 'card'
      ..createdAt = DateTime.now(),
    Expense()
      ..title = 'Office Supplies'
      ..amount = 870
      ..currency = 'INR'
      ..category = 'office'
      ..date = now.subtract(const Duration(days: 5))
      ..vendor = 'Amazon'
      ..isTaxDeductible = false
      ..aiInsight = 'Consider bulk purchasing office supplies quarterly to reduce costs.'
      ..paymentMethod = 'upi'
      ..createdAt = DateTime.now(),
    Expense()
      ..title = 'Google Workspace'
      ..amount = 2100
      ..currency = 'INR'
      ..category = 'software'
      ..date = now.subtract(const Duration(days: 7))
      ..vendor = 'Google LLC'
      ..isTaxDeductible = true
      ..taxDeductionReason = 'Business communication tools'
      ..aiInsight =
          'Google Workspace is fully deductible. Upgrade to Business Plus for advanced security.'
      ..paymentMethod = 'card'
      ..isAnomalous = false
      ..createdAt = DateTime.now(),
    Expense()
      ..title = 'Flight to Mumbai'
      ..amount = 8900
      ..currency = 'INR'
      ..category = 'travel'
      ..date = now.subtract(const Duration(days: 10))
      ..vendor = 'IndiGo Airlines'
      ..isTaxDeductible = true
      ..taxDeductionReason = 'Business travel expense'
      ..aiInsight =
          'Book 3+ weeks in advance for the same route to save ~35% on airfare.'
      ..paymentMethod = 'card'
      ..isAnomalous = true
      ..anomalyReason =
          'Unusually high travel expense compared to your monthly average of ₹3,200.'
      ..createdAt = DateTime.now(),
    Expense()
      ..title = 'LinkedIn Premium'
      ..amount = 2600
      ..currency = 'INR'
      ..category = 'marketing'
      ..date = now.subtract(const Duration(days: 12))
      ..vendor = 'LinkedIn'
      ..isTaxDeductible = true
      ..taxDeductionReason = 'Business development and recruitment tool'
      ..aiInsight =
          'Track your LinkedIn ROI: calculate leads generated per ₹2,600 spend.'
      ..paymentMethod = 'card'
      ..createdAt = DateTime.now(),
    Expense()
      ..title = 'Electricity Bill'
      ..amount = 4200
      ..currency = 'INR'
      ..category = 'utilities'
      ..date = now.subtract(const Duration(days: 14))
      ..vendor = 'BSES Rajdhani'
      ..isTaxDeductible = false
      ..aiInsight =
          'If you work from home, 30% of electricity can be claimed as business expense.'
      ..paymentMethod = 'netbanking'
      ..createdAt = DateTime.now(),
  ];
}
