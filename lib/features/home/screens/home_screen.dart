import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/pref_keys.dart';
import '../../../core/routes/app_routes.dart';
import '../../auth/db/user_dao.dart';
import '../../auth/models/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _user;
  int _bottomIdx = 0;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.eco_rounded, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            const Text(AppStrings.appName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
          IconButton(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryGreenSurface,
              child: Icon(Icons.person_rounded, color: AppColors.primaryGreen, size: 18),
            ),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, ${_user?.name.split(' ').first ?? 'Sobat'} 👋',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Apa yang ingin kamu lakukan hari ini?',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('Layanan Kami',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            // Komars Express Card
            _ServiceCard(
              id: 'express_card',
              gradient: AppColors.expressGradient,
              icon: Icons.restaurant_rounded,
              title: AppStrings.expressSection,
              subtitle: AppStrings.expressSubtitle,
              onTap: () => Navigator.pushNamed(context, AppRoutes.expressHome),
              badge: 'F&B Core',
            ),
            const SizedBox(height: 16),
            // Komars Farm Card
            _ServiceCard(
              id: 'farm_card',
              gradient: AppColors.primaryGradient,
              icon: Icons.agriculture_rounded,
              title: AppStrings.farmSection,
              subtitle: AppStrings.farmSubtitle,
              onTap: () => Navigator.pushNamed(context, AppRoutes.farmHome),
              badge: 'Agribisnis',
            ),
            const SizedBox(height: 28),
            Text('Akses Cepat', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                _QuickAction(
                  icon: Icons.menu_book_rounded,
                  label: 'Menu',
                  color: AppColors.secondaryOrange,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.menuList),
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: Icons.shopping_cart_outlined,
                  label: 'Keranjang',
                  color: AppColors.primaryGreen,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.cart),
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: Icons.receipt_long_rounded,
                  label: 'Pesanan',
                  color: AppColors.statusActive,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.orderHistory),
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: Icons.table_restaurant_rounded,
                  label: 'Reservasi',
                  color: AppColors.statusPending,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.reservation),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String id;
  final LinearGradient gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.id,
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(badge,
                        style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 6),
                  Text(title,
                      style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  Text(subtitle,
                      style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
