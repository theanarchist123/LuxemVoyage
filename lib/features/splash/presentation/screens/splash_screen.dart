import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../../../main_scaffold.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 3800), () {
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 1200),
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF080E1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Deep background glow behind the logo
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.3 + (_glowController.value * 0.4), // Pulses between 0.3 and 0.7
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.accentAmber.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                        stops: const [0.1, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // The Logo
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (_, child) {
                    final scale = 1.0 + (_glowController.value * 0.05); // Subtle breathing
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentAmber.withValues(alpha: 0.1),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'ChatGPT_Image_Feb_22__2026__05_45_13_PM-removebg-preview.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ).animate()
                 .fadeIn(duration: 1200.ms, curve: Curves.easeOut)
                 .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutQuart, duration: 1500.ms),

                const SizedBox(height: 48),

                // Brand Name
                Text(
                  "LuxemVoyage",
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 42,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ).animate()
                 .fadeIn(delay: 800.ms, duration: 1000.ms)
                 .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic, duration: 1000.ms),

                const SizedBox(height: 16),

                // Subtitle / Tagline
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    "CURATED TRAVEL EXPERIENCES",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4.0,
                      color: AppTheme.accentAmber,
                    ),
                  ),
                ).animate()
                 .fadeIn(delay: 1400.ms, duration: 800.ms)
                 .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack, duration: 800.ms),
              ],
            ),
            
            // Subtle loading indicator at bottom
            Positioned(
              bottom: 60,
              child: SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  color: AppTheme.accentAmber.withValues(alpha: 0.5),
                  minHeight: 2,
                ),
              ).animate().fadeIn(delay: 2000.ms, duration: 1000.ms),
            ),
          ],
        ),
      ),
    );
  }
}

