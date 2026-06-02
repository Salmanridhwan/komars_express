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


  Future<void> _toggleActive(TableModel table) async {
    final newStatus = !table.isActive;
    final title = newStatus ? 'Aktifkan Meja?' : 'Nonaktifkan Meja?';
    final content = newStatus
        ? 'Meja ${table.tableNumber} akan diaktifkan kembali dan muncul di denah lantai.'
        : 'Meja ${table.tableNumber} akan dinonaktifkan dari denah. Data historis tetap tersimpan.';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(fontFamily: 'Outfit')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontFamily: 'Outfit')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? AppColors.statusSuccess : AppColors.deleteRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(newStatus ? 'Aktifkan' : 'Nonaktifkan', style: const TextStyle(fontFamily: 'Outfit')),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final updated = TableModel(
        id: table.id,
        tableNumber: table.tableNumber,
        capacity: table.capacity,
        location: table.location,
        isActive: newStatus,
      );
      await _dao.update(updated);
      _load();
    }
  }

  void _showTableActions(TableModel table) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.table_restaurant_rounded,
                        color: AppColors.secondaryOrange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meja ${table.tableNumber}',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Lokasi: ${table.location} • ${table.capacity} Kursi',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: AppColors.secondaryOrange),
                  title: const Text(
                    'Edit Detail Meja',
                    style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddEdit(table);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    table.isActive ? Icons.remove_circle_outline_rounded : Icons.check_circle_outline_rounded,
                    color: table.isActive ? AppColors.deleteRed : AppColors.statusSuccess,
                  ),
                  title: Text(
                    table.isActive ? 'Nonaktifkan Meja' : 'Aktifkan Meja',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      color: table.isActive ? AppColors.deleteRed : AppColors.statusSuccess,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _toggleActive(table);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryPanel() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = _tables.length;
    final active = _tables.where((t) => t.isActive).length;
    final inactive = total - active;

    final vip = _tables.where((t) => t.location == 'VIP').length;
    final indoor = _tables.where((t) => t.location == 'Indoor').length;
    final outdoor = _tables.where((t) => t.location == 'Outdoor').length;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ringkasan Status Meja',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$total Total Meja',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSummaryItem(
                label: 'Aktif',
                value: '$active',
                color: AppColors.statusSuccess,
                icon: Icons.check_circle_outline_rounded,
              ),
              _buildDivider(),
              _buildSummaryItem(
                label: 'Nonaktif',
                value: '$inactive',
                color: Colors.grey,
                icon: Icons.remove_circle_outline_rounded,
              ),
              _buildDivider(),
              _buildSummaryItem(
                label: 'VIP',
                value: '$vip',
                color: const Color(0xFF7B1FA2),
                icon: Icons.star_rounded,
              ),
              _buildDivider(),
              _buildSummaryItem(
                label: 'Indoor',
                value: '$indoor',
                color: AppColors.secondaryOrange,
                icon: Icons.chair_rounded,
              ),
              _buildDivider(),
              _buildSummaryItem(
                label: 'Outdoor',
                value: '$outdoor',
                color: Colors.green,
                icon: Icons.park_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.grey.withValues(alpha: 0.2),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 9,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeTables = _tables.where((t) => t.isActive).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: const Text(
          'Manajemen Meja',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.secondaryOrange,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEdit(),
        backgroundColor: AppColors.secondaryOrange,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.secondaryOrange))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                // ─── Tab 1: List ─────────────────────────────────────────────
                _tables.isEmpty
                    ? const Center(
                        child: Text('Belum ada meja',
                            style: TextStyle(fontFamily: 'Outfit', color: Colors.grey)))
                    : Column(
                        children: [
                          _buildSummaryPanel(),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                              itemCount: _tables.length,
                              itemBuilder: (ctx, i) {
                                final t = _tables[i];
                                return _TableListCard(
                                  table: t,
                                  isDark: isDark,
                                  onMoreTap: () => _showTableActions(t),
                                );
                              },
                            ),
                          ),
                        ],
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
                          showLegend: false,
                          onTableSelected: (t) => _showTableActions(t),
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
  final VoidCallback onMoreTap;

  const _TableListCard({
    required this.table,
    required this.isDark,
    required this.onMoreTap,
  });

  Color _locationColor(String loc) {
    switch (loc) {
      case 'VIP': return const Color(0xFF7B1FA2);
      case 'Outdoor': return Colors.green;
      default: return AppColors.secondaryOrange; // Indoor
    }
  }

  IconData _locationIcon(String loc) {
    switch (loc) {
      case 'VIP': return Icons.star_rounded;
      case 'Outdoor': return Icons.park_rounded;
      default: return Icons.chair_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locColor = _locationColor(table.location);
    final locIcon = _locationIcon(table.location);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: table.isActive ? locColor : Colors.grey,
                width: 5,
              ),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: table.isActive
                    ? locColor.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                locIcon,
                color: table.isActive ? locColor : Colors.grey,
                size: 24,
              ),
            ),
            title: Row(
              children: [
                Text(
                  table.tableNumber,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: table.isActive
                        ? locColor.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    table.location,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: table.isActive ? locColor : Colors.grey,
                    ),
                  ),
                ),
                if (!table.isActive) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Nonaktif',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.people_alt_rounded,
                    size: 14,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${table.capacity} kursi',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              child: IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: onMoreTap,
                tooltip: 'Aksi Meja',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 24,
              ),
            ),
          ),
        ),
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
