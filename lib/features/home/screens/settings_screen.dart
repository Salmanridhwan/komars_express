import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/pref_keys.dart';

// We will use a ValueNotifier defined in main.dart to trigger dynamic rebuilds of MaterialApp
// We will import or access it via a static helper or notify it dynamically.
// To keep things simple and decoupled, we can define a static ValueNotifier in a central class
// or check if we can declare a global theme notifier. Let's assume there is a global notifier
// we can call. We will design one in main.dart: `MyApp.themeNotifier`.

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDark = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isDark = prefs.getBool(PrefKeys.isDarkMode) ?? false;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.isDarkMode, value);
    setState(() {
      _isDark = value;
    });

    // Notify main.dart theme notifier if it exists.
    // We'll call a static method on main.dart's MyApp or use a notification dispatch.
    // Let's implement static themeNotifier in main.dart.
    try {
      // We will access a global theme notifier that we will define in main.dart.
      // Since Dart allows dynamic lookups or we can just invoke the global notifier.
      // We can use a custom top-level notifier or a state.
      // To ensure no compile errors, we can check if there's a dynamic notification.
      // For now, let's trigger it by modifying a global notifier.
      themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {}
  }

  Future<void> _resetApp() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Aplikasi?'),
        content: const Text(
            'Semua data sesi, tema, dan onboarding akan dikembalikan ke setelan awal. Anda harus masuk kembali.'),
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
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aplikasi berhasil di-reset')),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tampilan & Tema',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDarkTheme
                          ? AppColors.primaryGreenLight
                          : AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkTheme ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDarkTheme
                            ? AppColors.darkDivider
                            : AppColors.lightDivider,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        _isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: _isDark
                            ? AppColors.secondaryOrangeLight
                            : AppColors.secondaryOrange,
                      ),
                      title: const Text(
                        'Mode Gelap (Dark Mode)',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Switch(
                        value: _isDark,
                        activeColor: AppColors.primaryGreenLight,
                        onChanged: _toggleTheme,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'Data & Keamanan',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDarkTheme
                          ? AppColors.primaryGreenLight
                          : AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkTheme ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDarkTheme
                            ? AppColors.darkDivider
                            : AppColors.lightDivider,
                      ),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.settings_backup_restore_rounded,
                        color: AppColors.deleteRed,
                      ),
                      title: const Text(
                        'Reset Data Aplikasi',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Hapus sesi masuk dan preferensi aplikasi',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _resetApp,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'Tentang Komars App',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDarkTheme
                          ? AppColors.primaryGreenLight
                          : AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDarkTheme ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDarkTheme
                            ? AppColors.darkDivider
                            : AppColors.lightDivider,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.between,
                          children: [
                            Text(
                              'Versi Aplikasi',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'v1.0.0 (Assessment 3)',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Divider(
                          height: 24,
                          color: isDarkTheme
                              ? AppColors.darkDivider
                              : AppColors.lightDivider,
                        ),
                        const Text(
                          'Pilar Ekosistem:',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const _PillarRow(
                          icon: Icons.restaurant_rounded,
                          color: AppColors.secondaryOrange,
                          text: 'Komars Express (F&B, Dine-in & Pemesanan)',
                        ),
                        const SizedBox(height: 8),
                        const _PillarRow(
                          icon: Icons.agriculture_rounded,
                          color: AppColors.primaryGreen,
                          text: 'Komars Farm (Agribisnis, Sourcing Mitra)',
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

class _PillarRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _PillarRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

// A global ValueNotifier that we can export to track changes in the brightness.
// We'll define it here so both main.dart and settings_screen.dart can access it.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);
