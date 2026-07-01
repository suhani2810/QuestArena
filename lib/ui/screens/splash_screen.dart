import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Warp Speed Starfield
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _WarpPainter(progress: _controller.value),
                size: Size.infinite,
              );
            },
          ),

          // Cinematic Overlay Glows
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.8),
                ],
                radius: 1.2,
              ),
            ),
          ),

          // Central Branding
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Shield Logo
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Glow
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonCyan.withValues(alpha: 0.2),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 2.seconds),

                    const Icon(
                      Icons.shield_rounded,
                      size: 100,
                      color: AppColors.gold,
                    )
                        .animate()
                        .fade(duration: 800.ms)
                        .scale(delay: 200.ms, curve: Curves.elasticOut)
                        .shimmer(delay: 1.seconds, duration: 1.5.seconds),
                  ],
                ),

                const SizedBox(height: 32),

                // App Name with Cyberpunk Glitch effect
                Text(
                  'QUEST ARENA',
                  style: AppTextStyles.display.copyWith(
                    letterSpacing: 12,
                    fontSize: 36,
                    shadows: [
                      const Shadow(
                          color: AppColors.neonCyan,
                          blurRadius: 10,
                          offset: Offset(-2, 0)),
                      const Shadow(
                          color: AppColors.neonPink,
                          blurRadius: 10,
                          offset: Offset(2, 0)),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 1.seconds)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic)
                    .then()
                    .shimmer(duration: 2.seconds),

                const SizedBox(height: 16),

                // Loading Line
                Container(
                  height: 2,
                  width: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.neonCyan,
                        AppColors.neonViolet,
                        AppColors.neonPink
                      ],
                    ),
                  ),
                ).animate().scaleX(
                    begin: 0,
                    end: 1,
                    duration: 2.seconds,
                    curve: Curves.easeInOutExpo),

                const SizedBox(height: 12),

                Text(
                  'PREPARING FOR BATTLE...',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 4,
                    fontSize: 10,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .fadeIn(duration: 1.seconds)
                    .fadeOut(delay: 800.ms, duration: 1.seconds),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarpPainter extends CustomPainter {
  final double progress;
  _WarpPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final random = math.Random(12345);

    // We draw stars as lines stretching from center
    for (int i = 0; i < 150; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final startDist = random.nextDouble() * 1.5; // normalized 0 to 1.5

      // Calculate current position based on progress
      double currentDist = (startDist + progress) % 1.5;

      // Warp speed curve: things accelerate as they move away from center
      double speedFactor = math.pow(currentDist, 2.5).toDouble();

      final opacity = (currentDist * 0.8).clamp(0.0, 1.0);
      final color = i % 10 == 0
          ? AppColors.neonCyan.withValues(alpha: opacity)
          : i % 15 == 0
              ? AppColors.neonViolet.withValues(alpha: opacity)
              : Colors.white.withValues(alpha: opacity);

      final paint = Paint()
        ..color = color
        ..strokeWidth = 1.0 + (speedFactor * 2)
        ..strokeCap = StrokeCap.round;

      final startPos = Offset(
        center.dx + math.cos(angle) * (speedFactor * size.width * 0.5),
        center.dy + math.sin(angle) * (speedFactor * size.width * 0.5),
      );

      final endPos = Offset(
        center.dx + math.cos(angle) * ((speedFactor + 0.05) * size.width * 0.5),
        center.dy + math.sin(angle) * ((speedFactor + 0.05) * size.width * 0.5),
      );

      canvas.drawLine(startPos, endPos, paint);
    }
  }

  @override
  bool shouldRepaint(_WarpPainter oldDelegate) => true;
}
