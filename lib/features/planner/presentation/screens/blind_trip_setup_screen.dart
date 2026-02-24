import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../../core/services/gemini_service.dart';
import 'blind_trip_countdown_screen.dart';

class BlindTripSetupScreen extends StatefulWidget {
  const BlindTripSetupScreen({super.key});

  @override
  State<BlindTripSetupScreen> createState() => _BlindTripSetupScreenState();
}

class _BlindTripSetupScreenState extends State<BlindTripSetupScreen> {
  double _budget = 2000;
  int _duration = 5;
  String? _selectedVibe;
  bool _isGenerating = false;

  final List<Map<String, String>> _vibes = [
    {'label': 'Neon Lights', 'emoji': '🌃'},
    {'label': 'Silent Mountains', 'emoji': '🏔️'},
    {'label': 'Hidden Beaches', 'emoji': '🏖️'},
    {'label': 'Historic Charm', 'emoji': '🏛️'},
    {'label': 'Total Chaos', 'emoji': '🔥'},
  ];

  void _lockInTrip() async {
    if (_selectedVibe == null) return;
    setState(() => _isGenerating = true);
    
    try {
      final jsonResponse = await GeminiService().generateBlindTripItinerary(
        budget: _budget,
        days: _duration,
        vibe: _selectedVibe!,
      );

      if (!mounted) return;
      setState(() => _isGenerating = false);

      Navigator.pushReplacement(context, PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => BlindTripCountdownScreen(generatedJson: jsonResponse),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ));
    } catch (e) {
      if (mounted) setState(() => _isGenerating = false);
      // Ignore error for now, maybe show snackbar if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: SafeArea(
          child: Stack(
            children: [
              _buildMainContent(),
              if (_isGenerating) _buildGeneratingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSuspenseIntro(),
                const SizedBox(height: 48),
                _buildBudgetSlider(),
                const SizedBox(height: 40),
                _buildDurationSlider(),
                const SizedBox(height: 40),
                _buildVibeSelection(),
                const SizedBox(height: 100), // padding for bottom button
              ],
            ),
          ),
        ),
        _buildBottomButton(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary, size: 18),
            ),
          ),
          ShaderMask(
            shaderCallback: (b) => AppTheme.auroraGradient.createShader(b),
            child: const Text('BLIND TRIP ROULETTE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.5)),
          ),
          const SizedBox(width: 38), // balance
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildSuspenseIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Trust the Unknown.",
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1, height: 1.1),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 12),
        Text(
          "Set your limits. Pick a vibe. We book it. You won't know where you're going until 24 hours before your flight.",
          style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.8), fontSize: 15, height: 1.5),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildBudgetSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Max Budget", style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            Text("\$${_budget.toInt()}", style: const TextStyle(color: AppTheme.accentAmber, fontSize: 22, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppTheme.accentAmber,
            inactiveTrackColor: Colors.white.withOpacity(0.1),
            thumbColor: AppTheme.accentAmber,
            trackHeight: 6,
          ),
          child: Slider(
            value: _budget,
            min: 500,
            max: 10000,
            divisions: 95,
            onChanged: (val) => setState(() => _budget = val),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildDurationSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Duration", style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            Text("$_duration Days", style: const TextStyle(color: AppTheme.accentAmber, fontSize: 22, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppTheme.accentTeal,
            inactiveTrackColor: Colors.white.withOpacity(0.1),
            thumbColor: AppTheme.accentTeal,
            trackHeight: 6,
          ),
          child: Slider(
            value: _duration.toDouble(),
            min: 2,
            max: 14,
            divisions: 12,
            onChanged: (val) => setState(() => _duration = val.toInt()),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildVibeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("The Vibe", style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _vibes.map((v) {
            final isSelected = _selectedVibe == v['label'];
            return GestureDetector(
              onTap: () => setState(() => _selectedVibe = v['label']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.accentViolet.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppTheme.accentViolet : Colors.transparent),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(v['emoji']!, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(v['label']!, style: TextStyle(
                      color: isSelected ? AppTheme.accentViolet : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildBottomButton() {
    final canProceed = _selectedVibe != null && !_isGenerating;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: GestureDetector(
        onTap: canProceed ? _lockInTrip : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: canProceed ? const LinearGradient(colors: [Colors.redAccent, Colors.deepOrange]) : null,
            color: canProceed ? null : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            boxShadow: canProceed ? [BoxShadow(color: Colors.redAccent.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 5))] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.lock, color: canProceed ? Colors.white : AppTheme.textSecondary, size: 18),
              const SizedBox(width: 8),
              Text("LOCK IN MYSTERY TRIP", style: TextStyle(color: canProceed ? Colors.white : AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, delay: 700.ms);
  }

  Widget _buildGeneratingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.redAccent),
            const SizedBox(height: 24),
            Text("Encrypting Destination...", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    ).animate().fadeIn();
  }
}
