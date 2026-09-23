import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Auto navigate after 2.4 seconds
    Future.delayed(const Duration(milliseconds: 2400), () {
      _navigateToHome();
    });
  }

  void _navigateToHome() {
    if (!_navigated && mounted) {
      _navigated = true;
      context.go('/');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFE85002);
    const darkObsidian = Color(0xFF070709);

    return Scaffold(
      backgroundColor: darkObsidian,
      body: GestureDetector(
        onTap: _navigateToHome,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Wallpaper Image
            Positioned.fill(
              child: Image.asset(
                'assets/images/background.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/splash_bg.webp',
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),

            // Premium Scrim Gradient to ensure high text legibility
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.70),
                      Colors.black.withValues(alpha: 0.45),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),

            // Dark orangish-red ambient radial glow
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.15);
                final opacity = 0.22 + (_pulseController.value * 0.15);
                return Center(
                  child: Container(
                    width: 320 * scale,
                    height: 320 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          primaryOrange.withValues(alpha: opacity),
                          const Color(0xFFB33600).withValues(alpha: opacity * 0.5),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Subtle grid or laser line accents
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 2,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, primaryOrange, Colors.transparent],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Centenary Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: primaryOrange.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 14, color: primaryOrange),
                              const SizedBox(width: 6),
                              Text(
                                "IIT (ISM) DHANBAD • CENTENARY EDITION",
                                style: GoogleFonts.orbitron(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.5, end: 0),

                    // Center: Square Logo with Glowing Frame
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: primaryOrange.withValues(alpha: 0.75),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryOrange.withValues(alpha: 0.45),
                                blurRadius: 36,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/logo_square.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.bolt_rounded,
                                  size: 80,
                                  color: primaryOrange,
                                );
                              },
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                            .scale(
                              begin: const Offset(0.75, 0.75),
                              end: const Offset(1.0, 1.0),
                              duration: 800.ms,
                              curve: Curves.easeOutBack,
                            ),

                        const SizedBox(height: 28),

                        // App Title: Concetto'26
                        Text(
                          "CONCETTO '26",
                          style: GoogleFonts.orbitron(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4.0,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: primaryOrange.withValues(alpha: 0.9),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 600.ms)
                            .slideY(begin: 0.3, end: 0),

                        const SizedBox(height: 8),

                        // Official Theme Tagline
                        Text(
                          "CENTAURI SYNAPSE",
                          style: GoogleFonts.rajdhani(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3.0,
                            color: primaryOrange,
                          ),
                        ).animate().fadeIn(delay: 500.ms, duration: 600.ms),

                        const SizedBox(height: 4),

                        Text(
                          "Forged Over a Century, Soaring Towards Infinity",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.white60,
                            letterSpacing: 0.5,
                          ),
                        ).animate().fadeIn(delay: 700.ms, duration: 600.ms),
                      ],
                    ),

                    // Bottom info: Dates & Skip Indicator
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Fest Dates Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF140806),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: primaryOrange.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: primaryOrange),
                              const SizedBox(width: 8),
                              Text(
                                "OCTOBER 08 – 11, 2026",
                                style: GoogleFonts.orbitron(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 800.ms, duration: 600.ms),

                        const SizedBox(height: 16),

                        // Progress line / Tap indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Tap anywhere to enter",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white38,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.white38),
                          ],
                        ).animate().fadeIn(delay: 1000.ms, duration: 500.ms),
                      ],
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
