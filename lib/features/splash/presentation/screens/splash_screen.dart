import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../../../main_scaffold.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 900),
          pageBuilder: (_, __, ___) =>
              user != null ? const MainScaffold() : const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: Stack(
          children: [
            // Decorative aurora orbs
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.accentTeal.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 2.seconds),
            Positioned(
              bottom: -100,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.accentViolet.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 2.seconds, delay: 300.ms),

            // Center content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo with pulsing glow
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (_, child) {
                      final glow = _glowController.value * 0.4 + 0.1;
                      return Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentAmber.withOpacity(glow),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.accentAmber.withOpacity(0.15),
                            AppTheme.accentAmber.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: AppTheme.accentAmber.withOpacity(0.6),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "L",
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.accentAmber,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 800.ms)
                      .scale(
                        begin: const Offset(0.7, 0.7),
                        end: const Offset(1, 1),
                        curve: Curves.easeOutBack,
                      ),

                  const SizedBox(height: 32),

                  // Brand name
                  const Text(
                    "LuxeVoyage",
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 800.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),

                  const SizedBox(height: 10),

                  // Tagline
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppTheme.auroraGradient.createShader(bounds),
                    child: const Text(
                      "CURATED TRAVEL EXPERIENCES",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3.0,
                        color: Colors.white,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 700.ms, duration: 800.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
