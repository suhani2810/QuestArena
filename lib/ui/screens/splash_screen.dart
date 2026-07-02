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
      duration: const Duration(seconds: 10),
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
        fit: StackFit.expand,
        children: [
          // 1. Warp Speed Background
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _StarfieldPainter(progress: _controller.value),
                size: Size.infinite,
              );
            },
          ),
          
          // 2. Cinematic Radial Overlay
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.5),
                  Colors.black,
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
          ),

          // 3. Central Branding
          Center(
            child: SingleChildScrollView( // Safety against keyboard or small heights
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Shield Logo with Pulse & Glow
                  _buildAnimatedLogo(),

                  const SizedBox(height: 50),

                  // App Name with NO-WRAP Guarantee
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Text(
                            'QUEST ARENA',
                            maxLines: 1,
                            softWrap: false,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.display.copyWith(
                              letterSpacing: 8,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                  color: AppColors.neonCyan.withValues(alpha: 0.8),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 800.ms)
                  .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack)
                  .shimmer(delay: 1.seconds, duration: 2.seconds, color: AppColors.neonPink.withValues(alpha: 0.4)),
                  
                  const SizedBox(height: 12),
                  
                  // Tactical Subtitle
                  Text(
                    'P R E P A R I N G  B A T T L E  S Y S T E M S',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.neonCyan,
                      fontSize: 10,
                      letterSpacing: 3,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 1200.ms)
                  .blur(begin: const Offset(10, 0), end: Offset.zero),

                  const SizedBox(height: 60),
                  
                  // Progress Loader
                  _buildLoadingBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer pulsing rings
        ...List.generate(2, (index) {
          return Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.neonCyan.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          )
          .animate(onPlay: (c) => c.repeat())
          .scale(
            duration: 2.seconds,
            begin: const Offset(1, 1),
            end: const Offset(1.6, 1.6),
            curve: Curves.easeOut,
            delay: (index * 1).seconds,
          )
          .fadeOut();
        }),

        // Main Shield Icon
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.7), width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.3),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.shield_rounded,
            size: 64,
            color: AppColors.gold,
          ),
        )
        .animate()
        .scale(duration: 1.seconds, curve: Curves.elasticOut)
        .shimmer(delay: 2.seconds, duration: 3.seconds),
      ],
    );
  }

  Widget _buildLoadingBar() {
    return Column(
      children: [
        Container(
          width: 220,
          height: 3,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.white10,
          ),
          child: Stack(
            children: [
              Container(
                width: 220,
                height: 3,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.neonCyan, AppColors.neonViolet],
                  ),
                ),
              )
              .animate()
              .scaleX(begin: 0, end: 1, duration: 3.seconds, curve: Curves.easeInOutExpo),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'AUTHENTICATING SIGNAL...',
          style: TextStyle(
            color: Colors.white30,
            fontSize: 9,
            letterSpacing: 3,
            fontWeight: FontWeight.w900,
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 1.seconds),
      ],
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  final double progress;
  _StarfieldPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final random = math.Random(777);
    
    for (int i = 0; i < 180; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final initialDist = random.nextDouble();
      
      // Accelerated expansion curve
      double currentDist = (initialDist + progress) % 1.0;
      double speedFactor = math.pow(currentDist, 3).toDouble();
      
      final opacity = (currentDist * 0.9).clamp(0.0, 1.0);
      final color = i % 15 == 0 
          ? AppColors.neonCyan.withValues(alpha: opacity)
          : i % 25 == 0 
              ? AppColors.neonViolet.withValues(alpha: opacity)
              : Colors.white.withValues(alpha: opacity);

      final paint = Paint()
        ..color = color
        ..strokeWidth = 1.0 + (speedFactor * 4)
        ..strokeCap = StrokeCap.round;

      final startPos = Offset(
        center.dx + math.cos(angle) * (speedFactor * size.width * 0.6),
        center.dy + math.sin(angle) * (speedFactor * size.width * 0.6),
      );
      
      final endPos = Offset(
        center.dx + math.cos(angle) * ((speedFactor + 0.05) * size.width * 0.6),
        center.dy + math.sin(angle) * ((speedFactor + 0.05) * size.width * 0.6),
      );

      canvas.drawLine(startPos, endPos, paint);
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter oldDelegate) => true;
}
