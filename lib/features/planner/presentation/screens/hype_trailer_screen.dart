import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/unsplash_service.dart';
import '../../../../core/services/gemini_service.dart';
import 'itinerary_result_screen.dart';

class HypeTrailerScreen extends StatefulWidget {
  final String destination;
  final int days;
  final String tier;
  final List<Map<String, dynamic>> itinerary;
  final List<String> traits; // Features or aesthetics chosen to generate the persona

  const HypeTrailerScreen({
    super.key,
    required this.destination,
    required this.days,
    required this.tier,
    required this.itinerary,
    required this.traits,
  });

  @override
  State<HypeTrailerScreen> createState() => _HypeTrailerScreenState();
}

class _HypeTrailerScreenState extends State<HypeTrailerScreen> {
  bool _isLoading = true;
  String _personaName = "The Global Wanderer";
  String _personaTagline = "Preparing your bespoke journey...";
  List<String> _images = [];
  
  int _currentImageIndex = 0;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    _prepareTrailer();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    super.dispose();
  }

  Future<void> _prepareTrailer() async {
    // 1. Fetch persona and images in parallel
    final results = await Future.wait([
      widget.traits.isNotEmpty 
          ? GeminiService().generateTravelPersona(widget.traits)
          : Future.value({
              'persona_name': 'The Discerning Traveller', 
              'tagline': 'A masterpiece itinerary crafted just for you.'
            }),
      UnsplashService().getDestinationImageUrls(widget.destination, count: 4),
    ]);

    final personaData = results[0] as Map<String, String>;
    final imageUrls = results[1] as List<String>;

    if (!mounted) return;

    setState(() {
      _personaName = personaData['persona_name'] ?? 'The Global Wanderer';
      _personaTagline = personaData['tagline'] ?? '';
      _images = imageUrls;
      _isLoading = false;
    });

    // Start Ken Burns loop
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % _images.length;
      });
    });
  }

  void _navigateToItinerary() {
    _carouselTimer?.cancel();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) => ItineraryResultScreen(
          destination: widget.destination,
          days: widget.days,
          tier: widget.tier,
          itinerary: widget.itinerary,
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ken Burns Background Images
          ...List.generate(_images.length, (index) {
            final isActive = index == _currentImageIndex;
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 1500),
              opacity: isActive ? 1.0 : 0.0,
              child: AnimatedScale(
                duration: const Duration(seconds: 6),
                scale: isActive ? 1.1 : 1.0,
                curve: Curves.linear,
                child: CachedNetworkImage(
                  imageUrl: _images[index],
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: AppTheme.surfaceDark),
                ),
              ),
            );
          }),

          // 2. Gradient Overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.8),
                  Colors.black,
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),

          // 3. The Trailer Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),

                  // Destination Reveal
                  Text(
                    "DESTINATION SECURED",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.accentAmber.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4.0,
                    ),
                  ).animate().fadeIn(duration: 800.ms, delay: 500.ms),

                  const SizedBox(height: 12),

                  Text(
                    widget.destination.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                      height: 1.1,
                    ),
                  ).animate().fadeIn(duration: 1000.ms, delay: 800.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

                  const Spacer(),

                  // Persona Reveal
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentAmber.withValues(alpha: 0.05),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(LucideIcons.sparkles, color: AppTheme.accentAmber, size: 28)
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2.seconds),
                        const SizedBox(height: 16),
                        Text(
                          "YOUR TRAVEL PERSONA",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ShaderMask(
                          shaderCallback: (bounds) => AppTheme.auroraGradient.createShader(bounds),
                          child: Text(
                            _personaName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _personaTagline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatValue(widget.days.toString(), "DAYS"),
                            _buildDivider(),
                            _buildStatValue(widget.tier.split(' ').first, "TIER"),
                            _buildDivider(),
                            _buildStatValue(widget.itinerary.length.toString(), "EVENTS"),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 1200.ms, delay: 2500.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),

                  const SizedBox(height: 48),

                  // Action Button
                  GestureDetector(
                    onTap: _navigateToItinerary,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: AppTheme.amberGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentAmber.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'View My Itinerary',
                            style: TextStyle(
                              color: AppTheme.primaryBlack,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(LucideIcons.arrowRight, color: AppTheme.primaryBlack, size: 20),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 800.ms, delay: 4000.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatValue(String value, String label) {
    return Column(
      children: [
        Text(
          value.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withValues(alpha: 0.2),
      margin: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.accentAmber),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) => AppTheme.auroraGradient.createShader(bounds),
              child: const Text(
                "Analyzing your vibes...",
                style: TextStyle(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 1.seconds),
          ],
        ),
      ),
    );
  }
}
