import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/pref_keys.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/database/database_helper.dart';
import '../../auth/db/user_dao.dart';
import '../../auth/models/user_model.dart';
import '../../express/order/db/order_dao.dart';
import '../../express/reservation/db/reservation_dao.dart';

class ProfileScreen extends StatefulWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  String? _selectedApp;
  bool _isLoading = true;

  // Personal user stats
  int _userOrdersCount = 0;
  int _userReservationsCount = 0;
  int _farmPackagesCount = 0;
  double _totalInvestedAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(PrefKeys.userSessionToken) ?? '';
    _selectedApp = prefs.getString(PrefKeys.selectedApp);

    if (token.isNotEmpty) {
      final userId = int.tryParse(token) ?? 0;
      final user = await UserDao().getById(userId);

      // Load user statistics
      try {
        final orderHistory = await OrderDao().getHistory();
        final userOrders = orderHistory.where((o) => o.userId == userId).toList();
        _userOrdersCount = userOrders.length;
      } catch (e) {
        debugPrint('Error loading user orders count: $e');
      }

      try {
        final userReservations = await ReservationDao().getByUser(userId);
        _userReservationsCount = userReservations.length;
      } catch (e) {
        debugPrint('Error loading user reservations count: $e');
      }

      try {
        final db = DatabaseHelper.instance;
        final purchasedList = await db.purchasedPackageDao.getPurchasedByUserId(userId);
        _farmPackagesCount = purchasedList.length;
        _totalInvestedAmount = purchasedList.fold(0.0, (sum, p) => sum + p.price);
      } catch (e) {
        debugPrint('Error loading user farm packages count: $e');
      }

      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                  color: AppColors.deleteRed.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 32,
                  color: AppColors.deleteRed,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Keluar dari Akun?',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Apakah Anda yakin ingin keluar dari akun Anda?',
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
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }

  ImageProvider? _getAvatarImage() {
    final path = _user?.profileImage;
    if (path == null || path.isEmpty) {
      return null;
    }
    if (kIsWeb) {
      return NetworkImage(path);
    }
    return FileImage(File(path));
  }

  String _getJoinedDate() {
    final dateStr = _user?.createdAt;
    if (dateStr == null) return '-';
    if (dateStr.length >= 10) {
      return dateStr.substring(0, 10);
    }
    return dateStr;
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _user;
    final isAdmin = user?.isAdmin ?? false;
    final hasAvatar = user?.profileImage?.isNotEmpty ?? false;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text(
                'Profil Pengguna',
                style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.white),
              ),
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.secondaryOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () async {
                    await Navigator.pushNamed(context, AppRoutes.editProfile);
                    _loadUserProfile();
                  },
                ),
              ],
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.secondaryOrange))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Beautiful Stack overlay for social-profile layout
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Header background banner
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: AppColors.expressGradient,
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                        ),
                      ),
                      // Edit button for embedded screen
                      if (widget.embedded)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Colors.white),
                              onPressed: () async {
                                await Navigator.pushNamed(context, AppRoutes.editProfile);
                                _loadUserProfile();
                              },
                            ),
                          ),
                        ),
                      // Avatar positioned half-in, half-out
                      Positioned(
                        bottom: -44,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: isDark ? AppColors.darkCard : AppColors.primaryGreenSurface,
                            backgroundImage: _getAvatarImage(),
                            child: !hasAvatar
                                ? Icon(
                                    Icons.person_rounded,
                                    size: 50,
                                    color: isDark ? AppColors.primaryGreenLight : AppColors.primaryGreen,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 56),

                  // Name & Email
                  Text(
                    _user?.name ?? 'Sobat Komars',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user?.email ?? 'email@komars.com',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: isAdmin
                          ? AppColors.secondaryOrange.withOpacity(0.12)
                          : AppColors.primaryGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isAdmin
                            ? AppColors.secondaryOrange.withOpacity(0.3)
                            : AppColors.primaryGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                          size: 14,
                          color: isAdmin ? AppColors.secondaryOrange : AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isAdmin ? 'Administrator' : 'Pelanggan',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isAdmin ? AppColors.secondaryOrangeDark : AppColors.primaryGreenDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stats Panel for Customer
                  if (!isAdmin) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: Row(
                        children: [
                          _buildStatBox('Pesanan', '$_userOrdersCount', Icons.receipt_long_rounded, AppColors.secondaryOrange),
                          const SizedBox(width: 10),
                          _buildStatBox('Reservasi', '$_userReservationsCount', Icons.event_seat_rounded, AppColors.statusActive),
                          const SizedBox(width: 10),
                          _buildStatBox('Paket Tani', '$_farmPackagesCount', Icons.spa_rounded, AppColors.statusSuccess),
                        ],
                      ),
                    ),
                  ],

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Personal Information Card
                        const Text(
                          'Informasi Personal',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                            ),
                          ),
                          child: Column(
                            children: [
                              _ProfileInfoRow(
                                icon: Icons.phone_android_rounded,
                                label: 'No. Telepon',
                                value: (user?.phoneNumber?.isNotEmpty ?? false)
                                    ? user!.phoneNumber!
                                    : '-',
                              ),
                              _DividerLine(isDark: isDark),
                              _ProfileInfoRow(
                                icon: Icons.calendar_today_rounded,
                                label: 'Tanggal Bergabung',
                                value: _getJoinedDate(),
                              ),
                              if (!isAdmin && _farmPackagesCount > 0) ...[
                                _DividerLine(isDark: isDark),
                                _ProfileInfoRow(
                                  icon: Icons.payments_rounded,
                                  label: 'Total Modal Tani',
                                  value: CurrencyFormatter.format(_totalInvestedAmount),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Menu Options
                        const Text(
                          'Pintasan Menu',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                            ),
                          ),
                          child: Column(
                            children: [
                              _ProfileMenuRow(
                                icon: Icons.settings_rounded,
                                title: 'Pengaturan Aplikasi',
                                color: AppColors.primaryGreen,
                                onTap: () async {
                                  await Navigator.pushNamed(
                                    context,
                                    AppRoutes.settings,
                                  );
                                  _loadUserProfile();
                                },
                              ),
                              if (_selectedApp != 'farm') ...[
                                _DividerLine(isDark: isDark),
                                _ProfileMenuRow(
                                  icon: Icons.history_edu_rounded,
                                  title: 'Riwayat Reservasi',
                                  color: AppColors.statusActive,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.reservationHistory,
                                    );
                                  },
                                ),
                              ],
                              _DividerLine(isDark: isDark),
                              _ProfileMenuRow(
                                icon: Icons.receipt_long_rounded,
                                title: 'Riwayat Transaksi',
                                color: AppColors.secondaryOrange,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.orderHistory,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Logout Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.deleteRed.withValues(alpha: 0.08),
                              foregroundColor: AppColors.deleteRed,
                              elevation: 0,
                              side: const BorderSide(
                                color: AppColors.deleteRed,
                                width: 1,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _logout,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout_rounded),
                                SizedBox(width: 8),
                                Text(
                                  'Keluar dari Akun',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDark ? AppColors.primaryGreenLight : AppColors.primaryGreen,
            size: 22,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ProfileMenuRow({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }
}

class _DividerLine extends StatelessWidget {
  final bool isDark;
  const _DividerLine({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
      indent: 20,
      endIndent: 20,
    );
  }
}
