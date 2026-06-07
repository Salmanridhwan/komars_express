import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Widget progress arc melingkar (semi-circle) untuk menampilkan progres
/// paket pertanian aktif vs total paket yang tersedia.
///
/// Menggunakan [CustomPainter] untuk menggambar:
/// - Arc track (background) putih transparan
/// - Arc progress (foreground) warna oranye solid dengan animasi grow-in
/// - Label persentase di tengah arc
///
/// Mendukung gesture [long-press] untuk menampilkan tooltip detail breakdown
/// kategori paket pertanian (Unggas, Ikan, Sayur).
class FarmProgressArc extends StatefulWidget {
  /// Jumlah total paket pertanian yang tersedia.
  final int totalPackages;

  /// Map berisi jumlah paket per jenis tani, e.g. {'unggas': 3, 'ikan': 2}.
  final Map<String, int> packagesByType;

  const FarmProgressArc({
    super.key,
    required this.totalPackages,
    required this.packagesByType,
  });

  @override
  State<FarmProgressArc> createState() => _FarmProgressArcState();
}

class _FarmProgressArcState extends State<FarmProgressArc>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _arcAnimation;
  bool _showTooltip = false;

  // Emoji & label untuk setiap kategori tani
  static const Map<String, String> _farmLabels = {
    'unggas': '🐔 Unggas',
    'ikan': '🐟 Ikan',
    'sayur': '🥬 Sayur',
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _arcAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.totalPackages;
    // Persentase: berapa persen dari 100% yang sudah terisi (max total = 100%)
    // Kita tampilkan jumlah paket aktif vs total yang relevan
    final activeCount = widget.packagesByType.values
        .fold(0, (sum, count) => sum + count);
    final double ratio = total == 0 ? 0 : (activeCount / total).clamp(0.0, 1.0);
    final int pct = (ratio * 100).round();

    return GestureDetector(
      // Long-press untuk menampilkan tooltip detail
      onLongPress: () {
        setState(() => _showTooltip = true);
      },
      onLongPressEnd: (_) {
        setState(() => _showTooltip = false);
      },
      onLongPressCancel: () {
        setState(() => _showTooltip = false);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Arc progress widget
          AnimatedBuilder(
            animation: _arcAnimation,
            builder: (context, child) {
              return SizedBox(
                width: 120,
                height: 80,
                child: CustomPaint(
                  painter: _ArcPainter(
                    progress: ratio * _arcAnimation.value,
                  ),
                ),
              );
            },
          ),
          // Label teks di tengah arc
          Positioned(
            bottom: 2,
            child: Column(
              children: [
                Text(
                  '$pct%',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const Text(
                  'Paket',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // Tooltip overlay saat long-press
          if (_showTooltip)
            Positioned(
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distribusi Paket',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...widget.packagesByType.entries.map((entry) {
                      final label =
                          _farmLabels[entry.key.toLowerCase()] ?? entry.key;
                      final count = entry.value;
                      final typePct = total == 0
                          ? 0
                          : ((count / total) * 100).round();
                      return Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '$label: $count paket ($typePct%)',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// CustomPainter yang menggambar arc setengah lingkaran (semi-circle)
/// sebagai progress indicator berbasis persen.
class _ArcPainter extends CustomPainter {
  final double progress; // 0.0 – 1.0

  _ArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Arc dimulai dari sudut 180° (kiri) ke 0° (kanan) — setengah lingkaran bawah
    const double startAngle = math.pi; // 180° dalam radian
    const double totalSweep = math.pi; // 180° penuh sebagai track

    final Rect arcRect = Rect.fromLTRB(8, 0, size.width - 8, size.height * 1.9);

    // ── 1. Gambar Track (background arc) ──
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, startAngle, totalSweep, false, trackPaint);

    // ── 2. Gambar Progress Arc (foreground) ──
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10.0
        ..strokeCap = StrokeCap.round;

      // Beri sedikit shadow/glow
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      final sweepAngle = totalSweep * progress;
      canvas.drawArc(arcRect, startAngle, sweepAngle, false, glowPaint);
      canvas.drawArc(arcRect, startAngle, sweepAngle, false, progressPaint);
    }

    // ── 3. Gambar titik ujung indikator (dot) ──
    if (progress > 0) {
      final double sweepAngle = totalSweep * progress;
      final double tipAngle = startAngle + sweepAngle;
      final double rx = (arcRect.width / 2);
      final double ry = (arcRect.height / 2);
      final double cx = arcRect.left + rx;
      final double cy = arcRect.top + ry;

      final double dotX = cx + rx * math.cos(tipAngle);
      final double dotY = cy + ry * math.sin(tipAngle);

      canvas.drawCircle(
        Offset(dotX, dotY),
        5.5,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(dotX, dotY),
        3.0,
        Paint()
          ..color = const Color(0xFFEF6C00)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
