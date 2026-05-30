import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/status_badge.dart';
import '../db/reservation_dao.dart';
import '../models/reservation_model.dart';

class ReservationHistoryScreen extends StatefulWidget {
  const ReservationHistoryScreen({super.key});

  @override
  State<ReservationHistoryScreen> createState() => _ReservationHistoryScreenState();
}

class _ReservationHistoryScreenState extends State<ReservationHistoryScreen> {
  final _dao = ReservationDao();
  List<ReservationModel> _reservations = [];
  bool _isLoading = true;

  // In production, get from session. Here default to 1.
  final int _userId = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final list = await _dao.getByUser(_userId);
    if (mounted) setState(() { _reservations = list; _isLoading = false; });
  }

  Future<void> _cancel(ReservationModel r) async {
    // PRD: cancellation cutoff is 3 hours before start time
    if (r.status != 'Aktif' && r.status != 'Berlangsung') return;
    final now = DateTime.now();
    final bookingDt = DateTime.parse('${r.reservationDate}T${r.startTime}:00');
    if (bookingDt.difference(now).inHours < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pembatalan hanya dapat dilakukan minimal 3 jam sebelum reservasi.'),
        backgroundColor: AppColors.statusCancelled,
      ));
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Reservasi?'),
        content: Text(
            'Batalkan reservasi meja ${r.tableNumber ?? r.tableId} pada ${r.reservationDate}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Kembali', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deleteRed, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (confirm == true && r.id != null) {
      await _dao.cancel(r.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Riwayat Reservasi'),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.secondaryOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.home, (route) => false),
        backgroundColor: AppColors.secondaryOrange,
        foregroundColor: Colors.white,
        tooltip: 'Kembali ke Beranda',
        child: const Icon(Icons.home_rounded, size: 28),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reservations.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.table_restaurant_rounded, size: 72,
                        color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('Belum ada reservasi',
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 16, color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Text('Buat reservasi pertama Anda sekarang!',
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: Colors.grey[400])),
                  ]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  itemCount: _reservations.length,
                  itemBuilder: (ctx, i) => _ReservationCard(
                    reservation: _reservations[i],
                    isDark: isDark,
                    onTap: () async {
                      await Navigator.pushNamed(ctx, AppRoutes.reservationDetail,
                          arguments: _reservations[i]);
                      _load();
                    },
                    onCancel: () => _cancel(_reservations[i]),
                  ),
                ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final bool isDark;
  final VoidCallback onTap, onCancel;

  const _ReservationCard({
    required this.reservation,
    required this.isDark,
    required this.onTap,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final canCancel = reservation.status == 'Aktif' || reservation.status == 'Berlangsung';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        boxShadow: [if (!isDark)
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppColors.secondaryOrange.withValues(alpha: 0.12),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.table_restaurant_rounded,
                      color: AppColors.secondaryOrange, size: 18),
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    'Meja ${reservation.tableNumber ?? reservation.tableId}',
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  Text(reservation.tableLocation ?? '',
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: Colors.grey)),
                ]),
              ]),
              StatusBadge(status: reservation.status),
            ]),
            const Divider(height: 20),
            Row(children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(reservation.reservationDate,
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 13)),
              const SizedBox(width: 16),
              const Icon(Icons.schedule_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text('${reservation.startTime} – ${reservation.endTime}',
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 13)),
            ]),
            if (canCancel) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: AppColors.deleteRed),
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined, size: 14),
                  label: const Text('Batalkan',
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
