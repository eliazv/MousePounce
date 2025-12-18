import 'dart:math';
import 'package:flutter/material.dart';

/// Decorative background widget with animated gradient for the game area
class AnimatedBackgroundWidget extends StatefulWidget {
  final Widget child;

  const AnimatedBackgroundWidget({Key? key, required this.child})
      : super(key: key);

  @override
  State<AnimatedBackgroundWidget> createState() =>
      _AnimatedBackgroundWidgetState();
}

class _AnimatedBackgroundWidgetState extends State<AnimatedBackgroundWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  const Color.fromARGB(255, 187, 216, 182),
                  const Color.fromARGB(255, 165, 200, 160),
                  (sin(_controller.value * 2 * pi) + 1) / 2,
                )!,
                Color.lerp(
                  const Color.fromARGB(255, 200, 228, 195),
                  const Color.fromARGB(255, 175, 210, 170),
                  (cos(_controller.value * 2 * pi) + 1) / 2,
                )!,
              ],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Widget that creates a decorative border around the green felt table
class FeltTableBorder extends StatelessWidget {
  final Widget child;
  final double borderWidth;

  const FeltTableBorder({
    Key? key,
    required this.child,
    this.borderWidth = 12.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color.fromARGB(255, 139, 69, 19), // Saddle brown
          width: borderWidth,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          // Inner shadow effect
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color.fromARGB(255, 184, 134, 11), // Dark goldenrod
            width: 3,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color.fromARGB(255, 160, 82, 45), // Sienna
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Animated sparkle particles behind the cat player
class SparkleBackground extends StatefulWidget {
  final int playerIndex;

  const SparkleBackground({
    Key? key,
    required this.playerIndex,
  }) : super(key: key);

  @override
  State<SparkleBackground> createState() => _SparkleBackgroundState();
}

class _SparkleBackgroundState extends State<SparkleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> particles;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    particles = List.generate(
      15,
      (index) => _Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 3 + 1,
        speed: random.nextDouble() * 0.5 + 0.3,
        phase: random.nextDouble() * 2 * pi,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getParticleColor() {
    return Colors.white.withValues(alpha: 0.3);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _SparklesPainter(
            particles: particles,
            animationValue: _controller.value,
            color: _getParticleColor(),
          ),
          child: Container(),
        );
      },
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double phase;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
  });
}

class _SparklesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;
  final Color color;

  _SparklesPainter({
    required this.particles,
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var particle in particles) {
      final x = particle.x * size.width;
      final y = particle.y * size.height;
      final opacity = (sin(animationValue * 2 * pi * particle.speed + particle.phase) + 1) / 2;

      paint.color = color.withValues(alpha: color.a * opacity);
      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        paint,
      );

      // Draw a cross sparkle effect
      paint.strokeWidth = 1;
      paint.style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(x - particle.size * 2, y),
        Offset(x + particle.size * 2, y),
        paint,
      );
      canvas.drawLine(
        Offset(x, y - particle.size * 2),
        Offset(x, y + particle.size * 2),
        paint,
      );
      paint.style = PaintingStyle.fill;
    }
  }

  @override
  bool shouldRepaint(_SparklesPainter oldDelegate) => true;
}
