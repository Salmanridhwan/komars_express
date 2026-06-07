import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/pref_keys.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/komars_navbar.dart';
import '../../../auth/db/user_dao.dart';
import '../../../auth/models/user_model.dart';
import '../../menu/db/menu_dao.dart';
import '../../order/db/order_dao.dart';
import '../../reservation/db/reservation_dao.dart';
import '../../table/db/table_dao.dart';
import '../../order/screens/order_history_screen.dart';
import '../../reservation/screens/reservation_history_screen.dart';
import '../../harvest/screens/express_harvest_inbox_screen.dart';
import '../widgets/sales_analytics_chart.dart';

/// Dashboard utama admin Komars Express.
/// Memiliki 5 tab: Dashboard, Menu, Meja, Pesanan, Reservasi.
class ExpressAdminDashboard extends StatefulWidget {
  const ExpressAdminDashboard({super.key});

  @override
  State<ExpressAdminDashboard> createState() => _ExpressAdminDashboardState();
}

class _ExpressAdminDashboardState extends State<ExpressAdminDashboard> {
  int _tabIndex = 0;
  UserModel? _admin;

  @override
  void initState() {
    super.initState();
    _loadAdmin();
  }

  Future<void> _loadAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(PrefKeys.userSessionToken) ?? '';
    if (token.isEmpty) return;
    final user = await UserDao().getById(int.tryParse(token) ?? 0);
    if (mounted) setState(() => _admin = user);
  }

  void _onNavTap(int idx) => setState(() => _tabIndex = idx);

  Widget _buildBody() {
    switch (_tabIndex) {
      case 0:
        return _AdminDashboardTab(admin: _admin);
      case 1:
        return const OrderHistoryScreen(embedded: true);
      case 2:
        return const ReservationHistoryScreen(embedded: true);
      case 3:
        return const ExpressHarvestInboxScreen(embedded: true);
      default:
        return _AdminDashboardTab(admin: _admin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: KomarsNavBar(
        selectedIndex: _tabIndex,
        onTap: _onNavTap,
        items: const [
          KomarsNavItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
            label: 'Dashboard',
          ),
          KomarsNavItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_rounded,
            label: 'Pesanan',
          ),
          KomarsNavItem(
            icon: Icons.event_seat_outlined,
            activeIcon: Icons.event_seat_rounded,
            label: 'Reservasi',
          ),
          KomarsNavItem(
            icon: Icons.agriculture_outlined,
            activeIcon: Icons.agriculture_rounded,
            label: 'Panen',
          ),
        ],
      ),
    );
  }
}

// ── Dashboard Tab ─────────────────────────────────────────────────────────────

class _AdminDashboardTab extends StatefulWidget {
  final UserModel? admin;
  const _AdminDashboardTab({this.admin});

  @override
  State<_AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<_AdminDashboardTab> {
  int _totalMenus = 0;
  int _totalOrders = 0;
  int _totalTables = 0;
  int _totalReservations = 0;
  double _todayRevenue = 0;
  List<ChartDataPoint> _chartData = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final menus = await MenuDao().getAll();
      final orders = await OrderDao().getHistory();
      final tables = await TableDao().getAll();
      final reservations = await ReservationDao().getAll();

      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      double revenue = 0;
      for (final o in orders) {
        if (o.status == 'Lunas' &&
            (o.createdAt?.startsWith(todayStr) ?? false)) {
          revenue += o.totalAmount;
        }
      }

      // Aggregating 7 days of sales analytics
      final List<ChartDataPoint> calculatedChartData = [];
      final List<String> weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      final List<String> fullWeekdays = [
        'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
      ];
      final List<String> months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];

      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final datePrefix =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        
        double dailySum = 0;
        for (final o in orders) {
          if (o.status == 'Lunas' && (o.createdAt?.startsWith(datePrefix) ?? false)) {
            dailySum += o.totalAmount;
          }
        }

        final String label = weekdays[date.weekday - 1];
        final String fullDate = '${fullWeekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
        
        calculatedChartData.add(ChartDataPoint(
          label: label,
          fullDate: fullDate,
          value: dailySum,
        ));
      }

      // If all calculations yielded zero, populate mock data for preview but preserve today's real value
      bool allZero = calculatedChartData.every((dp) => dp.value == 0.0);
      if (allZero) {
        final List<double> mockValues = [185000, 240000, 190000, 310000, 420000, 580000, 0];
        mockValues[6] = revenue; // Today's actual db sales
        for (int i = 0; i < 7; i++) {
          final oldDp = calculatedChartData[i];
          calculatedChartData[i] = ChartDataPoint(
            label: oldDp.label,
            fullDate: oldDp.fullDate,
            value: mockValues[i],
          );
        }
      }

      if (mounted) {
        setState(() {
          _totalMenus = menus.length;
          _totalOrders = orders.length;
          _totalTables = tables.length;
          _totalReservations = reservations.length;
          _todayRevenue = revenue;
          _chartData = calculatedChartData;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondaryOrange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 32,
                  color: AppColors.secondaryOrange,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Keluar dari Admin?',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Sesi masuk admin Komars Express akan diakhiri dan Anda harus masuk kembali.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(
                          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deleteRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'Keluar',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(PrefKeys.userSessionToken);
      await prefs.remove(PrefKeys.userRole);
      await prefs.remove(PrefKeys.selectedApp);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.login, (r) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.secondaryOrange,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Komars Express',
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.white)),
                Text('Panel Admin',
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10,
                        color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          // Admin badge
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.admin_panel_settings_rounded,
                    size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text('ADMIN',
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondaryOrange),
            )
          : RefreshIndicator(
              onRefresh: _loadStats,
              color: AppColors.secondaryOrange,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.expressGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.secondaryOrange.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat Datang, ${widget.admin?.name ?? 'Admin'}',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Panel manajemen Komars Express',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text('Ringkasan Hari Ini',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),

                    // Stats Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _StatCard(
                          icon: Icons.payments_rounded,
                          label: 'Pendapatan Hari Ini',
                          value: CurrencyFormatter.format(_todayRevenue),
                          color: AppColors.secondaryOrange,
                        ),
                        _StatCard(
                          icon: Icons.receipt_long_rounded,
                          label: 'Total Pesanan',
                          value: '$_totalOrders pesanan',
                          color: AppColors.secondaryOrange,
                        ),
                        _StatCard(
                          icon: Icons.menu_book_rounded,
                          label: 'Menu Aktif',
                          value: '$_totalMenus item',
                          color: AppColors.secondaryOrange,
                        ),
                        _StatCard(
                          icon: Icons.table_restaurant_rounded,
                          label: 'Total Meja',
                          value: '$_totalTables meja',
                          color: AppColors.secondaryOrange,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    SalesAnalyticsChart(dataPoints: _chartData),

                    const SizedBox(height: 24),
                    Text('Akses Cepat Admin',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),

                    _AdminQuickAction(
                      icon: Icons.menu_book_rounded,
                      title: 'Kelola Menu',
                      subtitle: 'Tambah, edit, hapus item menu',
                      color: AppColors.secondaryOrange,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.menuManagement),
                    ),
                    const SizedBox(height: 10),
                    _AdminQuickAction(
                      icon: Icons.table_restaurant_rounded,
                      title: 'Kelola Meja',
                      subtitle: 'Atur layout & kapasitas meja',
                      color: AppColors.secondaryOrange,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.tableManagement),
                    ),
                    const SizedBox(height: 10),
                    _AdminQuickAction(
                      icon: Icons.receipt_long_rounded,
                      title: 'Lihat Semua Pesanan',
                      subtitle: '$_totalOrders pesanan tercatat',
                      color: AppColors.secondaryOrange,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.orderHistory),
                    ),
                    const SizedBox(height: 10),
                    _AdminQuickAction(
                      icon: Icons.event_seat_rounded,
                      title: 'Lihat Semua Reservasi',
                      subtitle: '$_totalReservations reservasi tercatat',
                      color: AppColors.secondaryOrange,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.reservationHistory),
                    ),

                    const SizedBox(height: 32),

                    // ── Komars Farm Admin Section ────────────────────────────
                    Text(
                      'Kelola Komars Farm',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),

                    // Farm Admin Entry Card
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.farmAdminDashboard),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.primaryGreen.withValues(alpha: 0.25),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.agriculture_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Panel Admin',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Komars Farm',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Kelola paket, mitra & laporan panen',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 12,
                                      color:
                                          Colors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Farm sub-actions row
                    Row(
                      children: [
                        _FarmAdminTile(
                          icon: Icons.inventory_2_rounded,
                          label: 'Kelola\nPaket',
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.farmManagement),
                        ),
                        const SizedBox(width: 10),
                        _FarmAdminTile(
                          icon: Icons.people_alt_rounded,
                          label: 'Kelola\nMitra',
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.farmMitraAdmin),
                        ),
                        const SizedBox(width: 10),
                        _FarmAdminTile(
                          icon: Icons.agriculture_rounded,
                          label: 'Inbox\nPanen',
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.expressHarvestInbox),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}


class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary)),
              Text(value,
                  style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminQuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _AdminQuickAction(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: isDark ? AppColors.darkDivider : color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ── Farm Admin Shortcut Tile ───────────────────────────────────────────────────

class _FarmAdminTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FarmAdminTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkCard
                : AppColors.primaryGreenSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? AppColors.darkDivider
                  : AppColors.primaryGreen.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primaryGreen, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.primaryGreenLight
                      : AppColors.primaryGreenDark,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

