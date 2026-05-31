import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:komars_express/core/constants/app_colors.dart';
import 'package:komars_express/core/constants/pref_keys.dart';
import 'package:komars_express/core/database/database_helper.dart';
import '../../../auth/db/user_dao.dart';
import '../../../auth/models/user_model.dart';
import '../../../home/screens/profile_screen.dart';
import 'farm_management_screen.dart';

class FarmAdminDashboard extends StatefulWidget {
  const FarmAdminDashboard({super.key});

  @override
  State<FarmAdminDashboard> createState() => _FarmAdminDashboardState();
}

class _FarmAdminDashboardState extends State<FarmAdminDashboard> {
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
        return const FarmManagementScreen(embedded: true);
      case 2:
        return const ProfileScreen(embedded: true);
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
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : Colors.white,
        indicatorColor: AppColors.primaryGreen.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            key: ValueKey('farm_admin_nav_dashboard'),
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon:
                Icon(Icons.dashboard_rounded, color: AppColors.primaryGreen),
            label: 'Dashboard',
          ),
          NavigationDestination(
            key: ValueKey('farm_admin_nav_package'),
            icon: Icon(Icons.spa_outlined),
            selectedIcon: Icon(Icons.spa_rounded, color: AppColors.primaryGreen),
            label: 'Manajemen',
          ),
          NavigationDestination(
            key: ValueKey('farm_admin_nav_profile'),
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.primaryGreen),
            label: 'Profil',
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
  int _totalPackages = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final dao = DatabaseHelper.instance.farmPackageDao;
      final packages = await dao.getAllPackages();

      setState(() {
        _totalPackages = packages.length;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading farm stats: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.admin?.name.split(' ').first ?? 'Admin';

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: AppColors.primaryGreen,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.primaryGreen,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                'Komars Farm Admin',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.primaryGreen.withValues(alpha: 0.8)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Icon(
                        Icons.agriculture_rounded,
                        size: 150,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat Datang, $firstName!',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ringkasan data investasi Komars Farm',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_loading)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(
                          color: AppColors.primaryGreen),
                    ))
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Total Paket',
                            value: _totalPackages.toString(),
                            icon: Icons.spa_rounded,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: _StatCard(
                            title: 'Total Mitra',
                            value: '0',
                            icon: Icons.people_rounded,
                            color: AppColors.secondaryOrange,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
