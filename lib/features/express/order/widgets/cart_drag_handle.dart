import 'package:flutter/material.dart';

/// Widget kustom yang menggambar ikon drag handle (≡) menggunakan [CustomPainter].
/// Ditampilkan di sisi kanan item keranjang belanja saat mode reorder aktif.
/// Memberi sinyal visual kepada pengguna bahwa item bisa diseret untuk mengubah urutan.
class CartDragHandle extends StatelessWidget {
  final bool isReorderMode;
  final Color color;

  const CartDragHandle({
    super.key,
    required this.isReorderMode,
    this.color = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isReorderMode ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      child: SizedBox(
        width: 28,
        height: 36,
        child: CustomPaint(
          painter: _DragHandlePainter(color: color),
        ),
      ),
    );
  }
}

/// CustomPainter yang menggambar tiga garis horizontal paralel
/// sebagai ikon drag handle standar.
class _DragHandlePainter extends CustomPainter {
  final Color color;
  _DragHandlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Tiga garis horizontal dengan jarak merata
    final double cx = size.width / 2;
    final double lineHalfWidth = size.width * 0.38;
    const double gap = 5.0;
    final double midY = size.height / 2;

    for (int i = -1; i <= 1; i++) {
      final double y = midY + i * gap;
      canvas.drawLine(
        Offset(cx - lineHalfWidth, y),
        Offset(cx + lineHalfWidth, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DragHandlePainter oldDelegate) =>
      oldDelegate.color != color;
}
