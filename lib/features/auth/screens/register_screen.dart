import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../db/user_dao.dart';
import '../models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

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
        phoneNumber: _phoneCtrl.text.trim(),
      ),
    );
    setState(() => _loading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(AppStrings.registerSuccess)));
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.register)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buat Akun Baru 🌱',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Bergabung dengan ekosistem Farm-to-Table',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: AppStrings.name,
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? AppStrings.required : null,
              ),
              const SizedBox(height: 14),
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
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: AppStrings.phoneNumber,
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 14),
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
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: AppStrings.confirmPassword,
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return AppStrings.required;
                  if (v != _passCtrl.text) return 'Kata sandi tidak cocok';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(AppStrings.register),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.alreadyHaveAccount,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      AppStrings.login,
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
    );
  }
}
