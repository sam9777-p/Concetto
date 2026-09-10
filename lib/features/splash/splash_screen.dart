import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  // ============================================================
  // ▼▼▼  TWEAK THESE VALUES TO CONTROL SIZE & CROP  ▼▼▼
  // ============================================================

  // --- Video display size (fraction of screen) ---
  // 1.0 = full width/height, 0.5 = half, etc.
  static const double videoWidthFactor = 1.0;
  static const double videoHeightFactor = 1.0;

  // --- Crop via alignment (which part of the video is visible) ---
  // Alignment.center = centered (default)
  // Alignment.topCenter = show top, crop bottom
  // Alignment.bottomCenter = show bottom, crop top
  // Alignment(-0.5, -0.3) = custom offset
  static const Alignment videoAlignment = Alignment.center;

  // --- BoxFit controls how the video fits its container ---
  // BoxFit.cover  = fill container, crop excess (no black bars)
  // BoxFit.contain = show entire video, may have black bars
  // BoxFit.fill   = stretch to fill (may distort)
  // BoxFit.fitWidth  = fit width, crop height if needed
  // BoxFit.fitHeight = fit height, crop width if needed
  static const BoxFit videoFit = BoxFit.contain;

  // --- Extra padding around the video container ---
  static const EdgeInsets videoPadding = EdgeInsets.all(0);

  // --- Background color behind the video ---
  static const Color backgroundColor = Color(0xFF0B0403);

  // --- Optional scale transform (1.0 = no zoom, 1.5 = 150% zoom, etc.) ---
  static const double videoScale = 2;

  // ============================================================
  // ▲▲▲  END OF TWEAK SECTION  ▲▲▲
  // ============================================================

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/logo_anim.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
        _controller.play();
      });

    _controller.addListener(_onVideoUpdate);
  }

  void _onVideoUpdate() {
    if (!mounted) return;
    final position = _controller.value.position;
    final duration = _controller.value.duration;

    // Navigate when the video finishes
    if (duration > Duration.zero &&
        position >= duration - const Duration(milliseconds: 100)) {
      _controller.removeListener(_onVideoUpdate);
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    if (!mounted) return;
    context.go('/');
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: GestureDetector(
        // Tap to skip the splash
        onTap: _navigateToHome,
        child: Container(
          color: backgroundColor,
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: Padding(
              padding: videoPadding,
              child: SizedBox(
                width: screenSize.width * videoWidthFactor,
                height: screenSize.height * videoHeightFactor,
                child: _initialized
                    ? Transform.scale(
                        scale: videoScale,
                        child: FittedBox(
                          fit: videoFit,
                          alignment: videoAlignment,
                          clipBehavior: Clip.hardEdge,
                          child: SizedBox(
                            width: _controller.value.size.width,
                            height: _controller.value.size.height,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
