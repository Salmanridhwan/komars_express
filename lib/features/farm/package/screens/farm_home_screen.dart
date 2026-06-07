import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:komars_express/core/database/database_helper.dart';
import 'package:komars_express/core/constants/app_colors.dart';
import 'package:komars_express/core/constants/pref_keys.dart';
import 'package:komars_express/core/routes/app_routes.dart';
import 'package:komars_express/core/widgets/komars_navbar.dart';
import '../../../auth/db/user_dao.dart';
import '../../../auth/models/user_model.dart';
import '../models/farm_package_model.dart';
import '../../../home/screens/profile_screen.dart';
import '../../../farm/mitra/screens/farm_harvest_sale_screen.dart';
import '../../../farm/finance/screens/finance_history_screen.dart';
import '../widgets/farm_progress_arc.dart';

/// Home utama pelanggan Komars Farm.
/// Memiliki 3 tab: Beranda, Keuangan, Profil.
class FarmHomeScreen extends StatefulWidget {
  const FarmHomeScreen({super.key});

  @override
  State<FarmHomeScreen> createState() => _FarmHomeScreenState();
}

class _FarmHomeScreenState extends State<FarmHomeScreen> {
  int _tabIndex = 0;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(PrefKeys.userSessionToken) ?? '';
    if (token.isEmpty) return;
    final user = await UserDao().getById(int.tryParse(token) ?? 0);
    if (mounted) setState(() => _user = user);
  }

  Widget _buildBody() {
    switch (_tabIndex) {
      case 0:
        return _FarmBeranda(user: _user);
      case 1:
        return _buildKeuangan();
      case 2:
        return FarmHarvestSaleScreen(userId: _user?.id ?? 0, embedded: true);
      case 3:
        return const ProfileScreen(embedded: true);
      default:
        return _FarmBeranda(user: _user);
    }
  }

  Widget _buildKeuangan() {
    return FinanceHistoryScreen(userId: _user?.id ?? 0, embedded: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: KomarsNavBar(
        selectedIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        colorStart: AppColors.secondaryOrange,
        colorEnd: AppColors.secondaryOrangeLight,
        items: const [
          KomarsNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Beranda',
          ),
          KomarsNavItem(
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet_rounded,
            label: 'Keuangan',
          ),
          KomarsNavItem(
            icon: Icons.sell_outlined,
            activeIcon: Icons.sell_rounded,
            label: 'Jual Panen',
          ),
          KomarsNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ── Tab Beranda ───────────────────────────────────────────────────────────────

class _FarmBeranda extends StatefulWidget {
  final UserModel? user;
  const _FarmBeranda({this.user});

  @override
  State<_FarmBeranda> createState() => _FarmBerandaState();
}

class _FarmBerandaState extends State<_FarmBeranda> {
  late DatabaseHelper _dbHelper;
  String _selectedFarmType = 'unggas';
  List<FarmPackage> _packages = [];
  Map<String, int> _packagesByType = {};
  int _totalPackages = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _dbHelper = DatabaseHelper.instance;
    final prefs = await SharedPreferences.getInstance();
    _selectedFarmType = prefs.getString(PrefKeys.selectedFarmType) ?? 'unggas';
    await _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoading = true);
    try {
      // Load filtered packages for current view
      final packages = await _dbHelper.farmPackageDao.getPackagesByFarmType(
        _selectedFarmType,
      );

      // Load all packages to calculate arc distribution
      final allTypes = ['unggas', 'ikan', 'sayur'];
      final Map<String, int> byType = {};
      int total = 0;
      for (final type in allTypes) {
        final pkgs =
            await _dbHelper.farmPackageDao.getPackagesByFarmType(type);
        byType[type] = pkgs.length;
        total += pkgs.length;
      }

      if (mounted)
        setState(() {
          _packages = packages;
          _packagesByType = byType;
          _totalPackages = total;
          _isLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onFarmTypeChange(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.selectedFarmType, type);
    setState(() => _selectedFarmType = type);
    await _loadPackages();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.user?.name.split(' ').first ?? 'Mitra';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.expressCustomerHome);
            }
          },
          tooltip: 'Kembali ke Komars Express',
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.agriculture_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Komars Farm',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              if (widget.user?.id != null) {
                Navigator.pushNamed(
                  context,
                  AppRoutes.farmMyPackages,
                  arguments: widget.user!.id!,
                );
              }
            },
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Paket Saya',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero Banner ─────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Teks sambutan di kiri
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Halo, $firstName! 🌱',
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Kelola usaha tani Anda hari ini',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.88),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_totalPackages paket tersedia',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Progress Arc di kanan — Custom Drawing Widget
                            FarmProgressArc(
                              totalPackages: _totalPackages,
                              packagesByType: _packagesByType,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Quick finance access
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.farmFinanceHistory,
                            arguments: widget.user?.id ?? 1,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Lihat Riwayat Keuangan Mitra',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Filter Tipe Tani ────────────────────────────────
                        Text(
                          'Kategori Usaha Tani',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _farmTypeItem('unggas', '🐔', 'Unggas'),
                              const SizedBox(width: 8),
                              _farmTypeItem('ikan', '🐟', 'Ikan'),
                              const SizedBox(width: 8),
                              _farmTypeItem('sayur', '🥬', 'Sayur'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Package List ─────────────────────────────────────
                        Text(
                          'Paket Starter Kit',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        if (_packages.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 56,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Belum ada paket tersedia',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _packages.length,
                            itemBuilder: (ctx, i) {
                              final pkg = _packages[i];
                              return _PackageCard(
                                package: pkg,
                                onTap: () => Navigator.pushNamed(
                                  ctx,
                                  AppRoutes.farmPackageDetail,
                                  arguments: pkg,
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _farmTypeItem(String type, String emoji, String label) {
    final isSelected = _selectedFarmType == type;
    return GestureDetector(
      onTap: () => _onFarmTypeChange(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondaryOrange
              : AppColors.secondaryOrangeSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.secondaryOrange
                : AppColors.secondaryOrange.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.secondaryOrangeDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final FarmPackage package;
  final VoidCallback onTap;
  const _PackageCard({required this.package, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.secondaryOrangeSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.agriculture_rounded,
                color: AppColors.secondaryOrange,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.title,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ROI: ${package.roiMonths} bulan · Panen: ${package.harvestTimeDays} hari',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryOrangeSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Modal min: Rp ${(package.initialCapitalMin / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryOrangeDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
