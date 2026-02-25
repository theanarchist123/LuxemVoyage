import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import 'itinerary_result_screen.dart';

class BlindTripCountdownScreen extends StatefulWidget {
  final String generatedJson;
  
  const BlindTripCountdownScreen({super.key, required this.generatedJson});

  @override
  State<BlindTripCountdownScreen> createState() => _BlindTripCountdownScreenState();
}

class _BlindTripCountdownScreenState extends State<BlindTripCountdownScreen> {
  late Map<String, dynamic> _tripData;
  late List<String> _packingHints;
  
  // For demonstration: counting down 24 hours (fake)
  int _secondsLeft = 86400; 
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    try {
      final cleaned = widget.generatedJson.replaceAll('```json', '').replaceAll('```', '').trim();
      _tripData = jsonDecode(cleaned);
      _packingHints = (_tripData['packing_hints'] as List?)?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      _tripData = {'destination': 'Unknown', 'itinerary': []};
      _packingHints = ['Pack for anything...'];
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _revealNow() {
    final itinerary = (_tripData['itinerary'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final dest = _tripData['destination'] ?? 'Unknown Destination';

    Navigator.pushReplacement(context, PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 800),
      pageBuilder: (_, __, ___) => ItineraryResultScreen(
        destination: dest,
        days: itinerary.length,
        tier: 'Mystery VIP',
        itinerary: itinerary,
      ),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackgroundVortex(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTimerDisplay(),
                        const SizedBox(height: 60),
                        _buildPackingHints(),
                      ],
                    ),
                  ),
                ),
                _buildRevealOptions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundVortex() {
    return Center(
      child: Container(
        width: 300, height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.redAccent.withValues(alpha: 0.15),
              Colors.deepPurple.withValues(alpha: 0.1),
              Colors.transparent,
            ],
            stops: const [0.2, 0.6, 1.0],
          ),
        ),
      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
       .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 2000.ms),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(width: 38), // placeholder
          ShaderMask(
            shaderCallback: (b) => AppTheme.auroraGradient.createShader(b),
            child: const Text('YOUR FLIGHT AWAITS', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.5)),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay() {
    int h = _secondsLeft ~/ 3600;
    int m = (_secondsLeft % 3600) ~/ 60;
    int s = _secondsLeft % 60;

    String timeStr = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Column(
      children: [
        const Icon(LucideIcons.lock, color: Colors.white38, size: 28),
        const SizedBox(height: 16),
        Text(timeStr, style: const TextStyle(
          color: Colors.white, fontSize: 64, fontWeight: FontWeight.w900, letterSpacing: -2, fontFeatures: [FontFeature.tabularFigures()]
        )),
        const SizedBox(height: 8),
        Text("Destination Locked", style: TextStyle(color: AppTheme.accentAmber.withValues(alpha: 0.8), fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 1)),
      ],
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildPackingHints() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.glassCardDecoration(borderRadius: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(LucideIcons.briefcase, color: AppTheme.accentTeal, size: 18),
                SizedBox(width: 8),
                Text("Packing Intel", style: TextStyle(color: AppTheme.accentTeal, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1)),
              ]
            ),
            const SizedBox(height: 16),
            ..._packingHints.map((hint) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("•", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 18, height: 1.2)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(hint, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14, height: 1.4))),
                ],
              ),
            )),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildRevealOptions() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          // For the sake of the demo, we allow cheating.
          GestureDetector(
            onTap: _revealNow,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: const Center(
                child: Text("Cheat: Reveal Early", style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
