import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/gemini_service.dart';

class MoodBoardScreen extends StatefulWidget {
  const MoodBoardScreen({Key? key}) : super(key: key);

  @override
  State<MoodBoardScreen> createState() => _MoodBoardScreenState();
}

class _MoodBoardScreenState extends State<MoodBoardScreen> {
  final Set<String> _selected = {};
  bool _isLoading = false;

  final List<Map<String, dynamic>> _moods = [
    {'label': 'Mountain Silence',    'emoji': '🏔️', 'color': const Color(0xFF334155), 'img': 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?q=60&w=300'},
    {'label': 'Turquoise Lagoons',   'emoji': '🌊', 'color': const Color(0xFF0E7490), 'img': 'https://images.unsplash.com/photo-1573843981267-be1999ff37cd?q=60&w=300'},
    {'label': 'Neon City Nights',    'emoji': '🌃', 'color': const Color(0xFF3730A3), 'img': 'https://images.unsplash.com/photo-1519501025264-65ba15a82390?q=60&w=300'},
    {'label': 'Ancient Temples',     'emoji': '⛩️', 'color': const Color(0xFF92400E), 'img': 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?q=60&w=300'},
    {'label': 'Vineyard Evenings',   'emoji': '🍷', 'color': const Color(0xFF7C3AED), 'img': 'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?q=60&w=300'},
    {'label': 'Desert Golden Hour',  'emoji': '🌅', 'color': const Color(0xFFB45309), 'img': 'https://images.unsplash.com/photo-1509316785289-025f5b846b35?q=60&w=300'},
    {'label': 'Cobblestone Europe',  'emoji': '🏛️', 'color': const Color(0xFF374151), 'img': 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?q=60&w=300'},
    {'label': 'Rainforest Zen',      'emoji': '🌿', 'color': const Color(0xFF065F46), 'img': 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?q=60&w=300'},
    {'label': 'Arctic Aurora',       'emoji': '🌌', 'color': const Color(0xFF1E3A5F), 'img': 'https://images.unsplash.com/photo-1531366936337-7c912a4589a7?q=60&w=300'},
    {'label': 'Island Hammocks',     'emoji': '🌴', 'color': const Color(0xFF0D6E45), 'img': 'https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?q=60&w=300'},
    {'label': 'Snow Safari',         'emoji': '❄️', 'color': const Color(0xFF1D4ED8), 'img': 'https://images.unsplash.com/photo-1483721310020-03333e577078?q=60&w=300'},
    {'label': 'Cherry Blossoms',     'emoji': '🌸', 'color': const Color(0xFFBE185D), 'img': 'https://images.unsplash.com/photo-1522383225653-ed111181a951?q=60&w=300'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSubtitle(),
              Expanded(child: _buildGrid()),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
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
          Expanded(
            child: Center(
              child: ShaderMask(
                shaderCallback: (b) => AppTheme.auroraGradient.createShader(b),
                child: const Text('FIND MY DESTINATION', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.5)),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildSubtitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pick your vibe',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text('Choose 3–5 aesthetics that speak to your soul',
              style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7), fontSize: 13)),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: _moods.length,
      itemBuilder: (_, i) => _buildMoodTile(_moods[i], i),
    );
  }

  Widget _buildMoodTile(Map<String, dynamic> mood, int index) {
    final isSelected = _selected.contains(mood['label']);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selected.remove(mood['label']);
          } else if (_selected.length < 5) {
            _selected.add(mood['label']);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppTheme.accentAmber : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.accentAmber.withOpacity(0.3), blurRadius: 12)]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(mood['img'] as String, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: mood['color'] as Color)),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, (mood['color'] as Color).withOpacity(0.85)],
                  ),
                ),
              ),
              if (isSelected)
                Container(color: AppTheme.accentAmber.withOpacity(0.15)),
              Positioned(
                top: 8, right: 8,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isSelected ? 1 : 0,
                  child: Container(
                    width: 22, height: 22,
                    decoration: const BoxDecoration(gradient: AppTheme.amberGradient, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.check, color: AppTheme.primaryBlack, size: 12),
                  ),
                ),
              ),
              Positioned(
                left: 8, bottom: 8, right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mood['emoji'] as String, style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 2),
                    Text(mood['label'] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, height: 1.2)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 40 * index)).scale(
        begin: const Offset(0.9, 0.9), end: const Offset(1, 1),
        delay: Duration(milliseconds: 40 * index));
  }

  Widget _buildBottomBar() {
    final enough = _selected.length >= 3;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          // Selection count
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _selected.isNotEmpty ? 1 : 0.4,
            child: Text(
              _selected.isEmpty ? 'Select at least 3 vibes' :
              _selected.length < 3 ? '${_selected.length} selected — pick ${3 - _selected.length} more' :
              '${_selected.length} vibes selected ✨',
              style: TextStyle(
                color: enough ? AppTheme.accentAmber : AppTheme.textSecondary,
                fontSize: 13, fontWeight: enough ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: enough && !_isLoading ? _findDestination : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 17),
              decoration: BoxDecoration(
                gradient: enough ? AppTheme.amberGradient : null,
                color: enough ? null : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                boxShadow: enough
                    ? [BoxShadow(color: AppTheme.accentAmber.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 5))]
                    : null,
              ),
              child: Center(
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: AppTheme.primaryBlack, strokeWidth: 2))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(LucideIcons.sparkles, color: enough ? AppTheme.primaryBlack : AppTheme.textSecondary, size: 16),
                        const SizedBox(width: 8),
                        Text('Find My Destination',
                            style: TextStyle(
                              color: enough ? AppTheme.primaryBlack : AppTheme.textSecondary,
                              fontSize: 15, fontWeight: FontWeight.w700,
                            )),
                      ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _findDestination() async {
    setState(() => _isLoading = true);
    try {
      final result = await GeminiService().matchDestinationFromMoods(_selected.toList());
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.push(context, PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => _DestinationRevealScreen(
          result: result,
          selectedMoods: _selected.toList(),
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ));
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ─── Destination Reveal Screen ──────────────────────────────────────────────

class _DestinationRevealScreen extends StatefulWidget {
  final Map<String, dynamic> result;
  final List<String> selectedMoods;

  const _DestinationRevealScreen({required this.result, required this.selectedMoods});

  @override
  State<_DestinationRevealScreen> createState() => _DestinationRevealScreenState();
}

class _DestinationRevealScreenState extends State<_DestinationRevealScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showDestination = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showDestination = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destination = widget.result['destination'] as String? ?? 'Santorini, Greece';
    final tagline = widget.result['tagline'] as String? ?? '';
    final why = widget.result['why'] as String? ?? '';
    final highlights = (widget.result['highlights'] as List?)?.cast<String>() ?? [];
    final imageUrl = _getImageUrl(destination);

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image (delayed reveal)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 800),
            opacity: _showDestination ? 1 : 0,
            child: Image.network(imageUrl, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: AppTheme.surfaceDark)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.3), AppTheme.primaryBlack.withOpacity(0.95)],
                stops: const [0.0, 0.75],
              ),
            ),
          ),

          // Aurora vortex (before reveal)
          if (!_showDestination)
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => Container(
                  width: 180 * _controller.value,
                  height: 180 * _controller.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(colors: [
                      AppTheme.accentTeal.withOpacity(0.7),
                      AppTheme.accentViolet.withOpacity(0.7),
                      AppTheme.accentAmber.withOpacity(0.7),
                      AppTheme.accentTeal.withOpacity(0.7),
                    ]),
                  ),
                ),
              ),
            ),

          SafeArea(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 600),
              opacity: _showDestination ? 1 : 0,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 40),
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    // "Your Match" pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Text('✨ Your Perfect Match',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ).animate(delay: 200.ms).fadeIn(),

                    const SizedBox(height: 24),

                    // Destination name — letter by letter
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(destination,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1, height: 1.1)),
                    ).animate(delay: 300.ms).fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Text(tagline, textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 16, fontStyle: FontStyle.italic, height: 1.5)),
                    ).animate(delay: 500.ms).fadeIn(),

                    const SizedBox(height: 40),

                    // Why card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.glassCardDecoration(borderRadius: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(LucideIcons.sparkles, color: AppTheme.accentAmber, size: 16),
                            const SizedBox(width: 8),
                            const Text('Why this destination?',
                                style: TextStyle(color: AppTheme.accentAmber, fontSize: 13, fontWeight: FontWeight.w700)),
                          ]),
                          const SizedBox(height: 12),
                          Text(why,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.7)),
                        ],
                      ),
                    ).animate(delay: 700.ms).fadeIn().slideY(begin: 0.05, end: 0),

                    const SizedBox(height: 16),

                    // Highlights
                    if (highlights.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Wrap(
                          spacing: 8, runSpacing: 8,
                          children: highlights.map((h) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.accentViolet.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.accentViolet.withOpacity(0.2)),
                            ),
                            child: Text(h, style: const TextStyle(color: AppTheme.accentViolet, fontSize: 13, fontWeight: FontWeight.w600)),
                          )).toList(),
                        ),
                      ).animate(delay: 900.ms).fadeIn(),

                    const SizedBox(height: 36),

                    // CTA
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: AppTheme.amberGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: AppTheme.accentAmber.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 5))],
                          ),
                          child: const Center(child: Text('Plan This Trip →',
                              style: TextStyle(color: AppTheme.primaryBlack, fontSize: 15, fontWeight: FontWeight.w700))),
                        ),
                      ),
                    ).animate(delay: 1100.ms).fadeIn().slideY(begin: 0.05, end: 0),

                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Try Different Moods', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ).animate(delay: 1200.ms).fadeIn(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getImageUrl(String destination) {
    final lower = destination.toLowerCase();
    if (lower.contains('paris')) return 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?q=80&w=1200';
    if (lower.contains('maldives') || lower.contains('lagoon')) return 'https://images.unsplash.com/photo-1573843981267-be1999ff37cd?q=80&w=1200';
    if (lower.contains('santorini') || lower.contains('greece')) return 'https://images.unsplash.com/photo-1533105079780-92b9be482077?q=80&w=1200';
    if (lower.contains('kyoto') || lower.contains('japan')) return 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?q=80&w=1200';
    if (lower.contains('bali') || lower.contains('indonesia')) return 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?q=80&w=1200';
    if (lower.contains('dubai')) return 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?q=80&w=1200';
    if (lower.contains('iceland') || lower.contains('aurora')) return 'https://images.unsplash.com/photo-1531366936337-7c912a4589a7?q=80&w=1200';
    if (lower.contains('morocco') || lower.contains('marrakech')) return 'https://images.unsplash.com/photo-1539020140153-e479b8b47c53?q=80&w=1200';
    return 'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?q=80&w=1200';
  }
}
