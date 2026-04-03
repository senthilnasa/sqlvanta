import 'package:flutter/material.dart';

/// Full-screen splash shown while the app initialises.
/// Fades + scales the logo in, then fades the whole screen out.
class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Entrance: logo + text fade/scale in
  late final Animation<double> _logoScale;
  late final Animation<double> _contentFade;

  // Exit: entire screen fades out
  late final Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    // 0–0.35 → logo scales 0.78→1.0 with elastic bounce
    _logoScale = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.35, curve: Curves.elasticOut),
      ),
    );

    // 0–0.40 → content fades in
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOut),
      ),
    );

    // 0.72–1.0 → screen fades out
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.72, 1.0, curve: Curves.easeIn),
      ),
    );

    _ctrl.forward().then((_) {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final bg = isDark ? const Color(0xFF0E0E1A) : const Color(0xFF1565C0);

    return AnimatedBuilder(
      animation: _ctrl,
      builder:
          (ctx, child) => Opacity(
            opacity: _exitFade.value,
            child: Container(
              color: bg,
              child: Center(
                child: FadeTransition(
                  opacity: _contentFade,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Logo ──────────────────────────────────────────────────
                      ScaleTransition(
                        scale: _logoScale,
                        child: Image.asset(
                          'res/logo.png',
                          width: 220,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── App name ──────────────────────────────────────────────
                      const Text(
                        'SQLvanta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Open-source MySQL Client',
                        style: TextStyle(
                          color: Colors.white.withAlpha(170),
                          fontSize: 13,
                          letterSpacing: 0.4,
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // ── Loading dots ──────────────────────────────────────────
                      _LoadingDots(controller: _ctrl),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }
}

// ── Animated loading dots ─────────────────────────────────────────────────────

class _LoadingDots extends StatelessWidget {
  final AnimationController controller;
  const _LoadingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (ctx, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = ((controller.value * 3) - i).clamp(0.0, 1.0);
            final opacity = (phase < 0.5 ? phase * 2 : (1.0 - phase) * 2).clamp(
              0.2,
              1.0,
            );
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
