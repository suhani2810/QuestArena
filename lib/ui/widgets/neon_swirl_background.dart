import 'dart:math' as math;
import 'package:flutter/material.dart';

class NeonSwirlBackground extends StatefulWidget {
  final List<Color> colors;
  final Widget child;

  const NeonSwirlBackground({
    super.key,
    required this.colors,
    required this.child,
  });

  @override
  State<NeonSwirlBackground> createState() => _NeonSwirlBackgroundState();
}

class _NeonSwirlBackgroundState extends State<NeonSwirlBackground>
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
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _SwirlPainter(
                colors: widget.colors,
                progress: _controller.value,
              ),
              size: Size.infinite,
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class _SwirlPainter extends CustomPainter {
  final List<Color> colors;
  final double progress;

  _SwirlPainter({required this.colors, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    for (int i = 0; i < 5; i++) {
      final color = colors[i % colors.length];
      final paint = Paint()
        ..color = color.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

      // Orbital movement
      final radius = (size.width * 0.3) + random.nextDouble() * 100;
      final angle = (progress * 2 * math.pi) + (i * math.pi / 2.5);
      
      final x = size.width / 2 + math.cos(angle) * radius * math.sin(progress * math.pi);
      final y = size.height / 2 + math.sin(angle) * radius * math.cos(progress * math.pi);

      canvas.drawCircle(Offset(x, y), 60 + random.nextDouble() * 40, paint);
    }
  }

  @override
  bool shouldRepaint(_SwirlPainter oldDelegate) => true;
}
