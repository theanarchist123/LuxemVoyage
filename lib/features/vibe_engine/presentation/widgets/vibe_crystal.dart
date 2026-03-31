import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/vibe_provider.dart';

class VibeCrystal extends ConsumerStatefulWidget {
  const VibeCrystal({super.key});

  @override
  ConsumerState<VibeCrystal> createState() => _VibeCrystalState();
}

class _VibeCrystalState extends ConsumerState<VibeCrystal> with SingleTickerProviderStateMixin {
  double _chargeLevel = 0.0;
  bool _isHolding = false;
  bool _isShattering = false;

  void _onPanStart(DragDownDetails details) {
    if (_isShattering || !ref.read(vibeProvider).isVibeActive) return;
    HapticFeedback.lightImpact();
    setState(() => _isHolding = true);
    _startCharging();
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isShattering) return;
    setState(() {
      _isHolding = false;
      _chargeLevel = 0.0;
    });
  }

  void _onPanCancel() {
    if (_isShattering) return;
    setState(() {
      _isHolding = false;
      _chargeLevel = 0.0;
    });
  }

  void _startCharging() async {
    const chargeDuration = Duration(milliseconds: 1500);
    const increment = Duration(milliseconds: 30);
    int steps = chargeDuration.inMilliseconds ~/ increment.inMilliseconds;

    for (int i = 0; i <= steps; i++) {
      if (!_isHolding || !mounted) return;
      
      setState(() {
        _chargeLevel = i / steps;
      });

      // Increasing haptic intensity as it charges
      if (i % 10 == 0) {
        if (_chargeLevel > 0.8) {
          HapticFeedback.heavyImpact();
        } else if (_chargeLevel > 0.5) {
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.selectionClick();
        }
      }

      await Future.delayed(increment);
    }

    if (_isHolding && _chargeLevel >= 1.0) {
      _triggerShatter();
    }
  }

  void _triggerShatter() async {
    setState(() {
      _isShattering = true;
      _isHolding = false;
    });
    
    HapticFeedback.heavyImpact();
    
    // Slight delay to let the explosion animation start before snapping the theme back
    await Future.delayed(const Duration(milliseconds: 150));
    ref.read(vibeProvider.notifier).clearVibe();

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _isShattering = false;
        _chargeLevel = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeVibe = ref.watch(vibeProvider);

    if (!activeVibe.isVibeActive && !_isShattering) {
      return const SizedBox.shrink();
    }

    final color = activeVibe.primaryColor ?? AppTheme.accentAmber;

    return Positioned(
      bottom: 24,
      right: 24,
      child: GestureDetector(
        onPanDown: _onPanStart,
        onPanEnd: _onPanEnd,
        onPanCancel: _onPanCancel,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 300),
          scale: _isShattering ? 2.5 : (_isHolding ? 1.0 - (_chargeLevel * 0.15) : 1.0),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isShattering ? 0.0 : 1.0,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Inner Glow / Charge Aura
                if (_isHolding)
                  Container(
                    width: 70 + (_chargeLevel * 30),
                    height: 70 + (_chargeLevel * 30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5 * _chargeLevel),
                          blurRadius: 20 * _chargeLevel,
                          spreadRadius: 10 * _chargeLevel,
                        ),
                      ],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 200.ms),

                // The Crystal Itself
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3 + (_chargeLevel * 0.4)),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.5),
                              color.withValues(alpha: 0.2),
                              color.withValues(alpha: 0.8),
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5 + (_chargeLevel * 0.5)),
                            width: 1.5 + (_chargeLevel * 2),
                          ),
                        ),
                        child: Center(
                          child: _isHolding
                              ? Icon(LucideIcons.zap, 
                                  color: Colors.white, 
                                  size: 24 + (_chargeLevel * 6))
                                  .animate(onPlay: (c) => c.repeat(reverse: true))
                                  .shake(hz: 8 * _chargeLevel) // Violent shake
                              : const Icon(LucideIcons.sparkles, color: Colors.white, size: 24)
                                  .animate(onPlay: (c) => c.repeat(reverse: true))
                                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 2.seconds),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Exploding Particle Effect Overlay (Quick burst on shatter)
                if (_isShattering)
                  ...List.generate(12, (index) {
                    return Positioned(
                      child: Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ).animate()
                       .scale(begin: const Offset(1, 1), end: const Offset(0, 0), duration: 400.ms)
                       .move(
                         begin: Offset.zero,
                         end: Offset(
                           (index % 3 - 1) * 100.0, // spread X
                           (index ~/ 3 - 1) * 100.0, // spread Y
                         ),
                         duration: 400.ms,
                         curve: Curves.easeOutCirc,
                       ),
                    );
                  }),
              ],
            )
            // Idle Pulse
            .animate(onPlay: (c) => _isHolding ? c.stop() : c.repeat(reverse: true))
            .slideY(begin: 0.05, end: -0.05, duration: 3.seconds, curve: Curves.easeInOutSine),
          ),
        ),
      ),
    );
  }
}
