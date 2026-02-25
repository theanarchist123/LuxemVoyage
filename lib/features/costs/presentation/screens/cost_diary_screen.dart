import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';

class CostDiaryScreen extends StatefulWidget {
  const CostDiaryScreen({super.key});

  @override
  State<CostDiaryScreen> createState() => _CostDiaryScreenState();
}

class ExpenseCategory {
  final String name;
  final IconData icon;
  final Color color;
  double amount;
  
  ExpenseCategory(this.name, this.icon, this.color, this.amount);
}

class _CostDiaryScreenState extends State<CostDiaryScreen> with SingleTickerProviderStateMixin {
  final List<ExpenseCategory> _categories = [
    ExpenseCategory('Accommodation', LucideIcons.hotel, const Color(0xFFE2B93B), 850),
    ExpenseCategory('Food & Dining', LucideIcons.utensilsCrossed, const Color(0xFF4DB6AC), 320),
    ExpenseCategory('Transport', LucideIcons.planeTakeoff, const Color(0xFF9575CD), 450),
    ExpenseCategory('Activities', LucideIcons.ticket, const Color(0xFFFF8A65), 210),
    ExpenseCategory('Shopping', LucideIcons.shoppingBag, const Color(0xFF64B5F6), 150),
  ];

  double get _totalSpent => _categories.fold(0, (sum, cat) => sum + cat.amount);
  final double _budget = 2500;

  bool _isAddingExpense = false;
  String _currentInput = '0';
  ExpenseCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories[1]; // default to Food
  }

  void _onNumpadTap(String value) {
    setState(() {
      if (value == 'C') {
        _currentInput = '0';
      } else if (value == 'DEL') {
        if (_currentInput.length > 1) {
          _currentInput = _currentInput.substring(0, _currentInput.length - 1);
        } else {
          _currentInput = '0';
        }
      } else if (value == '.') {
        if (!_currentInput.contains('.')) _currentInput += '.';
      } else {
        if (_currentInput == '0') {
          _currentInput = value;
        } else {
          // Limit to 2 decimal places if there is a dot
          if (_currentInput.contains('.')) {
             final parts = _currentInput.split('.');
             if (parts.length > 1 && parts[1].length >= 2) return;
          }
          if (_currentInput.length < 8) _currentInput += value;
        }
      }
    });
  }

  void _saveExpense() {
    final amount = double.tryParse(_currentInput) ?? 0;
    if (amount > 0 && _selectedCategory != null) {
      setState(() {
        _selectedCategory!.amount += amount;
        _isAddingExpense = false;
        _currentInput = '0';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added \$${amount.toStringAsFixed(2)} to ${_selectedCategory!.name}'), backgroundColor: AppTheme.accentTeal),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Stack(
                  children: [
                    // Main Dashboard View
                    AnimatedOpacity(
                      opacity: _isAddingExpense ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: IgnorePointer(
                        ignoring: _isAddingExpense,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                          padding: const EdgeInsets.only(bottom: 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDonutChart(),
                              const SizedBox(height: 32),
                              _buildCategoryList(),
                              const SizedBox(height: 32),
                              _buildAINudge(),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Add Expense Overlay
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      top: _isAddingExpense ? 0 : MediaQuery.of(context).size.height,
                      left: 0, right: 0, bottom: 0,
                      child: _buildAddExpenseSheet(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: !_isAddingExpense ? FloatingActionButton.extended(
        onPressed: () => setState(() => _isAddingExpense = true),
        backgroundColor: AppTheme.accentAmber,
        icon: const Icon(LucideIcons.plus, color: AppTheme.primaryBlack),
        label: const Text('Log Expense', style: TextStyle(color: AppTheme.primaryBlack, fontWeight: FontWeight.w800)),
      ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              if (_isAddingExpense) {
                setState(() => _isAddingExpense = false);
              } else {
                Navigator.pop(context);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), shape: BoxShape.circle),
              child: Icon(LucideIcons.arrowLeft, color: _isAddingExpense ? AppTheme.accentAmber : AppTheme.textPrimary, size: 18),
            ),
          ),
          const Text('Cost Diary', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(width: 38), // Balance for centering
        ],
      ),
    );
  }

  Widget _buildDonutChart() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Center(
        child: SizedBox(
          width: 240, height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The Chart
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutQuart,
                builder: (context, value, child) {
                  return CustomPaint(
                    size: const Size(240, 240),
                    painter: _DonutChartPainter(_categories, _totalSpent, value),
                  );
                },
              ),
              // Center Text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Total Spent', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('\$${_totalSpent.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
                  const SizedBox(height: 4),
                  Text('of \$${_budget.toStringAsFixed(0)} limit', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.6), fontSize: 12)),
                ],
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Spending Breakdown', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 20),
          ...List.generate(_categories.length, (i) {
            final cat = _categories[i];
            final percent = _totalSpent > 0 ? cat.amount / _totalSpent : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                    child: Icon(cat.icon, color: cat.color, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(cat.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                            Text('\$${cat.amount.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            height: 6, width: double.infinity, color: Colors.white.withValues(alpha: 0.05),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: percent),
                                duration: const Duration(milliseconds: 1000),
                                curve: Curves.easeOutCubic,
                                builder: (ctx, val, child) => Container(
                                  width: MediaQuery.of(context).size.width * val,
                                  decoration: BoxDecoration(color: cat.color, borderRadius: BorderRadius.circular(4)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 300 + (100 * i))).slideX(begin: 0.05, end: 0);
          }),
        ],
      ),
    );
  }

  Widget _buildAINudge() {
    double remaining = _budget - _totalSpent;
    bool isGood = remaining > (_budget * 0.2);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isGood ? AppTheme.accentTeal.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isGood ? AppTheme.accentTeal.withValues(alpha: 0.2) : Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.sparkles, color: isGood ? AppTheme.accentTeal : Colors.redAccent, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isGood ? "You're on track!" : "Watch your spending.", style: TextStyle(color: isGood ? AppTheme.accentTeal : Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  isGood ? "You have \$${remaining.toStringAsFixed(0)} left for the rest of your trip. That fancy dinner is definitely in the budget!"
                         : "You've spent 80% of your budget. Consider local street food instead of fine dining tonight.",
                  style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.9), fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 1000.ms);
  }

  Widget _buildAddExpenseSheet() {
    return Container(
      color: AppTheme.primaryBlack,
      child: Column(
        children: [
          // Amount Display
          Expanded(
            flex: 3,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter Amount', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('\$$_currentInput', style: const TextStyle(color: AppTheme.accentAmber, fontSize: 64, fontWeight: FontWeight.w900, letterSpacing: -2)),
                ],
              ),
            ),
          ),
          
          // Category Selector
          Container(
            height: 90,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark.withValues(alpha: 0.5),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05)), bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected ? cat.color.withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? cat.color : Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(cat.icon, color: isSelected ? cat.color : AppTheme.textSecondary, size: 24),
                        const SizedBox(height: 6),
                        Text(cat.name, style: TextStyle(color: isSelected ? cat.color : AppTheme.textSecondary, fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Numpad
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                children: [
                  Expanded(child: Row(children: ['1', '2', '3'].map((e) => _buildNumPadKey(e)).toList())),
                  Expanded(child: Row(children: ['4', '5', '6'].map((e) => _buildNumPadKey(e)).toList())),
                  Expanded(child: Row(children: ['7', '8', '9'].map((e) => _buildNumPadKey(e)).toList())),
                  Expanded(child: Row(children: ['.', '0', 'DEL'].map((e) => _buildNumPadKey(e)).toList())),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _saveExpense,
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: AppTheme.amberGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: AppTheme.accentAmber.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))],
                      ),
                      child: const Center(child: Text('Save Expense', style: TextStyle(color: AppTheme.primaryBlack, fontSize: 16, fontWeight: FontWeight.w800))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumPadKey(String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onNumpadTap(label),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: label == 'DEL'
            ? const Icon(LucideIcons.delete, color: AppTheme.textSecondary, size: 24)
            : Text(label, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<ExpenseCategory> categories;
  final double total;
  final double animationValue;

  _DonutChartPainter(this.categories, this.total, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 28.0;

    double startAngle = -math.pi / 2;

    for (var cat in categories) {
      final sweepAngle = (cat.amount / total) * 2 * math.pi * animationValue;
      
      if (sweepAngle > 0) {
        final paint = Paint()
          ..color = cat.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
          startAngle + 0.04, // slight gap
          sweepAngle - 0.08, // slight gap
          false,
          paint,
        );

        startAngle += sweepAngle;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
