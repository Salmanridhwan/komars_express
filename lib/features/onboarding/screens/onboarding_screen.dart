import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/pref_keys.dart';
import '../../../core/routes/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  // Gradients for morphing background based on page
  final List<List<Color>> _backgroundGradients = [
    [const Color(0xFF1B5E20), const Color(0xFF2E7D32), const Color(0xFF0F5132)], // Forest Green (Ecosystem)
    [const Color(0xFFE65100), const Color(0xFFEF6C00), const Color(0xFFD84315)], // Warm Orange (Express F&B)
    [const Color(0xFF0F5132), const Color(0xFF198754), const Color(0xFF20C997)], // Emerald Teal (Mitra Farm)
  ];

  final List<Color> _brandColors = [
    AppColors.primaryGreen,
    AppColors.secondaryOrange,
    AppColors.primaryGreenLight,
  ];

  late List<_OnboardingData> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      _OnboardingData(
        icon: Icons.eco_rounded,
        title: AppStrings.onboarding1Title,
        subtitle: AppStrings.onboarding1Subtitle,
        badges: ['🌱 Ekosistem Lokal', '🤝 Kemitraan Adil', '📈 Terintegrasi'],
      ),
      _OnboardingData(
        icon: Icons.restaurant_menu_rounded,
        title: AppStrings.onboarding2Title,
        subtitle: AppStrings.onboarding2Subtitle,
        badges: ['🍽️ Menu Lezat', '📱 Bayar QRIS', '🪑 Reservasi Meja'],
      ),
      _OnboardingData(
        icon: Icons.handshake_rounded,
        title: AppStrings.onboarding3Title,
        subtitle: AppStrings.onboarding3Subtitle,
        badges: ['💰 Investasi Tani', '🌾 Hasil Melimpah', '📊 Transparan'],
      ),
    ];
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.isOnboardingDone, true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Layer
          AnimatedContainer(
            duration: const Duration(milliseconds: 550),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _backgroundGradients[_currentPage],
              ),
            ),
          ),
          
          // Content Layer
          SafeArea(
            child: Column(
              children: [
                // Main Swipeable Onboarding Cards
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, i) => _OnboardingPage(
                      data: _pages[i],
                      isActive: i == _currentPage,
                    ),
                  ),
                ),

                // Bottom Navigation & Actions Controls
                Container(
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                  children: [
                    // Stretch Page Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        final isActive = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: isActive ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white
                                : Colors.white.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 28),
                    
                    // Action Buttons (Skip / Next / Get Started)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Skip Button (hides on last page)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: _currentPage < _pages.length - 1 ? 1.0 : 0.0,
                          child: IgnorePointer(
                            ignoring: _currentPage >= _pages.length - 1,
                            child: TextButton(
                              onPressed: _finish,
                              child: const Text(
                                AppStrings.skip,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Right: Next / Get Started Button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_currentPage < _pages.length - 1) {
                                _pageCtrl.nextPage(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                _finish();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size.zero,
                              backgroundColor: Colors.white,
                              foregroundColor: _brandColors[_currentPage],
                              padding: EdgeInsets.symmetric(
                                horizontal: _currentPage == _pages.length - 1 ? 32 : 24,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                              elevation: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentPage == _pages.length - 1 
                                      ? AppStrings.getStarted 
                                      : AppStrings.next,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  _currentPage == _pages.length - 1 
                                      ? Icons.rocket_launch_rounded 
                                      : Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  final bool isActive;

  const _OnboardingPage({
    required this.data,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ─── Onboarding Icon Container ───────────────────────────
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(
                data.icon,
                size: 64,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 36),
          
          // ─── Premium Translucent Card ─────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.22),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: data.badges.map((badge) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 20),
                
                // Title Text
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Subtitle Description
                Text(
                  data.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.88),
                    height: 1.55,
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

class _OnboardingData {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> badges;

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badges,
  });
}
