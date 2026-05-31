import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../db/table_dao.dart';
import '../models/table_model.dart';
import '../widgets/table_grid_selector.dart';

class TableManagementScreen extends StatefulWidget {
  /// Jika true, screen ditampilkan sebagai tab (tanpa AppBar & FAB sendiri).
  /// Digunakan oleh ExpressAdminDashboard (Salman).
  final bool embedded;
  const TableManagementScreen({super.key, this.embedded = false});

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen>
    with SingleTickerProviderStateMixin {
  final _dao = TableDao();
  List<TableModel> _tables = [];
  bool _isLoading = true;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final all = await _dao.getAll();
    if (mounted) setState(() { _tables = all; _isLoading = false; });
  }

  Future<void> _showAddEdit([TableModel? existing]) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _TableFormSheet(
        existing: existing,
        onSave: (table) async {
          if (existing == null) {
            await _dao.insert(table);
          } else {
            await _dao.update(table);
          }
          if (ctx.mounted) Navigator.pop(ctx, true);
        },
      ),
    );
    if (result == true) _load();
  }


  Future<void> _deactivate(TableModel table) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nonaktifkan Meja?'),
        content: Text(
            'Meja ${table.tableNumber} akan dinonaktifkan dari denah. Data historis tetap tersimpan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deleteRed, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Nonaktifkan'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _dao.deactivate(table.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeTables = _tables.where((t) => t.isActive).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Manajemen Meja'),
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.secondaryOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
              ],
              bottom: TabBar(
                controller: _tabCtrl,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Daftar Meja', icon: Icon(Icons.list_alt_rounded, size: 18)),
                  Tab(text: 'Denah Lantai', icon: Icon(Icons.grid_view_rounded, size: 18)),
                ],
              ),
            ),
      floatingActionButton: widget.embedded
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddEdit(),
              backgroundColor: AppColors.secondaryOrange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Meja',
                  style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600)),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: [
                // ─── Tab 1: List ─────────────────────────────────────────────
                _tables.isEmpty
                    ? const Center(
                        child: Text('Belum ada meja',
                            style: TextStyle(fontFamily: 'Outfit', color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                        itemCount: _tables.length,
                        itemBuilder: (ctx, i) {
                          final t = _tables[i];
                          return _TableListCard(
                            table: t,
                            isDark: isDark,
                            onEdit: () => _showAddEdit(t),
                            onDeactivate: t.isActive ? () => _deactivate(t) : null,
                          );
                        },
                      ),
                // ─── Tab 2: Floor Map (Custom Widget) ────────────────────────
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  child: activeTables.isEmpty
                      ? const Center(child: Text('Tidak ada meja aktif'))
                      : TableGridSelector(
                          tables: activeTables,
                          reservedTableIds: const {},
                          selectedTableId: null,
                          onTableSelected: (t) => _showAddEdit(t),
                        ),
                ),
              ],
            ),
    );
  }
}

class _TableListCard extends StatelessWidget {
  final TableModel table;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback? onDeactivate;

  const _TableListCard({
    required this.table,
    required this.isDark,
    required this.onEdit,
    this.onDeactivate,
  });

  Color _locationColor(String loc) {
    switch (loc) {
      case 'VIP': return const Color(0xFF7B1FA2);
      case 'Outdoor': return AppColors.primaryGreen;
      default: return AppColors.statusActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = _locationColor(table.location);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        boxShadow: [if (!isDark)
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
              color: table.isActive ? loc.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.table_restaurant_rounded,
              color: table.isActive ? loc : Colors.grey, size: 22),
        ),
        title: Row(children: [
          Text(table.tableNumber,
              style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: loc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(table.location,
                style: TextStyle(fontFamily: 'Outfit', fontSize: 10, fontWeight: FontWeight.w700, color: loc)),
          ),
          if (!table.isActive) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: const Text('Nonaktif',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey)),
            ),
          ],
        ]),
        subtitle: Text('${table.capacity} kursi',
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Colors.grey)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 18),
            color: AppColors.secondaryOrange,
            onPressed: onEdit,
            tooltip: 'Edit',
          ),
          if (onDeactivate != null)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
              color: AppColors.deleteRed,
              onPressed: onDeactivate,
              tooltip: 'Nonaktifkan',
            ),
        ]),
      ),
    );
  }
}

// ─── Bottom Sheet Form (Add / Edit Table) ────────────────────────────────────

class _TableFormSheet extends StatefulWidget {
  final TableModel? existing;
  final Future<void> Function(TableModel) onSave;

  const _TableFormSheet({this.existing, required this.onSave});

  @override
  State<_TableFormSheet> createState() => _TableFormSheetState();
}

class _TableFormSheetState extends State<_TableFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _numberCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  String _location = 'Indoor';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _numberCtrl.text = widget.existing!.tableNumber;
      _capacityCtrl.text = widget.existing!.capacity.toString();
      _location = widget.existing!.location;
    }
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final table = TableModel(
      id: widget.existing?.id,
      tableNumber: _numberCtrl.text.trim().toUpperCase(),
      capacity: int.parse(_capacityCtrl.text.trim()),
      location: _location,
      isActive: widget.existing?.isActive ?? true,
    );
    await widget.onSave(table);
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24,
          MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(widget.existing == null ? 'Tambah Meja Baru' : 'Edit Meja',
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w700)),
            IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 20),
          TextFormField(
            controller: _numberCtrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontFamily: 'Outfit'),
            decoration: const InputDecoration(
              labelText: 'Nomor Meja (mis: A1, V2)',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              prefixIcon: Icon(Icons.table_restaurant_rounded),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _capacityCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontFamily: 'Outfit'),
            decoration: const InputDecoration(
              labelText: 'Kapasitas (kursi)',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              prefixIcon: Icon(Icons.chair_rounded),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Wajib diisi';
              if (int.tryParse(v) == null || int.parse(v) < 1) return 'Masukkan angka valid';
              return null;
            },
          ),
          const SizedBox(height: 16),
          const Text('Lokasi', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Indoor', label: Text('Indoor'), icon: Icon(Icons.chair_rounded, size: 16)),
              ButtonSegment(value: 'Outdoor', label: Text('Outdoor'), icon: Icon(Icons.park_rounded, size: 16)),
              ButtonSegment(value: 'VIP', label: Text('VIP'), icon: Icon(Icons.star_rounded, size: 16)),
            ],
            selected: {_location},
            onSelectionChanged: (s) => setState(() => _location = s.first),
            style: ButtonStyle(
              textStyle: WidgetStateProperty.all(
                const TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(widget.existing == null ? 'Tambah Meja' : 'Simpan Perubahan',
                      style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }
}
