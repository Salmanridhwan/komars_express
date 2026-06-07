import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';

class FinancialDonutChart extends StatefulWidget {
  final double income;
  final double expense;
  final double loss;

  const FinancialDonutChart({
    super.key,
    required this.income,
    required this.expense,
    required this.loss,
  });

  @override
  State<FinancialDonutChart> createState() => _FinancialDonutChartState();
}

class _FinancialDonutChartState extends State<FinancialDonutChart> {
  double _rotationAngle = 0.0;

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
    final double netProfit = widget.income - widget.expense - widget.loss;
    final isProfit = netProfit >= 0;
    final profitColor = isProfit ? Colors.green : Colors.red;
    final total = widget.income + widget.expense + widget.loss;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Center(
          child: Column(
            children: [
              GestureDetector(
                // Gesture 1: Pan/Drag untuk memutar diagram
                onPanUpdate: (details) {
                  setState(() {
                    _rotationAngle += details.delta.dx * 0.01;
                  });
                },
                // Gesture 2: Double Tap untuk reset putaran
                onDoubleTap: () {
                  setState(() {
                    _rotationAngle = 0.0;
                  });
                },
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                    ],
                    border: Border.all(
                      color: isDark ? AppColors.darkDivider : Colors.grey.shade100,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Custom Drawing: Menggambar diagram donat
                      CustomPaint(
                        size: const Size(200, 200),
                        painter: DonutChartPainter(
                          income: widget.income,
                          expense: widget.expense,
                          loss: widget.loss,
                          total: total,
                          rotationAngle: _rotationAngle,
                          isDark: isDark,
                        ),
                      ),
                      // Overlay informasi di tengah donat
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Net Profit',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatCurrency(netProfit),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: profitColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Keterangan / Legenda
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Income', Colors.green),
                  const SizedBox(width: 16),
                  _buildLegendItem('Expense', Colors.orange),
                  const SizedBox(width: 16),
                  _buildLegendItem('Loss', Colors.red),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '* Geser diagram untuk memutar • Ketuk 2x untuk reset',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final double income;
  final double expense;
  final double loss;
  final double total;
  final double rotationAngle;
  final bool isDark;

  DonutChartPainter({
    required this.income,
    required this.expense,
    required this.loss,
    required this.total,
    required this.rotationAngle,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = radius * 0.25;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (total == 0) {
      paint.color = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
      canvas.drawCircle(center, radius - strokeWidth / 2, paint);
      return;
    }

    final double incomeSweep = (income / total) * 2 * math.pi;
    final double expenseSweep = (expense / total) * 2 * math.pi;
    final double lossSweep = (loss / total) * 2 * math.pi;

    double startAngle = -math.pi / 2 + rotationAngle;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // 1. Draw Income (Green)
    if (incomeSweep > 0) {
      paint.color = Colors.green.shade500;
      canvas.drawArc(rect, startAngle, incomeSweep, false, paint);
      startAngle += incomeSweep;
    }

    // 2. Draw Expense (Orange)
    if (expenseSweep > 0) {
      paint.color = Colors.orange.shade500;
      canvas.drawArc(rect, startAngle, expenseSweep, false, paint);
      startAngle += expenseSweep;
    }

    // 3. Draw Loss (Red)
    if (lossSweep > 0) {
      paint.color = Colors.red.shade500;
      canvas.drawArc(rect, startAngle, lossSweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.income != income ||
        oldDelegate.expense != expense ||
        oldDelegate.loss != loss ||
        oldDelegate.total != total ||
        oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.isDark != isDark;
  }
}
