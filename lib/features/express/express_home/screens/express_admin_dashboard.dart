import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/pref_keys.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/db/user_dao.dart';
import '../../../auth/models/user_model.dart';
import '../../menu/db/menu_dao.dart';
import '../../order/db/order_dao.dart';
import '../../reservation/db/reservation_dao.dart';
import '../../table/db/table_dao.dart';
import '../../menu/screens/menu_management_screen.dart';
import '../../table/screens/table_management_screen.dart';
import '../../order/screens/order_history_screen.dart';
import '../../reservation/screens/reservation_history_screen.dart';

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
        return const MenuManagementScreen(embedded: true);
      case 2:
        return const TableManagementScreen(embedded: true);
      case 3:
        return const OrderHistoryScreen(embedded: true);
      case 4:
        return const ReservationHistoryScreen(embedded: true);
      default:
        return _AdminDashboardTab(admin: _admin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        height: 64,
        selectedIndex: _tabIndex,
        onDestinationSelected: _onNavTap,
        backgroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSurface
                : Colors.white,
        indicatorColor: AppColors.secondaryOrange.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            key: ValueKey('admin_nav_dashboard'),
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded,
                color: AppColors.secondaryOrange),
            label: 'Dashboard',
          ),
          NavigationDestination(
            key: ValueKey('admin_nav_menu'),
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded,
                color: AppColors.secondaryOrange),
            label: 'Menu',
          ),
          NavigationDestination(
            key: ValueKey('admin_nav_table'),
            icon: Icon(Icons.table_restaurant_outlined),
            selectedIcon: Icon(Icons.table_restaurant_rounded,
                color: AppColors.secondaryOrange),
            label: 'Meja',
          ),
          NavigationDestination(
            key: ValueKey('admin_nav_orders'),
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded,
                color: AppColors.secondaryOrange),
            label: 'Pesanan',
          ),
          NavigationDestination(
            key: ValueKey('admin_nav_reservation'),
            icon: Icon(Icons.event_seat_outlined),
            selectedIcon: Icon(Icons.event_seat_rounded,
                color: AppColors.secondaryOrange),
            label: 'Reservasi',
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

      if (mounted) {
        setState(() {
          _totalMenus = menus.length;
          _totalOrders = orders.length;
          _totalTables = tables.length;
          _totalReservations = reservations.length;
          _todayRevenue = revenue;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Admin?'),
        content: const Text('Session admin akan diakhiri.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deleteRed,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.expressGradient,
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
                        fontSize: 16)),
                Text('Panel Admin',
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10,
                        color: AppColors.secondaryOrange)),
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
              color: AppColors.secondaryOrangeSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.secondaryOrange.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.admin_panel_settings_rounded,
                    size: 14, color: AppColors.secondaryOrange),
                SizedBox(width: 4),
                Text('ADMIN',
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryOrangeDark)),
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
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
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
                            'Selamat Datang, ${widget.admin?.name ?? 'Admin'} 👋',
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
                          color: AppColors.statusSuccess,
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
                          color: AppColors.statusActive,
                        ),
                        _StatCard(
                          icon: Icons.table_restaurant_rounded,
                          label: 'Total Meja',
                          value: '$_totalTables meja',
                          color: AppColors.statusPending,
                        ),
                      ],
                    ),

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
                      color: AppColors.statusPending,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.tableManagement),
                    ),
                    const SizedBox(height: 10),
                    _AdminQuickAction(
                      icon: Icons.receipt_long_rounded,
                      title: 'Lihat Semua Pesanan',
                      subtitle: '$_totalOrders pesanan tercatat',
                      color: AppColors.statusActive,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.orderHistory),
                    ),
                    const SizedBox(height: 10),
                    _AdminQuickAction(
                      icon: Icons.event_seat_rounded,
                      title: 'Lihat Semua Reservasi',
                      subtitle: '$_totalReservations reservasi tercatat',
                      color: AppColors.primaryGreen,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.reservationHistory),
                    ),
                    const SizedBox(height: 10),
                    _AdminQuickAction(
                      icon: Icons.person_rounded,
                      title: 'Profil Admin',
                      subtitle: widget.admin?.email ?? '',
                      color: Colors.blueGrey,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.profile),
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
