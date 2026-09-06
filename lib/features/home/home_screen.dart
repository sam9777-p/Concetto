import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

// 1. Define the Star Model
class Star {
  final double x;
  final double y;
  final double size;
  final bool isCross;
  final double twinkleSpeed;
  final Color color;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.isCross,
    required this.twinkleSpeed,
    required this.color,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _starController;
  List<Star> _stars = [];

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stars.isEmpty) {
      _generateStars(MediaQuery.of(context).size);
    }
  }

  void _generateStars(Size size) {
    final random = math.Random(42);
    for (int i = 0; i < 80; i++) {
      final isCross = random.nextDouble() > 0.85; // 15% chance to be a cross
      _stars.add(
        Star(
          x: random.nextDouble() * size.width,
          y: random.nextDouble() * size.height,
          size: isCross ? random.nextDouble() * 3 + 2 : random.nextDouble() * 1.5 + 0.5,
          isCross: isCross,
          twinkleSpeed: random.nextDouble() * 3 + 1,
          color: isCross
              ? const Color(0xFFFF5722).withOpacity(0.6) // Orange tint for crosses
              : Colors.white.withOpacity(random.nextDouble() * 0.5 + 0.3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070202),
      body: Stack(
        children: [
          // Twinkling Starfield Layer
          AnimatedBuilder(
            animation: _starController,
            builder: (context, child) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: StarfieldPainter(
                  animationValue: _starController.value,
                  stars: _stars,
                ),
              );
            },
          ),

          // ... (Keep your Planet, Orb, and Navbar widgets here) ...

          // Static Logo Layer (No Transform.translate)
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/logo_final.webp', height: 90),
                    const SizedBox(width: 4),
                    Image.asset('assets/logo_hero.webp', height: 75),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 2. The Custom Painter
class StarfieldPainter extends CustomPainter {
  final double animationValue;
  final List<Star> stars;

  StarfieldPainter({required this.animationValue, required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    for (var star in stars) {
      // Calculate twinkling opacity using a sine wave
      final twinkle = (math.sin(animationValue * math.pi * 2 * star.twinkleSpeed) + 1) / 2;
      final currentOpacity = (star.color.opacity * twinkle).clamp(0.1, 1.0);

      final paint = Paint()
        ..color = star.color.withOpacity(currentOpacity)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;

      if (star.isCross) {
        // Draw + shape
        canvas.drawLine(Offset(star.x - star.size, star.y), Offset(star.x + star.size, star.y), paint);
        canvas.drawLine(Offset(star.x, star.y - star.size), Offset(star.x, star.y + star.size), paint);
      } else {
        // Draw circular dot
        canvas.drawCircle(Offset(star.x, star.y), star.size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant StarfieldPainter oldDelegate) => true;
}