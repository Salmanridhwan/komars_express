import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/pref_keys.dart';
import '../../../core/routes/app_routes.dart';
import '../db/user_dao.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

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
        const SnackBar(content: Text('Email atau kata sandi salah.')),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.userSessionToken, user.id.toString());
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreenSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        color: AppColors.primaryGreen,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      AppStrings.appName,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                Text(
                  'Selamat Datang\nKembali 👋',
                  style: Theme.of(
                    context,
                  ).textTheme.displayMedium?.copyWith(height: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masuk ke akun Komars Anda',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: AppStrings.email,
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return AppStrings.required;
                    if (!v.contains('@')) return 'Email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: AppStrings.password,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return AppStrings.required;
                    if (v.length < 6) return 'Min. 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
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
                        : const Text(AppStrings.login),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.dontHaveAccount,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.register),
                      child: const Text(
                        AppStrings.register,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
