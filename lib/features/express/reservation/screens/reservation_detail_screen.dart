import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../db/reservation_dao.dart';
import '../models/reservation_model.dart';

class ReservationDetailScreen extends StatefulWidget {
  final ReservationModel reservation;

  const ReservationDetailScreen({super.key, required this.reservation});

  @override
  State<ReservationDetailScreen> createState() => _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  final _dao = ReservationDao();
  late ReservationModel _reservation;
  bool _cancelling = false;
  bool _isEditing = false;
  String? _editStartTime;
  String? _editEndTime;

  @override
  void initState() {
    super.initState();
    _reservation = widget.reservation;
  }

  Future<void> _reload() async {
    final r = await _dao.getById(_reservation.id!);
    if (r != null && mounted) setState(() => _reservation = r);
  }

  Future<void> _cancel() async {
    // PRD: 3-hour cutoff
    final now = DateTime.now();
    final bookingDt =
        DateTime.parse('${_reservation.reservationDate}T${_reservation.startTime}:00');
    if (bookingDt.difference(now).inHours < 3) {
      _showSnack('Pembatalan hanya dapat dilakukan minimal 3 jam sebelum reservasi.', true);
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Reservasi?'),
        content: const Text('Tindakan ini tidak dapat diurungkan.'),
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
    if (confirm == true && _reservation.id != null) {
      setState(() => _cancelling = true);
      await _dao.cancel(_reservation.id!);
      await _reload();
      setState(() => _cancelling = false);
    }
  }

  Future<void> _saveEdit() async {
    if (_editStartTime == null && _editEndTime == null) return;
    final updated = _reservation.copyWith(
      startTime: _editStartTime ?? _reservation.startTime,
      endTime: _editEndTime ?? _reservation.endTime,
    );
    await _dao.update(updated);
    await _reload();
    setState(() { _isEditing = false; _editStartTime = null; _editEndTime = null; });
    _showSnack('Jadwal berhasil diperbarui.');
  }

  Future<String?> _pickTime(String initial) async {
    final parts = initial.split(':');
    final tod = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
    );
    if (tod == null) return null;
    return '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';
  }

  void _showSnack(String msg, [bool isError = false]) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.statusCancelled : AppColors.statusSuccess,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canEdit = _reservation.status == 'Aktif';
    final canCancel = _reservation.status == 'Aktif' || _reservation.status == 'Berlangsung';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Detail Reservasi'),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.secondaryOrange,
        foregroundColor: Colors.white,
        actions: [
          if (canEdit)
            TextButton(
              onPressed: () => setState(() => _isEditing = !_isEditing),
              child: Text(_isEditing ? 'Batal Edit' : 'Edit',
                  style: const TextStyle(color: Colors.white, fontFamily: 'Outfit')),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Status header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.expressGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Meja ${_reservation.tableNumber ?? _reservation.tableId}',
                    style: const TextStyle(fontFamily: 'Outfit', color: Colors.white,
                        fontSize: 22, fontWeight: FontWeight.w800)),
                StatusBadge(status: _reservation.status),
              ]),
              const SizedBox(height: 4),
              Text(_reservation.tableLocation ?? '',
                  style: TextStyle(fontFamily: 'Outfit', color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 24),

          // Details card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
            ),
            child: Column(children: [
              _DetailRow(label: 'Tanggal', value: _reservation.reservationDate,
                  icon: Icons.calendar_today_rounded),
              const Divider(height: 24),
              // Editable times
              if (!_isEditing) ...[
                _DetailRow(label: 'Mulai', value: _reservation.startTime, icon: Icons.schedule_rounded),
                const Divider(height: 24),
                _DetailRow(label: 'Selesai', value: _reservation.endTime, icon: Icons.alarm_rounded),
              ] else ...[
                _EditableTimeRow(
                  label: 'Mulai',
                  value: _editStartTime ?? _reservation.startTime,
                  onTap: () async {
                    final t = await _pickTime(_editStartTime ?? _reservation.startTime);
                    if (t != null) setState(() => _editStartTime = t);
                  },
                ),
                const Divider(height: 24),
                _EditableTimeRow(
                  label: 'Selesai',
                  value: _editEndTime ?? _reservation.endTime,
                  onTap: () async {
                    final t = await _pickTime(_editEndTime ?? _reservation.endTime);
                    if (t != null) setState(() => _editEndTime = t);
                  },
                ),
              ],
              if (_reservation.notes != null && _reservation.notes!.isNotEmpty) ...[
                const Divider(height: 24),
                _DetailRow(label: 'Catatan', value: _reservation.notes!, icon: Icons.notes_rounded),
              ],
            ]),
          ),

          // Edit save button
          if (_isEditing) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveEdit,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Simpan Perubahan',
                    style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],

          // Cancel button
          if (canCancel && !_isEditing) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _cancelling ? null : _cancel,
                icon: _cancelling
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.deleteRed))
                    : const Icon(Icons.cancel_outlined),
                label: const Text('Batalkan Reservasi',
                    style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.deleteRed,
                  side: const BorderSide(color: AppColors.deleteRed),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final IconData icon;

  const _DetailRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.secondaryOrange),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: Colors.grey)),
        Text(value, style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w600)),
      ])),
    ]);
  }
}

class _EditableTimeRow extends StatelessWidget {
  final String label, value;
  final VoidCallback onTap;

  const _EditableTimeRow({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        const Icon(Icons.schedule_rounded, size: 18, color: AppColors.secondaryOrange),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: Colors.grey)),
          Text(value, style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w600)),
        ])),
        const Icon(Icons.edit_rounded, size: 14, color: AppColors.secondaryOrange),
      ]),
    );
  }
}
