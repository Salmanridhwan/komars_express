import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../db/user_dao.dart';
import '../models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // Theme colors — matching login screen
  static const _brandGreen = Color(0xFF1B5E20);
  static const _brandGreenLight = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final dao = UserDao();
    final exists = await dao.emailExists(_emailCtrl.text.trim());
    if (exists) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email sudah terdaftar.')));
      return;
    }
    await dao.register(
      UserModel(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        role: 'customer',
        phoneNumber: _phoneCtrl.text.trim(),
      ),
    );
    setState(() => _loading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(AppStrings.registerSuccess)));
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
    required bool isDark,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontFamily: 'Outfit',
        color: isDark ? AppColors.darkTextHint : const Color(0xFF999999),
      ),
      floatingLabelStyle: const TextStyle(
        color: _brandGreen,
        fontWeight: FontWeight.w600,
        fontFamily: 'Outfit',
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF888888),
        size: 20,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? AppColors.darkCard : const Color(0xFFF7F7F7),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkDivider : const Color(0xFFE8E8E8),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _brandGreen,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.statusCancelled,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.statusCancelled,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight * 0.26;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ─── Hero Image Header ──────────────────────────────────
              SizedBox(
                height: headerHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Image (reuse login header)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                      child: Image.asset(
                        'assets/images/login_header.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF1B5E20),
                                  Color(0xFF2E7D32),
                                ],
                              ),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(32),
                                bottomRight: Radius.circular(32),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Dark overlay
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.1),
                            Colors.black.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                    ),

                    // Back button
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 8,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                    // Branding text
                    Positioned(
                      left: 28,
                      right: 28,
                      bottom: 28,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.eco_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Bergabung dengan Komars',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Buat Akun Baru',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Register Form ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lengkapi data diri Anda',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : const Color(0xFF888888),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Name Field
                      TextFormField(
                        controller: _nameCtrl,
                        cursorColor: _brandGreen,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                        ),
                        decoration: _buildInputDecoration(
                          label: AppStrings.name,
                          prefixIcon: Icons.person_outline_rounded,
                          isDark: isDark,
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? AppStrings.required : null,
                      ),
                      const SizedBox(height: 14),

                      // Email Field
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        cursorColor: _brandGreen,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                        ),
                        decoration: _buildInputDecoration(
                          label: AppStrings.email,
                          prefixIcon: Icons.email_outlined,
                          isDark: isDark,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return AppStrings.required;
                          if (!v.contains('@')) return 'Email tidak valid';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Phone Field
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        cursorColor: _brandGreen,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                        ),
                        decoration: _buildInputDecoration(
                          label: AppStrings.phoneNumber,
                          prefixIcon: Icons.phone_outlined,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Password Field
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        cursorColor: _brandGreen,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                        ),
                        decoration: _buildInputDecoration(
                          label: AppStrings.password,
                          prefixIcon: Icons.lock_outline_rounded,
                          isDark: isDark,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFF999999),
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return AppStrings.required;
                          if (v.length < 6) return 'Min. 6 karakter';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Confirm Password Field
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscureConfirm,
                        cursorColor: _brandGreen,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                        ),
                        decoration: _buildInputDecoration(
                          label: AppStrings.confirmPassword,
                          prefixIcon: Icons.lock_outline_rounded,
                          isDark: isDark,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFF999999),
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return AppStrings.required;
                          if (v != _passCtrl.text) {
                            return 'Kata sandi tidak cocok';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Register Button — deep green
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brandGreen,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_add_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Daftar',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppStrings.alreadyHaveAccount,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : const Color(0xFF888888),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              AppStrings.login,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: _brandGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
