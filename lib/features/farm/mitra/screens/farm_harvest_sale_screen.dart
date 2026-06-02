import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komars_express/core/constants/app_colors.dart';
import 'package:komars_express/core/database/database_helper.dart';
import '../models/mitra_model.dart';
import '../models/harvest_sale_model.dart';

/// Layar Jual Panen untuk User KomarFarm.
/// User memilih mitra, mengisi data hasil panen, dan melihat riwayat penjualan.
class FarmHarvestSaleScreen extends StatefulWidget {
  final int userId;
  const FarmHarvestSaleScreen({super.key, required this.userId});

  @override
  State<FarmHarvestSaleScreen> createState() => _FarmHarvestSaleScreenState();
}

class _FarmHarvestSaleScreenState extends State<FarmHarvestSaleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.sell_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'Jual Hasil Panen',
              style: TextStyle(
                  fontFamily: 'Outfit', fontWeight: FontWeight.w800),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGreen,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
              fontFamily: 'Outfit', fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Jual Panen'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SellFormTab(userId: widget.userId),
          _SaleHistoryTab(userId: widget.userId),
        ],
      ),
    );
  }
}

// ── Tab Form Jual ─────────────────────────────────────────────────────────────

class _SellFormTab extends StatefulWidget {
  final int userId;
  const _SellFormTab({required this.userId});

  @override
  State<_SellFormTab> createState() => _SellFormTabState();
}

class _SellFormTabState extends State<_SellFormTab> {
  final _formKey = GlobalKey<FormState>();
  final _harvestNameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  List<MitraPartnership> _mitras = [];
  MitraPartnership? _selectedMitra;
  String _selectedFarmType = 'unggas';
  bool _loading = true;
  bool _submitting = false;
  double _totalPrice = 0;

  /// Kategori jenis usaha tani — harus sinkron dengan preset di farm_package_form_screen
  static const Map<String, String> _farmTypeLabels = {
    'unggas': '🐔 Unggas',
    'ikan': '🐟 Ikan',
    'sayur': '🥬 Sayur',
    'campuran': '🌾 Campuran',
  };

  @override
  void initState() {
    super.initState();
    _loadMitra();
    _qtyCtrl.addListener(_calcTotal);
    _priceCtrl.addListener(_calcTotal);
  }

  void _calcTotal() {
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    setState(() => _totalPrice = qty * price);
  }

  Future<void> _loadMitra() async {
    setState(() => _loading = true);
    try {
      await DatabaseHelper.instance.database;
      final dao = DatabaseHelper.instance.mitraDao;
      await dao.seedDefaultMitra();
      final list = await dao.getActive();
      if (mounted) {
        setState(() {
          _mitras = list;
          if (list.isNotEmpty) _selectedMitra = list.first;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMitra == null) return;

    setState(() => _submitting = true);
    try {
      await DatabaseHelper.instance.database;
      final dao = DatabaseHelper.instance.harvestSaleDao;
      await dao.insert(HarvestSale(
        farmerUserId: widget.userId,
        mitraId: _selectedMitra!.id!,
        mitraName: _selectedMitra!.mitraName,
        farmType: _selectedFarmType,
        harvestName: _harvestNameCtrl.text.trim(),
        quantityKg: double.parse(_qtyCtrl.text),
        pricePerKg: double.parse(_priceCtrl.text),
        totalPrice: _totalPrice,
        status: 'Menunggu',
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ));

      if (mounted) {
        _harvestNameCtrl.clear();
        _qtyCtrl.clear();
        _priceCtrl.clear();
        _notesCtrl.clear();
        setState(() { _totalPrice = 0; _submitting = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Penjualan berhasil dikirim! Menunggu konfirmasi mitra.'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _harvestNameCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info Banner ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryGreenSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.primaryGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.primaryGreen, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Hasil panen Anda akan dikirim ke mitra untuk dikonfirmasi. Pantau status di tab Riwayat.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: AppColors.primaryGreenDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Pilih Mitra ────────────────────────────────────────────────
            _SectionLabel(label: 'Pilih Mitra Tujuan'),
            const SizedBox(height: 10),
            if (_mitras.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Text(
                  'Belum ada mitra tersedia',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 13),
                ),
              )
            else
              ...List.generate(_mitras.length, (i) {
                final m = _mitras[i];
                final isSelected = _selectedMitra?.id == m.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMitra = m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryGreenSurface
                          : (isDark ? AppColors.darkCard : Colors.white),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : (isDark
                                ? AppColors.darkDivider
                                : Colors.grey.shade200),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.storefront_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.mitraName,
                                  style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? AppColors.primaryGreenDark
                                          : null)),
                              Text(m.companyName,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : Colors.grey.shade500,
                                  )),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.primaryGreen),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 20),

            // ── Jenis Tani ─────────────────────────────────────────────────
            _SectionLabel(label: 'Jenis Usaha Tani'),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _farmTypeLabels.entries.map((e) {
                  final isSelected = _selectedFarmType == e.key;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFarmType = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : AppColors.primaryGreenSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryGreen
                              : AppColors.primaryGreen
                                  .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppColors.primaryGreenDark,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // ── Nama Hasil Panen ───────────────────────────────────────────
            _SectionLabel(label: 'Nama Hasil Panen'),
            const SizedBox(height: 8),
            _FieldBox(
              child: TextFormField(
                controller: _harvestNameCtrl,
                decoration: const InputDecoration(
                  hintText: 'cth: Ayam Kampung, Lele Segar, Bayam',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.grass_rounded,
                      color: AppColors.primaryGreen),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
            ),

            const SizedBox(height: 14),

            // ── Berat & Harga ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(label: 'Berat (kg)'),
                      const SizedBox(height: 8),
                      _FieldBox(
                        child: TextFormField(
                          controller: _qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'))
                          ],
                          decoration: const InputDecoration(
                            hintText: '0.0',
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.scale_rounded,
                                color: AppColors.primaryGreen),
                            suffixText: 'kg',
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Wajib diisi';
                            if ((double.tryParse(v) ?? 0) <= 0) {
                              return '> 0';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(label: 'Harga/kg (Rp)'),
                      const SizedBox(height: 8),
                      _FieldBox(
                        child: TextFormField(
                          controller: _priceCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: const InputDecoration(
                            hintText: '0',
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.attach_money_rounded,
                                color: AppColors.primaryGreen),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Wajib diisi';
                            if ((double.tryParse(v) ?? 0) <= 0) {
                              return '> 0';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Total ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Nilai Panen',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Rp ${_formatCurrency(_totalPrice)}',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Catatan ────────────────────────────────────────────────────
            _SectionLabel(label: 'Catatan (opsional)'),
            const SizedBox(height: 8),
            _FieldBox(
              child: TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'cth: panen pagi, kualitas premium, dll.',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.notes_rounded,
                      color: AppColors.primaryGreen),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Submit ─────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _submitting ? 'Mengirim...' : 'Kirim ke Mitra',
                  style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double val) {
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(val % 1000000 == 0 ? 0 : 1)}jt';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(val % 1000 == 0 ? 0 : 1)}rb';
    }
    return val.toStringAsFixed(0);
  }
}

// ── Tab Riwayat ───────────────────────────────────────────────────────────────

class _SaleHistoryTab extends StatefulWidget {
  final int userId;
  const _SaleHistoryTab({required this.userId});

  @override
  State<_SaleHistoryTab> createState() => _SaleHistoryTabState();
}

class _SaleHistoryTabState extends State<_SaleHistoryTab> {
  List<HarvestSale> _sales = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await DatabaseHelper.instance.database;
      final dao = DatabaseHelper.instance.harvestSaleDao;
      final list = await dao.getByFarmer(widget.userId);
      if (mounted) setState(() { _sales = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }
    if (_sales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sell_outlined, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Belum ada riwayat penjualan',
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            Text('Jual hasil panen Anda melalui tab Jual Panen',
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: Colors.grey.shade400)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sales.length,
        itemBuilder: (ctx, i) => _SaleCard(sale: _sales[i]),
      ),
    );
  }
}

// ── Sale Card ─────────────────────────────────────────────────────────────────

class _SaleCard extends StatelessWidget {
  final HarvestSale sale;
  const _SaleCard({required this.sale});

  Color _statusColor(String status) {
    switch (status) {
      case 'Diterima':
        return AppColors.statusSuccess;
      case 'Ditolak':
        return AppColors.statusCancelled;
      default:
        return AppColors.statusPending;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Diterima':
        return Icons.check_circle_rounded;
      case 'Ditolak':
        return Icons.cancel_rounded;
      default:
        return Icons.hourglass_empty_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _statusColor(sale.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: color.withValues(alpha: 0.3)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreenSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.grass_rounded,
                    color: AppColors.primaryGreen, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sale.harvestName,
                        style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    Text(
                      '→ ${sale.mitraName}',
                      style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon(sale.status), color: color, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      sale.status,
                      style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              _InfoChip(label: '${sale.quantityKg} kg'),
              const SizedBox(width: 8),
              _InfoChip(label: 'Rp ${_fmt(sale.pricePerKg)}/kg'),
              const Spacer(),
              Text(
                'Total: Rp ${_fmt(sale.totalPrice)}',
                style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryGreen),
              ),
            ],
          ),
          if (sale.notes != null && sale.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '📝 ${sale.notes}',
              style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : Colors.grey.shade500),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            sale.createdAt?.substring(0, 10) ?? '',
            style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}jt';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}rb';
    return v.toStringAsFixed(0);
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryGreenDark,
      ),
    );
  }
}

class _FieldBox extends StatelessWidget {
  final Widget child;
  const _FieldBox({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.darkDivider : Colors.grey.shade200),
      ),
      child: child,
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryGreenSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryGreenDark,
        ),
      ),
    );
  }
}
