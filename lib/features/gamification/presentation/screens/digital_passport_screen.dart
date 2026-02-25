import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class DigitalPassportScreen extends StatefulWidget {
  const DigitalPassportScreen({super.key});

  @override
  State<DigitalPassportScreen> createState() => _DigitalPassportScreenState();
}

class _DigitalPassportScreenState extends State<DigitalPassportScreen> with SingleTickerProviderStateMixin {
  bool _isPressing = false;
  bool _isStamped = false;
  double _pressProgress = 0.0;
  Timer? _pressTimer;
  Timer? _vibrationTimer;

  // Mock Data
  final String _currentLocation = "Kyoto, Japan";
  final String _arrivalDate = "Oct 14, 2024";

  void _onPressStart(LongPressStartDetails details) {
    if (_isStamped) return;

    setState(() {
      _isPressing = true;
      _pressProgress = 0.0;
    });

    // Fire haptics repeatedly while "scanning"
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      HapticFeedback.selectionClick();
    });

    // Fill the progress over 2 seconds
    const int totalTicks = 100;
    const int tickDuration = 2000 ~/ totalTicks; // 20ms per tick
    
    _pressTimer = Timer.periodic(const Duration(milliseconds: tickDuration), (timer) {
      if (!mounted) return;
      setState(() {
        _pressProgress += (1.0 / totalTicks);
      });

      if (_pressProgress >= 1.0) {
        _onScanComplete();
      }
    });
  }

  void _onPressCancel() {
    if (_isStamped) return;

    _vibrationTimer?.cancel();
    _pressTimer?.cancel();
    setState(() {
      _isPressing = false;
      _pressProgress = 0.0;
    });
  }

  void _onScanComplete() {
    _vibrationTimer?.cancel();
    _pressTimer?.cancel();

    // The violent slam of the stamp
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () => HapticFeedback.heavyImpact());

    setState(() {
      _isPressing = false;
      _isStamped = true;
    });
  }

  @override
  void dispose() {
    _vibrationTimer?.cancel();
    _pressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2128), // Dark desk background
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            const SizedBox(height: 20),
            _buildLocationSensorCard(),
            const SizedBox(height: 40),
            Expanded(child: _buildPassportBooklet()),
            const SizedBox(height: 40),
            _buildThumbprintScanner(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12),
            ),
            child: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Text(
            'DIGITAL PASSPORT',
            style: GoogleFonts.inter(
              color: AppTheme.accentAmber,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 48), // Balance for back button
        ],
      ),
    );
  }

  Widget _buildLocationSensorCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentTeal.withValues(alpha: 0.1),
        border: Border.all(color: AppTheme.accentTeal.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.mapPin, color: AppTheme.accentTeal),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "GPS Location Verified",
                  style: GoogleFonts.inter(color: AppTheme.accentTeal, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentLocation,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (!_isStamped)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.accentTeal, borderRadius: BorderRadius.circular(8)),
              child: const Text("Ready to stamp", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .fade(begin: 0.5, end: 1.0),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildPassportBooklet() {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F1EA), // High-quality passport paper
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, offset: const Offset(0, 20)),
            // Inner shadow to look like paper thickness
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, spreadRadius: -2, offset: const Offset(-2, 0)),
          ],
        ),
        child: Stack(
          children: [
            // Watermark background pattern
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: Icon(LucideIcons.globe, size: 300, color: Colors.blue[900]),
              ),
            ),
            
            // Subtle paper texture grain lines
            Positioned.fill(
              child: CustomPaint(painter: _PaperTexturePainter()),
            ),

            // The actual page content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "VISAS",
                        style: GoogleFonts.inter(
                          color: Colors.blue[900]!.withValues(alpha: 0.3),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),
                      Text(
                        "PAGE 12",
                        style: GoogleFonts.inter(
                          color: Colors.blue[900]!.withValues(alpha: 0.3),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // The dynamically appearing Stamp
                  if (_isStamped)
                    Center(
                      child: Transform.rotate(
                        angle: -0.15, // Slightly crooked for realism
                        child: _buildRealisticStamp(),
                      ),
                    ),
                    
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildRealisticStamp() {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.red[800]!.withValues(alpha: 0.85), width: 6),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner dashed border
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red[800]!.withValues(alpha: 0.85), width: 2),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "ARRIVED",
                style: GoogleFonts.oswald(
                  color: Colors.red[800]!.withValues(alpha: 0.9),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 8),
              Icon(LucideIcons.planeLanding, color: Colors.red[800]!.withValues(alpha: 0.9), size: 32),
              const SizedBox(height: 8),
              Text(
                _currentLocation.toUpperCase(),
                style: GoogleFonts.inter(
                  color: Colors.red[800]!.withValues(alpha: 0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _arrivalDate.toUpperCase(),
                style: GoogleFonts.courierPrime(
                  color: Colors.red[800]!.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Distressed/Grunge overlay effect could go here
        ],
      ),
    )
    .animate()
    .scale(begin: const Offset(3.0, 3.0), end: const Offset(1.0, 1.0), duration: 250.ms, curve: Curves.easeInQuint)
    .fade(duration: 250.ms)
    // Add a very slight shake to simulate physical impact
    .shake(hz: 4, curve: Curves.decelerate, duration: 300.ms);
  }

  Widget _buildThumbprintScanner() {
    return Column(
      children: [
        Text(
          _isStamped ? "STAMP SECURED" : (_isPressing ? "UPDATING LEDGER..." : "PRESS & HOLD TO STAMP"),
          style: GoogleFonts.inter(
            color: _isStamped ? AppTheme.accentTeal : Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ).animate(key: ValueKey(_isPressing || _isStamped)).fadeIn(),
        const SizedBox(height: 20),
        
        GestureDetector(
          onLongPressStart: _onPressStart,
          onLongPressEnd: (details) => _onPressCancel(),
          onLongPressCancel: _onPressCancel,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isStamped 
                  ? AppTheme.accentTeal.withValues(alpha: 0.2) 
                  : (_isPressing ? AppTheme.accentAmber.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05)),
              border: Border.all(
                color: _isStamped 
                    ? AppTheme.accentTeal 
                    : (_isPressing ? AppTheme.accentAmber : Colors.white24),
                width: 2,
              ),
              boxShadow: _isPressing && !_isStamped ? [
                BoxShadow(color: AppTheme.accentAmber.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 5)
              ] : [],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!_isStamped)
                  CircularProgressIndicator(
                    value: _pressProgress,
                    strokeWidth: 4,
                    color: AppTheme.accentAmber,
                    backgroundColor: Colors.transparent,
                  ),
                Icon(
                  _isStamped ? LucideIcons.check : LucideIcons.fingerprint,
                  color: _isStamped 
                      ? AppTheme.accentTeal 
                      : (_isPressing ? AppTheme.accentAmber : Colors.white),
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// A simple painter to add some visual "security thread" wavy lines to the passport paper
class _PaperTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue[900]!.withValues(alpha: 0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.height; i += 20) {
      final path = Path();
      path.moveTo(0, i);
      for (double j = 0; j < size.width; j += 40) {
        path.quadraticBezierTo(j + 20, i + 10, j + 40, i);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
