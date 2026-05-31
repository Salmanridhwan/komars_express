import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';

class ExpressHomeScreen extends StatelessWidget {
  const ExpressHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Komars Express'),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.secondaryOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.menuManagement),
            tooltip: 'Admin Menu',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Promo / Info Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                gradient: AppColors.expressGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pesan Makanan & Reservasi Meja',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bahan-bahan langsung dari pertanian binaan Komars Farm. Segar, organik, dan berkualitas premium.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Services Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fitur Pemesanan & Kasir',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ExpressCard(
                          icon: Icons.menu_book_rounded,
                          title: 'Katalog Menu',
                          desc: 'Lihat hidangan segar & lakukan pemesanan',
                          color: AppColors.secondaryOrange,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.menuList),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ExpressCard(
                          icon: Icons.shopping_basket_rounded,
                          title: 'Keranjang Belanja',
                          desc: 'Periksa item pilihan & total pembayaran',
                          color: AppColors.primaryGreen,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.cart),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ExpressCard(
                          icon: Icons.receipt_long_rounded,
                          title: 'Daftar Transaksi',
                          desc: 'Riwayat pesanan & status pembayaran',
                          color: AppColors.statusActive,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.orderHistory),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ExpressCard(
                          icon: Icons.admin_panel_settings_rounded,
                          title: 'Kelola Menu (Admin)',
                          desc: 'CRUD hidangan, harga & sourcing farm',
                          color: Colors.purple,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.menuManagement),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  Text(
                    'Reservasi & Tata Letak Meja (PJ Ega)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ExpressCard(
                          icon: Icons.table_restaurant_rounded,
                          title: 'Reservasi Meja',
                          desc: 'Pesan meja dine-in untuk acara Anda',
                          color: AppColors.statusPending,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.reservation),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ExpressCard(
                          icon: Icons.grid_view_rounded,
                          title: 'Tata Letak Meja',
                          desc: 'Kelola penempatan & visual denah meja',
                          color: Colors.blueGrey,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.tableManagement),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpressCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  final VoidCallback onTap;

  const _ExpressCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
