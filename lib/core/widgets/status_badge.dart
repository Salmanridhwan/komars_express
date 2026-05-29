import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double? fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.border, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: config.text,
          fontSize: fontSize ?? 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  _StatusConfig _getConfig(String status) {
    switch (status.toLowerCase()) {
      case 'lunas':
      case 'selesai':
        return _StatusConfig(
          bg: const Color(0xFFE8F5E9),
          text: AppColors.primaryGreen,
          border: const Color(0xFFA5D6A7),
        );
      case 'menunggu pembayaran':
      case 'aktif':
        return _StatusConfig(
          bg: const Color(0xFFFFF8E1),
          text: const Color(0xFFF57F17),
          border: const Color(0xFFFFCC80),
        );
      case 'berlangsung':
        return _StatusConfig(
          bg: const Color(0xFFE3F2FD),
          text: AppColors.statusActive,
          border: const Color(0xFF90CAF9),
        );
      case 'dibatalkan':
        return _StatusConfig(
          bg: const Color(0xFFFFEBEE),
          text: AppColors.statusCancelled,
          border: const Color(0xFFEF9A9A),
        );
      default:
        return _StatusConfig(
          bg: const Color(0xFFF5F5F5),
          text: Colors.grey,
          border: const Color(0xFFE0E0E0),
        );
    }
  }
}

class _StatusConfig {
  final Color bg;
  final Color text;
  final Color border;

  _StatusConfig({required this.bg, required this.text, required this.border});
}
