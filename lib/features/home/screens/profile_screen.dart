import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/pref_keys.dart';
import '../../../core/routes/app_routes.dart';
import '../../auth/db/user_dao.dart';
import '../../auth/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(PrefKeys.userSessionToken) ?? '';
    if (token.isNotEmpty) {
      final user = await UserDao().getById(int.tryParse(token) ?? 0);
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Akun?'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Anda?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deleteRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(PrefKeys.userSessionToken);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.editProfile);
              _loadUserProfile();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar Section
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 64,
                          backgroundColor: isDark
                              ? AppColors.darkCard
                              : AppColors.primaryGreenSurface,
                          backgroundImage: _user?.profileImage != null &&
                                  _user!.profileImage!.isNotEmpty
                              ? FileImage(File(_user!.profileImage!))
                              : null,
                          child: _user?.profileImage == null ||
                                  _user!.profileImage!.isEmpty
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 64,
                                  color: isDark
                                      ? AppColors.primaryGreenLight
                                      : AppColors.primaryGreen,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _user?.name ?? 'Sobat Komars',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user?.email ?? 'email@komars.com',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // Detail Information
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkDivider
                            : AppColors.lightDivider,
                      ),
                    ),
                    child: Column(
                      children: [
                        _ProfileInfoRow(
                          icon: Icons.phone_android_rounded,
                          label: 'No. Telepon',
                          value: _user?.phoneNumber != null &&
                                  _user!.phoneNumber!.isNotEmpty
                              ? _user!.phoneNumber!
                              : '-',
                        ),
                        _DividerLine(isDark: isDark),
                        _ProfileInfoRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Bergabung Sejak',
                          value: _user?.createdAt != null
                              ? _user!.createdAt!.substring(0, 10)
                              : '-',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Menu Options
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkDivider
                            : AppColors.lightDivider,
                      ),
                    ),
                    child: Column(
                      children: [
                        _ProfileMenuRow(
                          icon: Icons.settings_rounded,
                          title: 'Pengaturan Aplikasi',
                          color: AppColors.primaryGreen,
                          onTap: () async {
                            await Navigator.pushNamed(context, AppRoutes.settings);
                            _loadUserProfile();
                          },
                        ),
                        _DividerLine(isDark: isDark),
                        _ProfileMenuRow(
                          icon: Icons.history_edu_rounded,
                          title: 'Riwayat Reservasi',
                          color: AppColors.statusActive,
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.reservationHistory);
                          },
                        ),
                        _DividerLine(isDark: isDark),
                        _ProfileMenuRow(
                          icon: Icons.receipt_long_rounded,
                          title: 'Riwayat Transaksi',
                          color: AppColors.secondaryOrange,
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.orderHistory);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deleteRed.withOpacity(0.1),
                      foregroundColor: AppColors.deleteRed,
                      elevation: 0,
                      side: const BorderSide(color: AppColors.deleteRed, width: 1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ).build(
                      context,
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
          Icon(icon,
              color: isDark ? AppColors.primaryGreenLight : AppColors.primaryGreen,
              size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15,
              fontWeight: FontWeight.w600,
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
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
