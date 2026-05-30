import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/pref_keys.dart';
import '../../../../core/routes/app_routes.dart';
import '../../reservation/db/reservation_dao.dart';
import '../../reservation/models/reservation_model.dart';
import '../../table/db/table_dao.dart';
import '../../table/models/table_model.dart';
import '../../table/widgets/table_grid_selector.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final _tableDao = TableDao();
  final _reservationDao = ReservationDao();

  // Multi-step state
  int _step = 0; // 0=date, 1=time, 2=table, 3=confirm
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _startTime = '11:00';
  String _endTime = '13:00';
  TableModel? _selectedTable;
  final _notesController = TextEditingController();

  List<TableModel> _tables = [];
  Set<int> _reservedTableIds = {};
  bool _loadingTables = false;
  bool _submitting = false;

  // In a real app, get from session. Here we default to 1.
  final int _userId = 1;

  @override
  void initState() {
    super.initState();
    _restorePrefs();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _restorePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(PrefKeys.reservationDatePref) ?? '';
    if (savedDate.isNotEmpty) {
      final d = DateTime.tryParse(savedDate);
      if (d != null && d.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
        setState(() {
          _selectedDay = d;
          _focusedDay = d;
        });
      }
    }
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedDay != null) {
      await prefs.setString(
          PrefKeys.reservationDatePref,
          _selectedDay!.toIso8601String().split('T').first);
    }
    if (_selectedTable != null && _selectedTable!.id != null) {
      await prefs.setInt(PrefKeys.selectedTableId, _selectedTable!.id!);
    }
  }

  Future<void> _loadTablesForDate() async {
    if (_selectedDay == null) return;
    setState(() => _loadingTables = true);
    final dateStr = _selectedDay!.toIso8601String().split('T').first;
    final allTables = await _tableDao.getActive();
    final reservations = await _reservationDao.getByDate(dateStr);
    final reserved = <int>{};
    for (final res in reservations) {
      if (_timesOverlap(_startTime, _endTime, res.startTime, res.endTime)) {
        reserved.add(res.tableId);
      }
    }
    if (mounted) {
      setState(() {
        _tables = allTables;
        _reservedTableIds = reserved;
        _selectedTable = null; // reset selection when date/time changes
        _loadingTables = false;
      });
    }
  }

  bool _timesOverlap(String s1, String e1, String s2, String e2) {
    int toMin(String t) {
      final p = t.split(':');
      return int.parse(p[0]) * 60 + int.parse(p[1]);
    }
    return toMin(s1) < toMin(e2) && toMin(e1) > toMin(s2);
  }

  Future<void> _submit() async {
    if (_selectedDay == null || _selectedTable == null) return;
    final now = DateTime.now();
    final bookingDt = DateTime(
      _selectedDay!.year, _selectedDay!.month, _selectedDay!.day,
      int.parse(_startTime.split(':')[0]), int.parse(_startTime.split(':')[1]),
    );
    if (bookingDt.isBefore(now.add(const Duration(hours: 1)))) {
      _showSnack('Reservasi harus minimal 1 jam dari sekarang.', isError: true);
      return;
    }
    setState(() => _submitting = true);
    final dateStr = _selectedDay!.toIso8601String().split('T').first;
    // Double-check conflict
    final conflicts = await _reservationDao.getByTableAndDate(_selectedTable!.id!, dateStr);
    final hasConflict = conflicts.any(
        (r) => _timesOverlap(_startTime, _endTime, r.startTime, r.endTime));
    if (hasConflict) {
      setState(() => _submitting = false);
      _showSnack('Meja sudah terpesan. Pilih waktu atau meja lain.', isError: true);
      return;
    }
    final reservation = ReservationModel(
      userId: _userId,
      tableId: _selectedTable!.id!,
      reservationDate: dateStr,
      startTime: _startTime,
      endTime: _endTime,
      status: 'Aktif',
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );
    final id = await _reservationDao.insert(reservation);
    if (mounted) {
      setState(() => _submitting = false);
      await _savePrefs();
      Navigator.pushReplacementNamed(
        context, AppRoutes.reservationConfirmation, arguments: id);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.statusCancelled : AppColors.statusSuccess,
    ));
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Reservasi Meja'),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.secondaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.reservationHistory),
            icon: const Icon(Icons.history_rounded, color: Colors.white, size: 18),
            label: const Text('Riwayat',
                style: TextStyle(color: Colors.white, fontFamily: 'Outfit', fontSize: 13)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStepper(isDark),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.3, 0), end: Offset.zero)
                        .animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: _buildStep(isDark),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(isDark),
    );
  }

  Widget _buildStepper(bool isDark) {
    const labels = ['Tanggal', 'Waktu', 'Meja', 'Konfirmasi'];
    return Container(
      color: isDark ? AppColors.darkSurface : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(labels.length * 2 - 1, (i) {
          // Even indices → step circles; odd indices → connector lines
          if (i.isOdd) {
            final stepIndex = i ~/ 2;
            final isDone = stepIndex < _step;
            return Expanded(
              child: Container(
                height: 2,
                color: isDone ? AppColors.secondaryOrange : AppColors.lightDivider,
              ),
            );
          }
          final idx = i ~/ 2;
          final active = idx == _step;
          final done = idx < _step;
          return SizedBox(
            width: 56,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? AppColors.secondaryOrange
                        : done
                            ? AppColors.secondaryOrangeLight
                            : isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                        : Text('${idx + 1}',
                            style: TextStyle(
                                color: active ? Colors.white : Colors.grey,
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  labels[idx],
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 9,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    color: active ? AppColors.secondaryOrange : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep(bool isDark) {
    switch (_step) {
      case 0: return _StepDate(
          key: const ValueKey(0),
          isDark: isDark,
          focusedDay: _focusedDay,
          selectedDay: _selectedDay,
          onDaySelected: (sel, foc) => setState(() { _selectedDay = sel; _focusedDay = foc; }));
      case 1: return _StepTime(
          key: const ValueKey(1),
          isDark: isDark,
          startTime: _startTime,
          endTime: _endTime,
          onPickStart: () async { final t = await _pickTime(_startTime); if (t != null) setState(() => _startTime = t); },
          onPickEnd: () async { final t = await _pickTime(_endTime); if (t != null) setState(() => _endTime = t); });
      case 2: return _StepTable(
          key: const ValueKey(2),
          isDark: isDark,
          loading: _loadingTables,
          tables: _tables,
          reservedIds: _reservedTableIds,
          selectedId: _selectedTable?.id,
          onSelected: (t) => setState(() => _selectedTable = t));
      case 3: return _StepConfirm(
          key: const ValueKey(3),
          isDark: isDark,
          selectedDay: _selectedDay,
          startTime: _startTime,
          endTime: _endTime,
          table: _selectedTable,
          notesController: _notesController);
      default: return const SizedBox();
    }
  }

  Widget _buildBottomBar(bool isDark) {
    final canNext = _step == 0 ? _selectedDay != null
        : _step == 2 ? _selectedTable != null : true;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(top: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.lightDivider)),
      ),
      child: Row(
        children: [
          if (_step > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step--),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondaryOrange,
                  side: const BorderSide(color: AppColors.secondaryOrange),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Kembali',
                    style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: canNext
                  ? () async {
                      if (_step == 1) await _loadTablesForDate();
                      if (_step < 3) {
                        setState(() => _step++);
                      } else {
                        await _submit();
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryOrange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_step < 3 ? 'Lanjut' : 'Buat Reservasi',
                      style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step Widgets ─────────────────────────────────────────────────────────────

class _StepDate extends StatelessWidget {
  final bool isDark;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Function(DateTime, DateTime) onDaySelected;

  const _StepDate({super.key, required this.isDark, required this.focusedDay,
    required this.selectedDay, required this.onDaySelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pilih Tanggal Reservasi',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Pilih tanggal dine-in Anda',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
            boxShadow: [if (!isDark)
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          // ─── table_calendar Library (PRD §5.2.C) ─────────────────────────
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 90)),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            onDaySelected: onDaySelected,
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                  color: AppColors.secondaryOrange, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(
                  color: AppColors.secondaryOrange.withValues(alpha: 0.3),
                  shape: BoxShape.circle),
              weekendTextStyle: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontFamily: 'Outfit'),
              defaultTextStyle: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  fontFamily: 'Outfit'),
              disabledTextStyle: const TextStyle(color: Colors.grey, fontFamily: 'Outfit'),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                  fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: AppColors.secondaryOrange),
              rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: AppColors.secondaryOrange),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepTime extends StatelessWidget {
  final bool isDark;
  final String startTime, endTime;
  final VoidCallback onPickStart, onPickEnd;

  const _StepTime({super.key, required this.isDark, required this.startTime,
    required this.endTime, required this.onPickStart, required this.onPickEnd});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pilih Waktu',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Tentukan jam mulai dan selesai',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        const SizedBox(height: 24),
        _TimeCard(isDark: isDark, label: 'Waktu Mulai', icon: Icons.schedule_rounded,
            value: startTime, onTap: onPickStart),
        const SizedBox(height: 16),
        _TimeCard(isDark: isDark, label: 'Waktu Selesai', icon: Icons.alarm_rounded,
            value: endTime, onTap: onPickEnd),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.secondaryOrangeSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.secondaryOrangeLight.withValues(alpha: 0.5)),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded, size: 16, color: AppColors.secondaryOrange),
            SizedBox(width: 8),
            Expanded(child: Text(
                'Pembatalan reservasi maksimal 3 jam sebelum waktu mulai.',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 12,
                    color: AppColors.secondaryOrangeDark))),
          ]),
        ),
      ],
    );
  }
}

class _TimeCard extends StatelessWidget {
  final bool isDark;
  final String label, value;
  final IconData icon;
  final VoidCallback onTap;

  const _TimeCard({required this.isDark, required this.label, required this.value,
    required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
          boxShadow: [if (!isDark)
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.secondaryOrange.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.secondaryOrange, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: Colors.grey)),
              Text(value, style: const TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.w700)),
            ],
          )),
          const Icon(Icons.edit_rounded, size: 16, color: Colors.grey),
        ]),
      ),
    );
  }
}

class _StepTable extends StatelessWidget {
  final bool isDark, loading;
  final List<TableModel> tables;
  final Set<int> reservedIds;
  final int? selectedId;
  final ValueChanged<TableModel> onSelected;

  const _StepTable({super.key, required this.isDark, required this.loading,
    required this.tables, required this.reservedIds, required this.selectedId,
    required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pilih Meja',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Denah lantai restoran Komars Express',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        const SizedBox(height: 20),
        loading
            ? const Center(child: CircularProgressIndicator())
            // ─── Custom Widget (PRD §5.2.C) ─────────────────────────────────
            : TableGridSelector(
                tables: tables,
                reservedTableIds: reservedIds,
                selectedTableId: selectedId,
                onTableSelected: onSelected,
              ),
      ],
    );
  }
}

class _StepConfirm extends StatelessWidget {
  final bool isDark;
  final DateTime? selectedDay;
  final String startTime, endTime;
  final TableModel? table;
  final TextEditingController notesController;

  const _StepConfirm({super.key, required this.isDark, required this.selectedDay,
    required this.startTime, required this.endTime, required this.table,
    required this.notesController});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Konfirmasi Reservasi',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: cardColor, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
            boxShadow: [if (!isDark)
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(children: [
            _Row(icon: Icons.calendar_today_rounded, label: 'Tanggal',
                value: selectedDay?.toIso8601String().split('T').first ?? '-',
                color: AppColors.secondaryOrange, border: border),
            _Row(icon: Icons.schedule_rounded, label: 'Waktu',
                value: '$startTime – $endTime',
                color: AppColors.primaryGreen, border: border),
            _Row(icon: Icons.table_restaurant_rounded, label: 'Meja',
                value: table != null
                    ? '${table!.tableNumber} (${table!.location}) — ${table!.capacity} kursi'
                    : '-',
                color: AppColors.statusActive, border: border, last: true),
          ]),
        ),
        const SizedBox(height: 20),
        Text('Catatan (opsional)',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: notesController,
          maxLines: 3,
          style: const TextStyle(fontFamily: 'Outfit'),
          decoration: InputDecoration(
            hintText: 'Mis: perayaan ulang tahun, kursi khusus...',
            hintStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 13),
            filled: true, fillColor: cardColor,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.secondaryOrange, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color, border;
  final bool last;

  const _Row({required this.icon, required this.label, required this.value,
    required this.color, required this.border, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: Colors.grey)),
              Text(value, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w600)),
            ])),
          ]),
        ),
        if (!last) Divider(height: 1, color: border),
      ],
    );
  }
}
