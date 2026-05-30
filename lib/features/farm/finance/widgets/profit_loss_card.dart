import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProfitLossCard extends StatefulWidget {
  final double income;
  final double expense;
  final double loss;
  final double netProfit;
  final String title;
  final VoidCallback? onTap;

  const ProfitLossCard({
    Key? key,
    required this.income,
    required this.expense,
    required this.loss,
    required this.netProfit,
    this.title = 'Financial Summary',
    this.onTap,
  }) : super(key: key);

  @override
  State<ProfitLossCard> createState() => _ProfitLossCardState();
}

class _ProfitLossCardState extends State<ProfitLossCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final isProfit = widget.netProfit >= 0;
    final profitColor = isProfit ? Colors.green : Colors.red;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.grey.shade50],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  widget.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Income, Expense, Loss row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _FinancialItem(
                      label: 'Income',
                      amount: widget.income,
                      color: Colors.green,
                    ),
                    _FinancialItem(
                      label: 'Expense',
                      amount: widget.expense,
                      color: Colors.orange,
                    ),
                    _FinancialItem(
                      label: 'Loss',
                      amount: widget.loss,
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Net Profit with Animated Counter
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: profitColor.withOpacity(0.1),
                    border: Border.all(color: profitColor, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Net Profit',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: profitColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: widget.netProfit),
                        duration: const Duration(milliseconds: 600),
                        builder: (context, value, child) {
                          return Text(
                            _formatCurrency(value),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: profitColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FinancialItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _FinancialItem({
    Key? key,
    required this.label,
    required this.amount,
    required this.color,
  }) : super(key: key);

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: amount),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Text(
                _formatCurrency(value),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
