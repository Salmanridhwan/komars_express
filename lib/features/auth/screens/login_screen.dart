import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/pref_keys.dart';
import '../../../core/routes/app_routes.dart';
import '../db/user_dao.dart';

/// Halaman Login Terpadu Komars (Express & Farm).
/// Memiliki widget segmented control interaktif untuk memilih sub-app yang dituju.
/// Warna, tema, logo, dan alur navigasi berubah secara dinamis dengan animasi halus.
class LoginScreen extends StatefulWidget {
  final String? initialApp;
  const LoginScreen({super.key, this.initialApp});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  
  bool _obscure = true;
  bool _loading = false;
  late String _selectedApp;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _selectedApp = widget.initialApp ?? 'express';
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final user = await UserDao().login(
      _emailCtrl.text.trim(),
      _passCtrl.text.trim(),
    );

    setState(() => _loading = false);
    if (!mounted) return;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email atau kata sandi salah.'),
          backgroundColor: AppColors.statusCancelled,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.userSessionToken, user.id.toString());
    await prefs.setString(PrefKeys.userRole, user.role);
    await prefs.setString(PrefKeys.selectedApp, _selectedApp);

    if (!mounted) return;

    if (user.isAdmin) {
      if (_selectedApp == 'farm') {
        Navigator.pushReplacementNamed(context, AppRoutes.farmAdminDashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.expressAdminDashboard);
      }
    } else {
      if (_selectedApp == 'farm') {
        Navigator.pushReplacementNamed(context, AppRoutes.farmCustomerHome);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.expressCustomerHome);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Dynamic brand values based on selection
    final LinearGradient brandGradient = _selectedApp == 'express' 
        ? AppColors.expressGradient 
        : AppColors.primaryGradient;
    final Color brandColor = _selectedApp == 'express' 
        ? AppColors.secondaryOrange 
        : AppColors.primaryGreen;
    final Color brandColorDark = _selectedApp == 'express' 
        ? AppColors.secondaryOrangeDark 
        : AppColors.primaryGreenDark;
    final Color brandColorLight = _selectedApp == 'express' 
        ? AppColors.secondaryOrangeLight 
        : AppColors.primaryGreenLight;
    final Color brandSurface = _selectedApp == 'express' 
        ? AppColors.secondaryOrangeSurface 
        : AppColors.primaryGreenSurface;
    final Color pageBg = _selectedApp == 'express' 
        ? const Color(0xFFFFFAF5) 
        : const Color(0xFFF5FAF5);
        
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : pageBg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ─── Dynamic Header Banner ──────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(28, 48, 28, 40),
                  decoration: BoxDecoration(
                    gradient: brandGradient,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: brandColor.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Animated Logo Container
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            _selectedApp == 'express' 
                                ? Icons.restaurant_rounded 
                                : Icons.agriculture_rounded,
                            key: ValueKey<String>(_selectedApp),
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _selectedApp == 'express' 
                              ? 'Komars Express' 
                              : 'Komars Farm',
                          key: ValueKey<String>(_selectedApp),
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _selectedApp == 'express'
                              ? 'Platform F&B · Pesan, Bayar & Reservasi'
                              : 'Platform Agribisnis · Mitra Pertanian',
                          key: ValueKey<String>(_selectedApp),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── Login Form & App Switcher ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Aplikasi & Masuk',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800, fontFamily: 'Outfit'),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tentukan sub-app tujuan Anda di bawah ini',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ─── Dynamic Segmented Tab Switcher Widget ───────────
                        _buildAppSelector(isDark, brandColor, brandGradient),
                        
                        const SizedBox(height: 28),

                        // Email Field
                        TextFormField(
                          key: const ValueKey('login_email_field'),
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          cursorColor: brandColor,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            floatingLabelStyle: TextStyle(color: brandColor, fontWeight: FontWeight.w600),
                            prefixIcon: Icon(Icons.email_outlined, color: brandColor),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: brandColor, width: 2),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Wajib diisi';
                            if (!v.contains('@')) return 'Email tidak valid';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          key: const ValueKey('login_password_field'),
                          controller: _passCtrl,
                          obscureText: _obscure,
                          cursorColor: brandColor,
                          decoration: InputDecoration(
                            labelText: 'Kata Sandi',
                            floatingLabelStyle: TextStyle(color: brandColor, fontWeight: FontWeight.w600),
                            prefixIcon: Icon(Icons.lock_outline_rounded, color: brandColor),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: brandColor, width: 2),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: brandColor.withValues(alpha: 0.7),
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Wajib diisi';
                            if (v.length < 6) return 'Min. 6 karakter';
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            key: const ValueKey('login_submit_btn'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              shadowColor: brandColor.withValues(alpha: 0.4),
                            ),
                            onPressed: _loading ? null : _login,
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Masuk',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Belum punya akun? ',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (_selectedApp == 'express') {
                                  Navigator.pushNamed(context, AppRoutes.expressRegister);
                                } else {
                                  Navigator.pushNamed(context, AppRoutes.farmRegister);
                                }
                              },
                              child: Text(
                                'Daftar Sekarang',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: brandColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),
                        
                        // Admin Hint Box
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : brandSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppColors.darkDivider : brandColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.admin_panel_settings_outlined,
                                size: 20,
                                color: isDark ? brandColorLight : brandColor,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Akses Admin: Gunakan email admin@gmail.com dan kata sandi admin123',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : brandColorDark,
                                    height: 1.4,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget Segmented Tab Switcher Premium untuk memilih sub-app
  Widget _buildAppSelector(bool isDark, Color brandColor, LinearGradient brandGradient) {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Animated pill background
          AnimatedAlign(
            alignment: _selectedApp == 'express'
                ? Alignment.centerLeft
                : Alignment.centerRight,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: brandGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: brandColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Interactive Tab Labels
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  key: const ValueKey('selector_express_tab'),
                  onTap: () => setState(() => _selectedApp = 'express'),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_rounded,
                          color: _selectedApp == 'express' ? Colors.white : Colors.grey[600],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Komars Express',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: _selectedApp == 'express' ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  key: const ValueKey('selector_farm_tab'),
                  onTap: () => setState(() => _selectedApp = 'farm'),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.agriculture_rounded,
                          color: _selectedApp == 'farm' ? Colors.white : Colors.grey[600],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Komars Farm',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: _selectedApp == 'farm' ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
