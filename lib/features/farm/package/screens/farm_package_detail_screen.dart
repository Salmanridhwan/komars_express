import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/pref_keys.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/komars_button.dart';
import '../models/farm_package_model.dart';

class FarmPackageDetailScreen extends StatefulWidget {
  final FarmPackage package;
  final bool? purchased;

  const FarmPackageDetailScreen({
    super.key,
    required this.package,
    this.purchased,
  });

  @override
  State<FarmPackageDetailScreen> createState() =>
      _FarmPackageDetailScreenState();
}

class _FarmPackageDetailScreenState extends State<FarmPackageDetailScreen> {
  bool _isPurchased = false;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _isPurchased = widget.purchased ?? false;
    _checkPurchaseStatus();
  }

  Future<void> _checkPurchaseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(PrefKeys.userSessionToken) ?? '';
    final userId = int.tryParse(token);

    if (mounted) {
      setState(() => _userId = userId);
    }

    if (_isPurchased) return;

    if (userId != null) {
      final db = DatabaseHelper.instance;
      final purchased = await db.purchasedPackageDao.hasPurchased(
        userId,
        widget.package.id,
      );
      if (mounted) {
        setState(() => _isPurchased = purchased);
      }
    }
  }

  Future<void> _navToPayment() async {
    if (_userId == null) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(PrefKeys.userSessionToken) ?? '';
      _userId = int.tryParse(token);
    }

    if (_userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    if (!mounted) return;
    final success = await Navigator.pushNamed<bool>(
      context,
      AppRoutes.farmPackagePayment,
      arguments: {'package': widget.package, 'userId': _userId!},
    );

    if (success == true && mounted) {
      setState(() => _isPurchased = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.spa_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Detail Paket Tani',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Card ───────────────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.agriculture_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.package.title,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Tipe: ${widget.package.farmType.toUpperCase()}',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Deskripsi ─────────────────────────────────────────────────────
            _SectionTitle(title: 'Deskripsi', isDark: isDark),
            const SizedBox(height: 8),
            Text(
              widget.package.description,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                height: 1.6,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // ── Detail Finansial ──────────────────────────────────────────────
            _SectionTitle(title: 'Detail Finansial', isDark: isDark),
            const SizedBox(height: 12),
            _FinancialCard(isDark: isDark, children: [
              _DetailRow(
                label: 'Modal Awal (Minimum)',
                value: 'Rp ${_formatNumber(widget.package.initialCapitalMin)}',
                isDark: isDark,
              ),
              _DetailRow(
                label: 'Modal Awal (Rekomendasi)',
                value: 'Rp ${_formatNumber(widget.package.initialCapitalRec)}',
                isDark: isDark,
              ),
              _DetailRow(
                label: 'Periode ROI',
                value: '${widget.package.roiMonths} bulan',
                isDark: isDark,
              ),
              _DetailRow(
                label: 'Estimasi Pendapatan/Bulan',
                value: 'Rp ${_formatNumber(widget.package.monthlyIncomeEst)}',
                isDark: isDark,
              ),
              _DetailRow(
                label: 'Waktu Panen',
                value: '${widget.package.harvestTimeDays} hari',
                isDark: isDark,
                isLast: true,
              ),
            ]),
            const SizedBox(height: 24),

            if (_isPurchased) ...[
              // ── Langkah-langkah ───────────────────────────────────────────
              _SectionTitle(title: 'Langkah Implementasi', isDark: isDark),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.package.steps.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.package.steps[index],
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              height: 1.5,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // ── Peralatan ─────────────────────────────────────────────────
              _SectionTitle(title: 'Peralatan yang Dibutuhkan', isDark: isDark),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.package.equipmentList.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primaryGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.package.equipmentList[index],
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ] else ...[
              // ── Konten Terkunci ───────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCard
                      : AppColors.primaryGreenSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkDivider
                        : AppColors.farmBadgeBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        size: 36,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Panduan Eksklusif Terkunci',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.primaryGreenDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Beli paket starter kit ini untuk membuka langkah-langkah implementasi dan daftar peralatan yang diperlukan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        height: 1.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.farmBadgeText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _isPurchased
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  ),
                ),
              ),
              child: KomarsPrimaryButton(
                label: 'Beli Paket Starter Kit',
                icon: Icons.shopping_bag_rounded,
                onPressed: _navToPayment,
              ),
            ),
    );
  }

  String _formatNumber(double value) {
    final str = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    final chars = str.split('').reversed.toList();
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write('.');
      buffer.write(chars[i]);
    }
    return buffer.toString().split('').reversed.join();
  }
}

// ── Section Title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}

// ── Financial Card ────────────────────────────────────────────────────────────

class _FinancialCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;
  const _FinancialCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Column(children: children),
    );
  }
}

// ── Detail Row ────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool isLast;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
      ],
    );
  }
}
