import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../models/table_model.dart';

/// Custom Widget (Ega) — PRD §5.2.C
///
/// Renders restaurant tables as interactive grid tiles with 3 states:
///   • Available  → Green
///   • Selected   → Blue (user's current pick)
///   • Reserved   → Red  (disabled, cannot be tapped)
class TableGridSelector extends StatefulWidget {
  final List<TableModel> tables;

  /// Set of table IDs that are already reserved (conflict on chosen date/time).
  final Set<int> reservedTableIds;

  /// Currently selected table ID (nullable).
  final int? selectedTableId;

  /// Called when the user taps an available tile.
  final ValueChanged<TableModel> onTableSelected;

  const TableGridSelector({
    super.key,
    required this.tables,
    required this.reservedTableIds,
    required this.onTableSelected,
    this.selectedTableId,
  });

  @override
  State<TableGridSelector> createState() => _TableGridSelectorState();
}

class _TableGridSelectorState extends State<TableGridSelector> {
  @override
  Widget build(BuildContext context) {
    if (widget.tables.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada meja tersedia',
          style: TextStyle(fontFamily: 'Outfit', color: Colors.grey),
        ),
      );
    }

    // Group tables by location
    final grouped = <String, List<TableModel>>{};
    for (final t in widget.tables) {
      grouped.putIfAbsent(t.location, () => []).add(t);
    }

    // Location display order
    final locationOrder = ['VIP', 'Indoor', 'Outdoor'];
    final orderedLocations = locationOrder
        .where((loc) => grouped.containsKey(loc))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        _buildLegend(),
        const SizedBox(height: 16),

        for (final location in orderedLocations) ...[
          _buildLocationSection(location, grouped[location]!),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _LegendDot(color: AppColors.statusSuccess, label: 'Tersedia'),
        const SizedBox(width: 16),
        _LegendDot(color: AppColors.statusActive, label: 'Dipilih'),
        const SizedBox(width: 16),
        _LegendDot(color: AppColors.statusCancelled, label: 'Terpesan'),
      ],
    );
  }

  Widget _buildLocationSection(String location, List<TableModel> tables) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData locationIcon;
    Color locationColor;
    switch (location) {
      case 'VIP':
        locationIcon = Icons.star_rounded;
        locationColor = const Color(0xFF7B1FA2); // purple
        break;
      case 'Outdoor':
        locationIcon = Icons.park_rounded;
        locationColor = AppColors.primaryGreen;
        break;
      default: // Indoor
        locationIcon = Icons.chair_rounded;
        locationColor = AppColors.statusActive;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(locationIcon, size: 16, color: locationColor),
            const SizedBox(width: 6),
            Text(
              location,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: locationColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemCount: tables.length,
          itemBuilder: (context, i) {
            final table = tables[i];
            final isReserved = widget.reservedTableIds.contains(table.id);
            final isSelected = widget.selectedTableId == table.id;
            return _TableTile(
              table: table,
              isReserved: isReserved,
              isSelected: isSelected,
              isDark: isDark,
              onTap: isReserved ? null : () => widget.onTableSelected(table),
            );
          },
        ),
      ],
    );
  }
}

// ─── Individual Table Tile with AnimatedScale (PRD §5.2.C) ───────────────────

class _TableTile extends StatefulWidget {
  final TableModel table;
  final bool isReserved;
  final bool isSelected;
  final bool isDark;
  final VoidCallback? onTap;

  const _TableTile({
    required this.table,
    required this.isReserved,
    required this.isSelected,
    required this.isDark,
    this.onTap,
  });

  @override
  State<_TableTile> createState() => _TableTileState();
}

class _TableTileState extends State<_TableTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _controller.forward();
  void _onTapUp(_) {
    _controller.reverse();
    widget.onTap?.call();
  }
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    Color tileColor;
    Color borderColor;
    Color textColor;

    if (widget.isReserved) {
      tileColor = AppColors.statusCancelled.withValues(alpha: 0.12);
      borderColor = AppColors.statusCancelled;
      textColor = AppColors.statusCancelled;
    } else if (widget.isSelected) {
      tileColor = AppColors.statusActive.withValues(alpha: 0.15);
      borderColor = AppColors.statusActive;
      textColor = AppColors.statusActive;
    } else {
      tileColor = AppColors.statusSuccess.withValues(alpha: 0.10);
      borderColor = AppColors.statusSuccess;
      textColor = AppColors.statusSuccess;
    }

    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: widget.isReserved ? null : _onTapDown,
        onTapUp: widget.isReserved ? null : _onTapUp,
        onTapCancel: widget.isReserved ? null : _onTapCancel,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            decoration: BoxDecoration(
              color: widget.isDark ? widget.isSelected
                  ? AppColors.statusActive.withValues(alpha: 0.25)
                  : tileColor
                  : tileColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.table_restaurant_rounded,
                  color: textColor,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.table.tableNumber,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                Text(
                  '${widget.table.capacity} kursi',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 9,
                    color: textColor.withValues(alpha: 0.8),
                  ),
                ),
                if (widget.isReserved)
                  const Icon(Icons.lock_rounded, size: 10, color: AppColors.statusCancelled),
                if (widget.isSelected)
                  const Icon(Icons.check_circle_rounded, size: 10, color: AppColors.statusActive),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Legend Dot ───────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
