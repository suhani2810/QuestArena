import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/app_theme.dart';

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
      duration: const Duration(seconds: 4),
    )..forward();
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
          // Dark Galaxy with rushing neon colors
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _GalaxyPainter(progress: _controller.value),
                size: Size.infinite,
              );
            },
          ),
          
          // Quest Arena Tag
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'QUEST ARENA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                    fontFamily: 'Orbitron', // Using a sophisticated font if available, else default bold
                  ),
                )

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Icon
            const Icon(
              Icons.shield_rounded,
              size: 100,
              color: AppColors.gold,
            )
                .animate()
                .fade(duration: 800.ms)
                .scale(delay: 200.ms, curve: Curves.elasticOut),

            const SizedBox(height: 24),

            // App Name
            Text(
              'QUESTARENA',
              style: AppTextStyles.display.copyWith(letterSpacing: 4),
            )
                .animate()
                .fadeIn(duration: 1500.ms, curve: Curves.easeIn)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), duration: 2000.ms),
                
                const SizedBox(height: 10),
                
                Container(
                  height: 2,
                  width: 100,
                  color: AppColors.neonCyan.withValues(alpha: 0.5),
                ).animate().scaleX(begin: 0, end: 1, duration: 1000.ms, delay: 1000.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GalaxyPainter extends CustomPainter {
  final double progress;
  _GalaxyPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final random = math.Random(42);
    
    // Star field
    final starPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 100; i++) {
      starPaint.color = Colors.white.withValues(alpha: random.nextDouble() * 0.5);
      final offset = Offset(random.nextDouble() * size.width, random.nextDouble() * size.height);
      canvas.drawCircle(offset, random.nextDouble() * 1.5, starPaint);
    }

    // Neon rushing particles
    final neonColors = [
      AppColors.neonCyan,
      AppColors.neonViolet,
      AppColors.neonPink,
      AppColors.neonAmber,
    ];

    for (int i = 0; i < 40; i++) {
      final color = neonColors[i % neonColors.length];
      final paint = Paint()
        ..color = color.withValues(alpha: (1.0 - progress).clamp(0.0, 0.6))
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      // Particles starting from outside and rushing inward
      final angle = random.nextDouble() * 2 * math.pi;
      final startRadius = math.max(size.width, size.height) * 0.8;
      final currentRadius = startRadius * (1.0 - progress);
      
      final startPos = Offset(
        center.dx + math.cos(angle) * startRadius,
        center.dy + math.sin(angle) * startRadius,
      );
      
      final currentPos = Offset(
        center.dx + math.cos(angle) * currentRadius,
        center.dy + math.sin(angle) * currentRadius,
      );

      // Draw a line representing the rush
      canvas.drawLine(
        Offset(
          center.dx + math.cos(angle) * (currentRadius + 50),
          center.dy + math.sin(angle) * (currentRadius + 50),
        ),
        currentPos,
        paint,
      );
      
      // Add a glow
      canvas.drawCircle(
        currentPos,
        4.0,
        Paint()
          ..color = color.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
  }

  @override
  bool shouldRepaint(_GalaxyPainter oldDelegate) => true;
}
