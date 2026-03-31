import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/vibe_model.dart';
import '../../../../core/theme/vibe_theme_extension.dart';

class VibeBackgroundParticles extends StatefulWidget {
  final Widget child;

  const VibeBackgroundParticles({super.key, required this.child});

  @override
  State<VibeBackgroundParticles> createState() => _VibeBackgroundParticlesState();
}

class _VibeBackgroundParticlesState extends State<VibeBackgroundParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..addListener(() {
        _updateParticles();
        setState(() {});
      })
      ..repeat();
  }

  void _initParticles(ParticleEffectType type, Size size) {
    if (_particles.isNotEmpty) return;
    int count = type == ParticleEffectType.stars ? 40 : 80;
    for (int i = 0; i < count; i++) {
      _particles.add(_Particle(
        x: _rnd.nextDouble() * size.width,
        y: _rnd.nextDouble() * size.height,
        speed: _rnd.nextDouble() * 2 + 1,
        radius: _rnd.nextDouble() * 3 + 1,
        color: _getRandomColorForEffect(type),
        drift: (_rnd.nextDouble() - 0.5) * 2,
      ));
    }
  }

  Color _getRandomColorForEffect(ParticleEffectType type) {
    switch (type) {
      case ParticleEffectType.snow:
        return Colors.white.withValues(alpha: _rnd.nextDouble() * 0.5 + 0.3);
      case ParticleEffectType.confetti:
      case ParticleEffectType.colorDust:
        final colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.cyan];
        return colors[_rnd.nextInt(colors.length)].withValues(alpha: 0.6);
      case ParticleEffectType.stars:
        return Colors.amber.withValues(alpha: _rnd.nextDouble() * 0.5 + 0.3);
      default:
        return Colors.white24;
    }
  }

  void _updateParticles() {
    if (!mounted || _particles.isEmpty) return;
    final size = MediaQuery.of(context).size;
    
    for (var p in _particles) {
      p.y += p.speed;
      p.x += p.drift;
      
      // Reset if offscreen
      if (p.y > size.height) {
        p.y = -10;
        p.x = _rnd.nextDouble() * size.width;
      }
      if (p.x > size.width || p.x < 0) {
        p.drift = -p.drift;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vibe = Theme.of(context).extension<VibeThemeExtension>();
    final activeEffect = vibe?.particleEffect ?? ParticleEffectType.none;

    if (activeEffect == ParticleEffectType.none) {
      _particles.clear();
      return widget.child;
    }

    // Initialize if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_particles.isEmpty && mounted) {
        _initParticles(activeEffect, MediaQuery.of(context).size);
      }
    });

    return Stack(
      children: [
        widget.child,
        IgnorePointer(
          child: CustomPaint(
            size: Size.infinite,
            painter: _ParticlePainter(_particles, activeEffect),
          ),
        ),
      ],
    );
  }
}

class _Particle {
  double x;
  double y;
  double speed;
  double radius;
  Color color;
  double drift;

  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.radius,
    required this.color,
    required this.drift,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final ParticleEffectType type;

  _ParticlePainter(this.particles, this.type);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()..color = p.color;
      
      if (type == ParticleEffectType.stars) {
        // Draw a simple star/diamond
        final path = Path()
          ..moveTo(p.x, p.y - p.radius)
          ..lineTo(p.x + p.radius / 2, p.y)
          ..lineTo(p.x, p.y + p.radius)
          ..lineTo(p.x - p.radius / 2, p.y)
          ..close();
        canvas.drawPath(path, paint);
      } else {
        // Draw circle
        canvas.drawCircle(Offset(p.x, p.y), p.radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
