import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../models/table_model.dart';

class TableFloorMap extends StatefulWidget {
  final List<TableModel> tables;
  final Set<int> reservedTableIds;
  final int? selectedTableId;
  final ValueChanged<TableModel> onTableSelected;

  const TableFloorMap({
    super.key,
    required this.tables,
    required this.reservedTableIds,
    required this.onTableSelected,
    this.selectedTableId,
  });

  @override
  State<TableFloorMap> createState() => _TableFloorMapState();
}

class _TableFloorMapState extends State<TableFloorMap> {
  Offset _panOffset = Offset.zero;
  
  // Deterministic coordinate spacing for tables
  Offset _getTableOffset(TableModel table) {
    final locTables = widget.tables.where((t) => t.location == table.location).toList();
    final localIdx = locTables.indexWhere((t) => t.id == table.id);
    if (localIdx == -1) return const Offset(160, 200);

    final col = localIdx % 3;
    final row = localIdx ~/ 3;

    double x = 60.0 + col * 110.0;
    double y = 0.0;

    if (table.location == 'VIP') {
      y = 80.0 + row * 90.0;
      if (locTables.length < 3) {
        x = 115.0 + col * 110.0;
      }
    } else if (table.location == 'Indoor') {
      y = 220.0 + row * 90.0;
    } else { // Outdoor
      y = 370.0 + row * 90.0;
    }

    return Offset(x, y);
  }

  void _handleTap(TapUpDetails details) {
    // Adjust tap location based on camera offset
    final tapPos = details.localPosition - _panOffset;

    TableModel? tappedTable;
    double minDistance = double.infinity;

    for (final table in widget.tables) {
      final center = _getTableOffset(table);
      final distance = (tapPos - center).distance;

      // Table radius is 26px, let's use 32px click margin
      if (distance <= 32 && distance < minDistance) {
        tappedTable = table;
        minDistance = distance;
      }
    }

    if (tappedTable != null) {
      final isReserved = widget.reservedTableIds.contains(tappedTable.id);
      if (!isReserved) {
        widget.onTableSelected(tappedTable);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Map Container
        GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _panOffset += details.delta;
            });
          },
          onDoubleTap: () {
            setState(() {
              _panOffset = Offset.zero;
            });
          },
          onTapUp: _handleTap,
          child: Container(
            width: double.infinity,
            height: 480,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppColors.darkDivider : Colors.grey.shade200,
                width: 1.5,
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(
                painter: FloorMapPainter(
                  tables: widget.tables,
                  reservedTableIds: widget.reservedTableIds,
                  selectedTableId: widget.selectedTableId,
                  panOffset: _panOffset,
                  getTableOffset: _getTableOffset,
                  isDark: isDark,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Interactive note
        Text(
          '* Geser denah untuk memindahkan • Ketuk meja untuk memilih • Ketuk 2x untuk reset',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 10,
            fontStyle: FontStyle.italic,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}

class FloorMapPainter extends CustomPainter {
  final List<TableModel> tables;
  final Set<int> reservedTableIds;
  final int? selectedTableId;
  final Offset panOffset;
  final Offset Function(TableModel) getTableOffset;
  final bool isDark;

  FloorMapPainter({
    required this.tables,
    required this.reservedTableIds,
    required this.selectedTableId,
    required this.panOffset,
    required this.getTableOffset,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Translate map viewport by the current pan camera offset
    canvas.translate(panOffset.dx, panOffset.dy);

    // ─── 1. Draw Seating Area Boundary Boxes ───
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    // VIP Lounge Boundary (y from 30 to 140)
    fillPaint.color = (isDark ? const Color(0xFF7B1FA2) : const Color(0xFFE1BEE7)).withValues(alpha: 0.06);
    linePaint.color = const Color(0xFF7B1FA2).withValues(alpha: 0.35);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(16, 25, 324, 145), const Radius.circular(16)),
      fillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(16, 25, 324, 145), const Radius.circular(16)),
      linePaint,
    );
    _drawLabel(canvas, 'VIP Area (Room)', const Offset(26, 32), const Color(0xFF7B1FA2));

    // Indoor Boundary (y from 165 to 295)
    fillPaint.color = (isDark ? AppColors.secondaryOrange : AppColors.secondaryOrangeLight).withValues(alpha: 0.05);
    linePaint.color = AppColors.secondaryOrange.withValues(alpha: 0.35);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(16, 165, 324, 295), const Radius.circular(16)),
      fillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(16, 165, 324, 295), const Radius.circular(16)),
      linePaint,
    );
    _drawLabel(canvas, 'Indoor AC Lounge', const Offset(26, 172), AppColors.secondaryOrange);

    // Outdoor Garden Boundary (y from 315 to 455)
    fillPaint.color = (isDark ? AppColors.primaryGreen : AppColors.primaryGreenLight).withValues(alpha: 0.05);
    linePaint.color = AppColors.primaryGreen.withValues(alpha: 0.35);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(16, 315, 324, 455), const Radius.circular(16)),
      fillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(16, 315, 324, 455), const Radius.circular(16)),
      linePaint,
    );
    _drawLabel(canvas, 'Outdoor Garden', const Offset(26, 322), AppColors.primaryGreen);

    // Decorative Tree (Simple Custom Drawing element in Outdoor)
    _drawTree(canvas, const Offset(285, 335));
    _drawTree(canvas, const Offset(45, 435));

    // ─── 2. Draw Tables and Chairs ───
    for (final table in tables) {
      final center = getTableOffset(table);
      final isReserved = reservedTableIds.contains(table.id);
      final isSelected = selectedTableId == table.id;

      Color mainColor;
      if (isReserved) {
        mainColor = AppColors.statusCancelled;
      } else if (isSelected) {
        mainColor = AppColors.statusActive;
      } else {
        // Theme by Location
        switch (table.location) {
          case 'VIP':
            mainColor = const Color(0xFF7B1FA2);
            break;
          case 'Outdoor':
            mainColor = AppColors.primaryGreen;
            break;
          default:
            mainColor = AppColors.statusSuccess;
        }
      }

      // Draw Chairs Around Table
      _drawChairs(canvas, center, table.capacity, isReserved ? Colors.grey : mainColor);

      // Draw Table Shape
      final tablePaint = Paint()
        ..color = isDark ? AppColors.darkCard : Colors.white
        ..style = PaintingStyle.fill;
      
      final borderPaint = Paint()
        ..color = mainColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3.0 : 2.0;

      const double size = 26.0; // Table radius/half-size

      if (table.location == 'Indoor') {
        // Rounded Rect for Indoor
        final rect = Rect.fromCircle(center: center, radius: size);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), tablePaint);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), borderPaint);
      } else {
        // Circle for VIP and Outdoor
        canvas.drawCircle(center, size, tablePaint);
        canvas.drawCircle(center, size, borderPaint);
      }

      // Draw Table Label
      _drawTableLabel(canvas, table.tableNumber, center, isReserved ? Colors.grey : mainColor);
    }

    canvas.restore();
  }

  void _drawLabel(Canvas canvas, String text, Offset offset, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  void _drawTree(Canvas canvas, Offset center) {
    // Draw simple botanical shape for garden vibe
    final trunkPaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..style = PaintingStyle.fill;
    
    final leavePaint = Paint()
      ..color = const Color(0xFF4CAF50).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromCenter(center: center + const Offset(0, 8), width: 3, height: 10), trunkPaint);
    canvas.drawCircle(center, 7, leavePaint);
    canvas.drawCircle(center - const Offset(4, 3), 5, leavePaint);
    canvas.drawCircle(center + const Offset(4, 3), 5, leavePaint);
  }

  void _drawChairs(Canvas canvas, Offset tableCenter, int capacity, Color color) {
    final chairPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final double dist = 34.0; // Distance of chair center from table center
    final double chairRadius = 5.0;

    for (int i = 0; i < capacity; i++) {
      final angle = (i * 2 * math.pi) / capacity;
      final chairCenter = Offset(
        tableCenter.dx + dist * math.cos(angle),
        tableCenter.dy + dist * math.sin(angle),
      );
      canvas.drawCircle(chairCenter, chairRadius, chairPaint);
    }
  }

  void _drawTableLabel(Canvas canvas, String label, Offset center, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    // Center alignment offset
    final textOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant FloorMapPainter oldDelegate) {
    return oldDelegate.tables != tables ||
        oldDelegate.reservedTableIds != reservedTableIds ||
        oldDelegate.selectedTableId != selectedTableId ||
        oldDelegate.panOffset != panOffset ||
        oldDelegate.isDark != isDark;
  }
}
