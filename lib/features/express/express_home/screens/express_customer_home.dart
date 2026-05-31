import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/pref_keys.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../auth/db/user_dao.dart';
import '../../../auth/models/user_model.dart';
import '../../order/screens/order_history_screen.dart';
import '../../menu/screens/menu_list_screen.dart';
import '../../../home/screens/profile_screen.dart';

/// Home utama pelanggan Komars Express.
/// Memiliki 3 tab: Beranda, Pesanan, Profil.
class ExpressCustomerHome extends StatefulWidget {
  const ExpressCustomerHome({super.key});

  @override
  State<ExpressCustomerHome> createState() => _ExpressCustomerHomeState();
}

class _ExpressCustomerHomeState extends State<ExpressCustomerHome> {
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

  void _onNavTap(int idx) => setState(() => _tabIndex = idx);

  Widget _buildBody() {
    switch (_tabIndex) {
      case 0:
        return _ExpressBeranda(user: _user);
      case 1:
        return const MenuListScreen(embedded: true);
      case 2:
        return const OrderHistoryScreen(embedded: true);
      case 3:
        return const ProfileScreen(embedded: true);
      default:
        return _ExpressBeranda(user: _user);
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
            key: ValueKey('nav_home'),
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.secondaryOrange),
            label: 'Beranda',
          ),
          NavigationDestination(
            key: ValueKey('nav_menu'),
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded, color: AppColors.secondaryOrange),
            label: 'Katalog',
          ),
          NavigationDestination(
            key: ValueKey('nav_orders'),
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.secondaryOrange),
            label: 'Pesanan',
          ),
          NavigationDestination(
            key: ValueKey('nav_profile'),
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.secondaryOrange),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ── Tab Beranda ───────────────────────────────────────────────────────────────

class _ExpressBeranda extends StatelessWidget {
  final UserModel? user;
  const _ExpressBeranda({this.user});

  @override
  Widget build(BuildContext context) {
    final firstName = user?.name.split(' ').first ?? 'KOMMUNITY';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Top Section (Orange Background) ──
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Orange curve background
                Container(
                  height: 340,
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryOrange,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                ),
                
                SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // Header Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.restaurant_rounded, color: Colors.white, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'Komars Express',
                                  style: TextStyle(
                                    fontFamily: 'Outfit', 
                                    fontWeight: FontWeight.w900, 
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, AppRoutes.cart),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.shopping_cart_outlined, color: Colors.black87, size: 16),
                                    SizedBox(width: 6),
                                    Text('Keranjang', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87, fontSize: 12)),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Carousel
                      const _PromoCarousel(),
                    ],
                  ),
                ),
                
                // Greeting Overlapping Card
                Positioned(
                  bottom: -35,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hi, ${firstName.toUpperCase()}!',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, AppRoutes.menuList),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryOrange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Cari Menu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 60),
            
            // ── Categories Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Kategori Menu',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // ── Circle Categories (4 items) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _CircleCategory(
                    icon: Icons.rice_bowl_rounded,
                    title: 'Makanan',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.menuList, arguments: 'food'),
                  ),
                  _CircleCategory(
                    icon: Icons.local_drink_rounded,
                    title: 'Minuman',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.menuList, arguments: 'drink'),
                  ),
                  _CircleCategory(
                    icon: Icons.emoji_food_beverage_rounded,
                    title: 'Beverage',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.menuList, arguments: 'beverage'),
                  ),
                  _CircleCategory(
                    icon: Icons.local_offer_rounded,
                    title: 'Promo',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.menuList),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 35),
            
            // ── Bottom Banner ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.reservation),
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/promo/promo_04.png',
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.3, 1.0],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'MAU MAKAN DI TEMPAT?',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Reservasi meja sekarang, tanpa antre.',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 11,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryOrange,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Reservasi',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Components ──

class _CircleCategory extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _CircleCategory({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppColors.darkCard : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.secondaryOrange, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoCarousel extends StatefulWidget {
  const _PromoCarousel();

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.95);
  int _currentIndex = 0;

  final List<Map<String, String>> _promos = [
    {
      'image': 'assets/promo/promo_01.png',
      'title': 'Nikmati Sajian Nusantara',
      'subtitle': 'Lezat dan menggugah selera, pas untuk makan siang',
    },
    {
      'image': 'assets/promo/promo_02.png',
      'title': 'Menu Pilihan Keluarga',
      'subtitle': 'Makan bersama keluarga jadi lebih hemat dan meriah',
    },
    {
      'image': 'assets/promo/promo_03.png',
      'title': 'Segarnya Bikin Semangat',
      'subtitle': 'Hilangkan dahaga dengan minuman segar racikan kami',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentIndex = idx),
            itemCount: _promos.length,
            itemBuilder: (context, index) {
              final promo = _promos[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
                  }
                  return Transform.scale(
                    scale: value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                promo['image']!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.7),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: const [0.4, 1.0],
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 16,
                                left: 16,
                                right: 16,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      promo['title']!,
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      promo['subtitle']!,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 12,
                                        color: Colors.white.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _promos.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentIndex == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
class _QuickTile extends StatelessWidget {
  final String id;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickTile(
      {required this.id,
      required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        key: ValueKey(id),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
