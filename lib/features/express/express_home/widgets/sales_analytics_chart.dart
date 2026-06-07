import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Model data untuk setiap titik/bar pada grafik analitik penjualan.
class ChartDataPoint {
  final String label; // E.g., 'Sen', 'Sel', 'Rab'
  final String fullDate; // E.g., 'Senin, 01 Juni 2026'
  final double value; // Nilai nominal pendapatan

  const ChartDataPoint({
    required this.label,
    required this.fullDate,
    required this.value,
  });
}

/// Widget Grafik Analisis Penjualan interaktif yang digambar menggunakan CustomPainter.
/// Mendukung gestur:
/// 1. Pan/Drag (menggeser): Untuk melihat tooltip dan titik koordinat pendapatan secara detail.
/// 2. Double Tap: Untuk mengubah tipe grafik dari Line Chart ke Bar Chart (atau sebaliknya).
class SalesAnalyticsChart extends StatefulWidget {
  final List<ChartDataPoint> dataPoints;

  const SalesAnalyticsChart({
    super.key,
    required this.dataPoints,
  });

  @override
  State<SalesAnalyticsChart> createState() => _SalesAnalyticsChartState();
}

class _SalesAnalyticsChartState extends State<SalesAnalyticsChart> {
  bool _isLineChart = true;
  int _hoverIndex = -1;
  Offset? _hoverOffset;

  void _updateHover(Offset localPosition, double chartWidth, double paddingLeft) {
    if (widget.dataPoints.isEmpty) return;

    final double stepWidth = chartWidth / (widget.dataPoints.length - 1);
    final double relativeX = localPosition.dx - paddingLeft;
    
    int index = (relativeX / stepWidth).round();
    if (index < 0) index = 0;
    if (index >= widget.dataPoints.length) index = widget.dataPoints.length - 1;

    setState(() {
      _hoverIndex = index;
      _hoverOffset = localPosition;
    });
  }

  void _clearHover() {
    setState(() {
      _hoverIndex = -1;
      _hoverOffset = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.dataPoints.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: Text(
          'Tidak ada data penjualan',
          style: TextStyle(
            fontFamily: 'Outfit',
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const double paddingLeft = 45.0;
        const double paddingRight = 16.0;
        final double chartWidth = constraints.maxWidth - paddingLeft - paddingRight;

        return TweenAnimationBuilder<double>(
          // Micro-animation saat load pertama kali atau ketika tipe grafik berubah
          key: ValueKey(_isLineChart),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, animValue, child) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkDivider : Colors.grey.shade200,
                  width: 1.5,
                ),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Analisis Pendapatan',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isLineChart ? 'Tampilan: Grafik Garis' : 'Tampilan: Grafik Batang',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      // Visual indicator toggler button
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          _isLineChart ? Icons.bar_chart_rounded : Icons.show_chart_rounded,
                          color: AppColors.secondaryOrange,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _isLineChart = !_isLineChart;
                          });
                        },
                        tooltip: 'Ubah Jenis Grafik',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Chart Area
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanDown: (details) => _updateHover(details.localPosition, chartWidth, paddingLeft),
                    onPanUpdate: (details) => _updateHover(details.localPosition, chartWidth, paddingLeft),
                    onPanEnd: (_) => _clearHover(),
                    onPanCancel: () => _clearHover(),
                    onDoubleTap: () {
                      setState(() {
                        _isLineChart = !_isLineChart;
                      });
                    },
                    child: SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: SalesChartPainter(
                          dataPoints: widget.dataPoints,
                          isLineChart: _isLineChart,
                          hoverIndex: _hoverIndex,
                          hoverOffset: _hoverOffset,
                          isDark: isDark,
                          animationValue: animValue,
                          paddingLeft: paddingLeft,
                          paddingRight: paddingRight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Footer Legend & Gestures instructions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.secondaryOrange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pendapatan (Rupiah)',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Geser kursor untuk detail • Ketuk 2x untuk ubah',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 9,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class SalesChartPainter extends CustomPainter {
  final List<ChartDataPoint> dataPoints;
  final bool isLineChart;
  final int hoverIndex;
  final Offset? hoverOffset;
  final bool isDark;
  final double animationValue;
  final double paddingLeft;
  final double paddingRight;

  SalesChartPainter({
    required this.dataPoints,
    required this.isLineChart,
    required this.hoverIndex,
    required this.hoverOffset,
    required this.isDark,
    required this.animationValue,
    required this.paddingLeft,
    required this.paddingRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingTop = 25.0;
    const double paddingBottom = 25.0;
    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    // ─── 1. Hitung Batas Atas Skala (Y Axis) ───
    double maxVal = 0.0;
    for (final dp in dataPoints) {
      if (dp.value > maxVal) maxVal = dp.value;
    }
    // Jika semua data 0, berikan skala default 100k
    double upperLimit = maxVal == 0 ? 100000.0 : maxVal * 1.15; // Beri ruang 15% untuk tooltip di atas

    // ─── 2. Gambar Grid Lines Horisontal & Label Y ───
    final gridPaint = Paint()
      ..color = (isDark ? AppColors.darkDivider : AppColors.lightDivider).withValues(alpha: 0.7)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final int divisions = 3;
    for (int i = 0; i <= divisions; i++) {
      double ratio = i / divisions;
      double y = paddingTop + chartHeight * (1 - ratio);
      
      // Garis grid horizontal
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);

      // Label nominal di sumbu Y
      double val = upperLimit * ratio;
      _drawLabelText(
        canvas,
        _formatAxisValue(val),
        Offset(5, y - 6),
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        fontSize: 9,
        fontWeight: FontWeight.w600,
        alignment: Alignment.centerLeft,
      );
    }

    // ─── 3. Siapkan Titik Koordinat (X, Y) ───
    final List<Offset> points = [];
    final double stepWidth = chartWidth / (dataPoints.length - 1);

    for (int i = 0; i < dataPoints.length; i++) {
      double x = paddingLeft + i * stepWidth;
      double ratio = upperLimit == 0 ? 0.0 : (dataPoints[i].value / upperLimit);
      // Efek micro-animation pada tinggi data
      double animatedRatio = ratio * animationValue;
      double y = paddingTop + chartHeight * (1.0 - animatedRatio);
      points.add(Offset(x, y));
    }

    // ─── 4. Render Visual Sesuai Tipe Grafik ───
    if (isLineChart) {
      // ── Grafik Garis (Line Chart) ──
      if (points.isNotEmpty) {
        final path = Path();
        path.moveTo(points[0].dx, points[0].dy);

        // Menggunakan kurva bezier cubic untuk transisi garis yang mulus & premium
        for (int i = 0; i < points.length - 1; i++) {
          final p0 = points[i];
          final p1 = points[i + 1];
          final control1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
          final control2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
          path.cubicTo(control1.dx, control1.dy, control2.dx, control2.dy, p1.dx, p1.dy);
        }

        // Gambar Area Gradient Fill di Bawah Garis
        final fillPath = Path.from(path);
        fillPath.lineTo(points.last.dx, paddingTop + chartHeight);
        fillPath.lineTo(points.first.dx, paddingTop + chartHeight);
        fillPath.close();

        final fillPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.secondaryOrange.withValues(alpha: 0.35),
              AppColors.secondaryOrange.withValues(alpha: 0.00),
            ],
          ).createShader(Rect.fromLTRB(paddingLeft, paddingTop, size.width - paddingRight, paddingTop + chartHeight))
          ..style = PaintingStyle.fill;

        canvas.drawPath(fillPath, fillPaint);

        // Gambar Garis Tren Utama
        final strokePaint = Paint()
          ..color = AppColors.secondaryOrange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        canvas.drawPath(path, strokePaint);

        // Gambar Titik Penanda (Dots) untuk Setiap Hari
        final dotFillPaint = Paint()
          ..color = isDark ? AppColors.darkCard : Colors.white
          ..style = PaintingStyle.fill;
        final dotStrokePaint = Paint()
          ..color = AppColors.secondaryOrange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        for (int i = 0; i < points.length; i++) {
          canvas.drawCircle(points[i], 4.5, dotFillPaint);
          canvas.drawCircle(points[i], 4.5, dotStrokePaint);
        }
      }
    } else {
      // ── Grafik Batang (Bar Chart) ──
      final double barWidth = stepWidth * 0.4;
      for (int i = 0; i < points.length; i++) {
        final p = points[i];
        final double x = p.dx;
        final double y = p.dy;
        final double bottomY = paddingTop + chartHeight;

        // Bounding rect untuk bar
        final rect = Rect.fromLTRB(x - barWidth / 2, y, x + barWidth / 2, bottomY);
        // Desain melengkung di sudut atas bar
        final rrect = RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(5),
          topRight: const Radius.circular(5),
        );

        final barPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.secondaryOrange,
              AppColors.secondaryOrange.withValues(alpha: 0.3),
            ],
          ).createShader(rect)
          ..style = PaintingStyle.fill;

        canvas.drawRRect(rrect, barPaint);
      }
    }

    // ─── 5. Gambar Label Sumbu X (Hari) ───
    for (int i = 0; i < dataPoints.length; i++) {
      double x = points[i].dx;
      _drawLabelText(
        canvas,
        dataPoints[i].label,
        Offset(x, paddingTop + chartHeight + 10),
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        alignment: Alignment.topCenter,
      );
    }

    // ─── 6. Gambar Interaksi Tooltip / Hover (Jika Aktif) ───
    if (hoverIndex >= 0 && hoverIndex < points.length) {
      final activePoint = points[hoverIndex];
      final activeData = dataPoints[hoverIndex];

      // A. Gambar Garis Bantu Vertikal (Crosshair)
      final crosshairPaint = Paint()
        ..color = AppColors.secondaryOrange.withValues(alpha: 0.4)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      
      // Garis putus-putus sederhana vertikal
      double startY = paddingTop;
      double endY = paddingTop + chartHeight;
      double dashHeight = 4.0;
      double dashSpace = 3.0;
      double currentY = startY;
      while (currentY < endY) {
        canvas.drawLine(
          Offset(activePoint.dx, currentY),
          Offset(activePoint.dx, math.min(currentY + dashHeight, endY)),
          crosshairPaint,
        );
        currentY += dashHeight + dashSpace;
      }

      // B. Gambar Dot Glow di titik aktif
      final glowPaint = Paint()
        ..color = AppColors.secondaryOrange.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      final highlightPaint = Paint()
        ..color = AppColors.secondaryOrange
        ..style = PaintingStyle.fill;

      canvas.drawCircle(activePoint, 10.0, glowPaint);
      canvas.drawCircle(activePoint, 5.0, highlightPaint);
      canvas.drawCircle(activePoint, 5.0, Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke);

      // C. Menggambar Balon Dialog Tooltip Melayang
      final String priceStr = CurrencyFormatter.format(activeData.value);
      final String dateStr = activeData.fullDate;
      final String tooltipText = '$dateStr: $priceStr';

      final textPainter = TextPainter(
        text: TextSpan(
          text: tooltipText,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Hitung posisi Tooltip agar tidak meluber keluar layar canvas
      double tooltipWidth = textPainter.width + 16.0;
      double tooltipHeight = textPainter.height + 10.0;
      double tooltipX = activePoint.dx - tooltipWidth / 2;
      double tooltipY = activePoint.dy - tooltipHeight - 12;

      // Proteksi sisi kiri & kanan
      if (tooltipX < paddingLeft) {
        tooltipX = paddingLeft;
      } else if (tooltipX + tooltipWidth > size.width - paddingRight) {
        tooltipX = size.width - paddingRight - tooltipWidth;
      }
      // Proteksi sisi atas (jika mepet ke atas, pindahkan ke bawah titik data)
      if (tooltipY < 2) {
        tooltipY = activePoint.dy + 12;
      }

      final Rect tooltipRect = Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight);
      final RRect tooltipRRect = RRect.fromRectAndRadius(tooltipRect, const Radius.circular(8));

      // Draw Tooltip Shadow & Background
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawRRect(tooltipRRect, shadowPaint);

      final tooltipBgPaint = Paint()
        ..color = const Color(0xFF2C2C2C)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(tooltipRRect, tooltipBgPaint);

      // Draw Tooltip Text
      textPainter.paint(
        canvas,
        Offset(tooltipX + 8.0, tooltipY + 5.0),
      );
    }
  }

  String _formatAxisValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1).replaceAll('.0', '')}Jt';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}Rb';
    }
    return value.toStringAsFixed(0);
  }

  void _drawLabelText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color, {
    double fontSize = 10,
    FontWeight fontWeight = FontWeight.normal,
    Alignment alignment = Alignment.center,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    double dx = offset.dx;
    double dy = offset.dy;

    if (alignment == Alignment.center) {
      dx -= textPainter.width / 2;
      dy -= textPainter.height / 2;
    } else if (alignment == Alignment.topCenter) {
      dx -= textPainter.width / 2;
    } else if (alignment == Alignment.centerLeft) {
      dy -= textPainter.height / 2;
    }

    textPainter.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant SalesChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints ||
        oldDelegate.isLineChart != isLineChart ||
        oldDelegate.hoverIndex != hoverIndex ||
        oldDelegate.hoverOffset != hoverOffset ||
        oldDelegate.isDark != isDark ||
        oldDelegate.animationValue != animationValue;
  }
}
