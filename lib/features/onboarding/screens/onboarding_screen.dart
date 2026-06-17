import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/pref_keys.dart';
import '../../../core/routes/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  // Onboarding data with image paths
  final List<_OnboardingSlide> _slides = const [
    _OnboardingSlide(
      imagePath: 'assets/onboarding/onboarding_1.png',
      title: 'Selamat Datang di Komars',
      subtitle:
          'Ekosistem agri-kuliner yang menghubungkan petani lokal\ndengan pengalaman kuliner premium.',
    ),
    _OnboardingSlide(
      imagePath: 'assets/onboarding/onboarding_2.png',
      title: 'Pesan Makanan Segar',
      subtitle:
          'Nikmati hidangan lezat yang bahan-bahannya langsung\ndari mitra tani Komars Farm.',
    ),
    _OnboardingSlide(
      imagePath: 'assets/onboarding/onboarding_3.png',
      title: 'Dukung Petani Lokal',
      subtitle:
          'Setiap pesanan Anda mendukung keberlanjutan pertanian\nlokal dan ekosistem ramah lingkungan.',
    ),
  ];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Fade-in animation for bottom content
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Auto-scroll every 4 seconds
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final nextPage = (_currentPage + 1) % _slides.length;
      _pageCtrl.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _resetAutoScroll() {
    _autoScrollTimer?.cancel();
    _startAutoScroll();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.isOnboardingDone, true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageCtrl.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.58;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ─── Top: Image Carousel ─────────────────────────────────────
          SizedBox(
            height: imageHeight,
            child: Stack(
              children: [
                // Photo PageView
                PageView.builder(
                  controller: _pageCtrl,
                  itemCount: _slides.length,
                  onPageChanged: (i) {
                    setState(() => _currentPage = i);
                    _resetAutoScroll();
                    // Animate text content
                    _fadeController.reset();
                    _fadeController.forward();
                  },
                  itemBuilder: (context, i) {
                    return Image.asset(
                      _slides[i].imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: imageHeight,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback gradient if image not found
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF1B5E20).withValues(alpha: 0.8),
                                const Color(0xFF2E7D32),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  i == 0
                                      ? Icons.eco_rounded
                                      : i == 1
                                          ? Icons.restaurant_menu_rounded
                                          : Icons.handshake_rounded,
                                  size: 80,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Gambar akan ditampilkan di sini',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 14,
                                    color:
                                        Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                // Bottom gradient fade (image to white transition)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.6),
                          Colors.white,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),

                // Page Indicators (centered, over the image)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF1B5E20)
                              : const Color(0xFF1B5E20).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // ─── Bottom: Text + Buttons ──────────────────────────────────
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // Title
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.15),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        _slides[_currentPage].title,
                        key: ValueKey<int>(_currentPage),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B5E20),
                          height: 1.3,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subtitle
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      child: Text(
                        _slides[_currentPage].subtitle,
                        key: ValueKey<String>(
                            '${_currentPage}_subtitle'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          color: Color(0xFF666666),
                          height: 1.6,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // ─── "Masuk" Full-Width Button ──────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _finish,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          shadowColor: Colors.transparent,
                        ),
                        child: const Text(
                          'Masuk',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ─── "Lewati tahap ini" Link ────────────────────
                    GestureDetector(
                      onTap: _finish,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Lewati tahap ini',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF888888),
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFFBBBBBB),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide {
  final String imagePath;
  final String title;
  final String subtitle;

  const _OnboardingSlide({
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });
}
