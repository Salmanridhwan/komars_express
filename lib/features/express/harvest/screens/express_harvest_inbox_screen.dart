import 'package:flutter/material.dart';
import 'package:komars_express/core/constants/app_colors.dart';
import 'package:komars_express/core/database/database_helper.dart';
import '../../../farm/mitra/models/harvest_sale_model.dart';

/// Layar Panen Masuk untuk Admin KomarExpress.
/// Menerima dan mengelola hasil panen dari petani mitra KomarFarm.
class ExpressHarvestInboxScreen extends StatefulWidget {
  final bool embedded;
  const ExpressHarvestInboxScreen({super.key, this.embedded = false});

  @override
  State<ExpressHarvestInboxScreen> createState() =>
      _ExpressHarvestInboxScreenState();
}

class _ExpressHarvestInboxScreenState
    extends State<ExpressHarvestInboxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<HarvestSale> _allSales = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await DatabaseHelper.instance.database;
      final dao = DatabaseHelper.instance.harvestSaleDao;
      final list = await dao.getAll();
      if (mounted) setState(() { _allSales = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<HarvestSale> get _pending =>
      _allSales.where((s) => s.status == 'Menunggu').toList();
  List<HarvestSale> get _accepted =>
      _allSales.where((s) => s.status == 'Diterima').toList();
  List<HarvestSale> get _rejected =>
      _allSales.where((s) => s.status == 'Ditolak').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Panen Masuk'),
              backgroundColor: AppColors.secondaryOrange,
              foregroundColor: Colors.white,
            ),
      body: Column(
        children: [
          // ── Header Stats ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            decoration: const BoxDecoration(
              gradient: AppColors.expressGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inbox Hasil Panen',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Panen dari mitra petani KomarFarm',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 16),
                // Mini stats row
                Row(
                  children: [
                    _MiniStat(
                        label: 'Menunggu',
                        value: _pending.length.toString(),
                        color: AppColors.statusPending),
                    const SizedBox(width: 10),
                    _MiniStat(
                        label: 'Diterima',
                        value: _accepted.length.toString(),
                        color: AppColors.statusSuccess),
                    const SizedBox(width: 10),
                    _MiniStat(
                        label: 'Ditolak',
                        value: _rejected.length.toString(),
                        color: AppColors.statusCancelled),
                  ],
                ),
                const SizedBox(height: 16),
                // Tab bar
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                      fontFamily: 'Outfit', fontWeight: FontWeight.w700),
                  tabs: [
                    Tab(text: 'Menunggu (${_pending.length})'),
                    Tab(text: 'Diterima'),
                    Tab(text: 'Ditolak'),
                  ],
                ),
              ],
            ),
          ),

          // ── Tab Content ───────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.secondaryOrange))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _HarvestList(
                          sales: _pending,
                          onRefresh: _load,
                          showActions: true),
                      _HarvestList(sales: _accepted, onRefresh: _load),
                      _HarvestList(sales: _rejected, onRefresh: _load),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Mini Stat Badge ───────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── List Widget ───────────────────────────────────────────────────────────────

class _HarvestList extends StatelessWidget {
  final List<HarvestSale> sales;
  final Future<void> Function() onRefresh;
  final bool showActions;

  const _HarvestList({
    required this.sales,
    required this.onRefresh,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              showActions ? 'Tidak ada panen menunggu' : 'Tidak ada data',
              style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.secondaryOrange,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sales.length,
        itemBuilder: (ctx, i) =>
            _HarvestCard(sale: sales[i], showActions: showActions,
                onAction: onRefresh),
      ),
    );
  }
}

// ── Harvest Card ──────────────────────────────────────────────────────────────

class _HarvestCard extends StatelessWidget {
  final HarvestSale sale;
  final bool showActions;
  final Future<void> Function() onAction;

  const _HarvestCard({
    required this.sale,
    required this.showActions,
    required this.onAction,
  });

  Future<void> _updateStatus(BuildContext ctx, String newStatus) async {
    try {
      await DatabaseHelper.instance.database;
      await DatabaseHelper.instance.harvestSaleDao
          .updateStatus(sale.id!, newStatus);
      await onAction();
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text(
            newStatus == 'Diterima'
                ? '✅ Panen diterima!'
                : '❌ Panen ditolak.',
          ),
          backgroundColor: newStatus == 'Diterima'
              ? AppColors.statusSuccess
              : AppColors.statusCancelled,
        ));
      }
    } catch (e) {
      debugPrint('Error update status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? AppColors.darkDivider
              : AppColors.secondaryOrange.withValues(alpha: 0.2),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: AppColors.secondaryOrange.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Farmer Info ──────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreenSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: AppColors.primaryGreen, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sale.farmerName ?? 'Petani',
                            style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14,
                                fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Petani KomarFarm',
                            style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      sale.createdAt?.substring(0, 10) ?? '',
                      style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : Colors.grey.shade400),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // ── Harvest Info ─────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.grass_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sale.harvestName,
                            style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16,
                                fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${sale.farmType} · ${sale.quantityKg} kg',
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
                  ],
                ),

                const SizedBox(height: 10),

                // ── Price ────────────────────────────────────────────────
                Row(
                  children: [
                    _PriceChip(
                        label:
                            'Rp ${_fmt(sale.pricePerKg)}/kg'),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Total',
                            style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11,
                                color: Colors.grey)),
                        Text(
                          'Rp ${_fmt(sale.totalPrice)}',
                          style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryGreen),
                        ),
                      ],
                    ),
                  ],
                ),

                if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.notes_rounded,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            sale.notes!,
                            style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Actions ───────────────────────────────────────────────────
          if (showActions)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : AppColors.lightCard,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateStatus(context, 'Ditolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.statusCancelled,
                        side: const BorderSide(
                            color: AppColors.statusCancelled),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Tolak',
                          style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus(context, 'Diterima'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusSuccess,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Terima Panen',
                          style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : AppColors.lightCard,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    sale.status == 'Diterima'
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 14,
                    color: sale.status == 'Diterima'
                        ? AppColors.statusSuccess
                        : AppColors.statusCancelled,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    sale.status == 'Diterima'
                        ? 'Panen telah diterima'
                        : 'Panen ditolak',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: sale.status == 'Diterima'
                          ? AppColors.statusSuccess
                          : AppColors.statusCancelled,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
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

class _PriceChip extends StatelessWidget {
  final String label;
  const _PriceChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.secondaryOrangeSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.secondaryOrangeDark,
        ),
      ),
    );
  }
}
