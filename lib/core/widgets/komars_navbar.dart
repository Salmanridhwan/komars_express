import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

/// Model data untuk setiap item di navbar.
class KomarsNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const KomarsNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Custom animated bottom navigation bar.
///
/// Desain:
/// - Menempel penuh ke bawah layar (full-width, tidak melayang)
/// - Border top tipis sebagai pemisah
/// - Pill indicator gradient oranye untuk item aktif
/// - Animasi scale bounce saat tab berganti
/// - Label selalu terlihat: aktif bold oranye, non-aktif abu kecil
/// - Haptic feedback ringan saat tap
/// - Support light & dark mode
class KomarsNavBar extends StatefulWidget {
  final int selectedIndex;
  final List<KomarsNavItem> items;
  final ValueChanged<int> onTap;

  /// Warna gradient kiri pill indicator (default oranye)
  final Color colorStart;

  /// Warna gradient kanan pill indicator (default amber)
  final Color colorEnd;

  const KomarsNavBar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onTap,
    this.colorStart = AppColors.secondaryOrange,
    this.colorEnd = AppColors.secondaryOrangeLight,
  });

  @override
  State<KomarsNavBar> createState() => _KomarsNavBarState();
}

class _KomarsNavBarState extends State<KomarsNavBar>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnims;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _controllers[widget.selectedIndex].forward();
  }

  void _initControllers() {
    _controllers = List.generate(
      widget.items.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );

    _scaleAnims = _controllers.map((ctrl) {
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.82)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 25,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 0.82, end: 1.10)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 45,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.10, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 30,
        ),
      ]).animate(ctrl);
    }).toList();
  }

  @override
  void didUpdateWidget(KomarsNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _controllers[oldWidget.selectedIndex].reverse();
      _controllers[widget.selectedIndex].forward(from: 0);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTap(int index) {
    if (index == widget.selectedIndex) return;
    HapticFeedback.lightImpact();
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final unselectedIconColor = isDark ? Colors.white38 : Colors.black38;
    final unselectedLabelColor = isDark ? Colors.white38 : Colors.black45;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(widget.items.length, (i) {
              final item = widget.items[i];
              final isSelected = widget.selectedIndex == i;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onTap(i),
                  child: AnimatedBuilder(
                    animation: _controllers[i],
                    builder: (context, _) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ── Icon dengan pill indicator ────────────────────
                          Transform.scale(
                            scale: _scaleAnims[i].value,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeInOut,
                              padding: EdgeInsets.symmetric(
                                horizontal: isSelected ? 14 : 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [
                                          widget.colorStart,
                                          widget.colorEnd,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: widget.colorStart
                                              .withValues(alpha: 0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Icon(
                                isSelected ? item.activeIcon : item.icon,
                                color: isSelected
                                    ? Colors.white
                                    : unselectedIconColor,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          // ── Label selalu tampil ───────────────────────────
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isSelected
                                  ? widget.colorStart
                                  : unselectedLabelColor,
                            ),
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
