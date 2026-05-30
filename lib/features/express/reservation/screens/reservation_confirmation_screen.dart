import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/status_badge.dart';
import '../db/reservation_dao.dart';
import '../models/reservation_model.dart';

class ReservationConfirmationScreen extends StatefulWidget {
  final int reservationId;

  const ReservationConfirmationScreen({super.key, required this.reservationId});

  @override
  State<ReservationConfirmationScreen> createState() =>
      _ReservationConfirmationScreenState();
}

class _ReservationConfirmationScreenState
    extends State<ReservationConfirmationScreen>
    with SingleTickerProviderStateMixin {
  final _dao = ReservationDao();
  ReservationModel? _reservation;
  bool _loading = true;

  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _load();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final r = await _dao.getById(widget.reservationId);
    if (mounted) {
      setState(() { _reservation = r; _loading = false; });
      _animController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Spacer(),
                    // Animated checkmark
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Container(
                        width: 100, height: 100,
                        decoration: const BoxDecoration(
                          color: AppColors.statusSuccess,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(children: [
                        const Text('Reservasi Berhasil!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(
                          'Reservasi meja Anda telah dikonfirmasi. Sampai jumpa di Komars!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 14,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 32),
                    if (_reservation != null)
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                            boxShadow: [if (!isDark)
                              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12,
                                  offset: const Offset(0, 4))],
                          ),
                          child: Column(children: [
                            _InfoRow(icon: Icons.table_restaurant_rounded, label: 'Meja',
                                value: '${_reservation!.tableNumber ?? _reservation!.tableId} (${_reservation!.tableLocation ?? ''})'),
                            const Divider(height: 20),
                            _InfoRow(icon: Icons.calendar_today_rounded, label: 'Tanggal',
                                value: _reservation!.reservationDate),
                            const Divider(height: 20),
                            _InfoRow(icon: Icons.schedule_rounded, label: 'Waktu',
                                value: '${_reservation!.startTime} – ${_reservation!.endTime}'),
                            const Divider(height: 20),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              const Text('Status', style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: Colors.grey)),
                              StatusBadge(status: _reservation!.status),
                            ]),
                          ]),
                        ),
                      ),
                    const Spacer(),
                    Column(children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.reservationHistory, (r) => false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondaryOrange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            elevation: 0,
                          ),
                          child: const Text('Lihat Riwayat Reservasi',
                              style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pushNamedAndRemoveUntil(
                              context, AppRoutes.home, (r) => false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.secondaryOrange,
                            side: const BorderSide(color: AppColors.secondaryOrange),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text('Kembali ke Beranda',
                              style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 15)),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, color: Colors.grey)),
      Row(children: [
        Icon(icon, size: 14, color: AppColors.secondaryOrange),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    ]);
  }
}
