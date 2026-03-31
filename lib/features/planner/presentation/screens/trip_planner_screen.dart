import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../../core/services/gemini_service.dart';
import 'itinerary_result_screen.dart';
import 'hype_trailer_screen.dart';

class TripPlannerScreen extends StatefulWidget {
  final String? preselectedDestination;
  final String? preselectedImageUrl;

  const TripPlannerScreen({super.key, this.preselectedDestination, this.preselectedImageUrl});

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen> {
  int _step = 0;
  String _selectedDestination = '';
  int _days = 5;
  int _selectedTier = 1;
  bool _isGenerating = false;

  final GeminiService _geminiService = GeminiService();

  final List<Map<String, String>> _destinations = [
    {'name': 'Paris, France', 'image': 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?q=80&w=400&auto=format&fit=crop', 'emoji': '🗼'},
    {'name': 'Maldives', 'image': 'https://images.unsplash.com/photo-1573843981267-be1999ff37cd?q=80&w=400&auto=format&fit=crop', 'emoji': '🏝️'},
    {'name': 'Santorini, Greece', 'image': 'https://images.unsplash.com/photo-1533105079780-92b9be482077?q=80&w=400&auto=format&fit=crop', 'emoji': '🏛️'},
    {'name': 'Kyoto, Japan', 'image': 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?q=80&w=400&auto=format&fit=crop', 'emoji': '⛩️'},
    {'name': 'Amalfi Coast, Italy', 'image': 'https://images.unsplash.com/photo-1612698093158-e07ac200d44e?q=80&w=400&auto=format&fit=crop', 'emoji': '🌊'},
    {'name': 'Bali, Indonesia', 'image': 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?q=80&w=400&auto=format&fit=crop', 'emoji': '🌴'},
    {'name': 'Dubai, UAE', 'image': 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?q=80&w=400&auto=format&fit=crop', 'emoji': '🏙️'},
    {'name': 'Machu Picchu, Peru', 'image': 'https://images.unsplash.com/photo-1526392060635-9d6019884377?q=80&w=400&auto=format&fit=crop', 'emoji': '🏔️'},
    {'name': 'Bora Bora, French Polynesia', 'image': 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?q=80&w=400&auto=format&fit=crop', 'emoji': '🛖'},
    {'name': 'Serengeti, Tanzania', 'image': 'https://images.unsplash.com/photo-1516426122078-c23e76319801?q=80&w=400&auto=format&fit=crop', 'emoji': '🦁'},
    {'name': 'New York City, USA', 'image': 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?q=80&w=400&auto=format&fit=crop', 'emoji': '🗽'},
    {'name': 'Rome, Italy', 'image': 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?q=80&w=400&auto=format&fit=crop', 'emoji': '🍕'},
    {'name': 'Cape Town, South Africa', 'image': 'https://images.unsplash.com/photo-1580060839134-75a5edca2e99?q=80&w=400&auto=format&fit=crop', 'emoji': '🐧'},
    {'name': 'Swiss Alps, Switzerland', 'image': 'https://images.unsplash.com/photo-1530122037265-a5f1f91d3b99?q=80&w=400&auto=format&fit=crop', 'emoji': '🎿'},
    {'name': 'Reykjavik, Iceland', 'image': 'https://images.unsplash.com/photo-1531366936337-7c912a4589a7?q=80&w=400&auto=format&fit=crop', 'emoji': '🌋'},
    {'name': 'Sydney, Australia', 'image': 'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?q=80&w=400&auto=format&fit=crop', 'emoji': '🦘'},
    {'name': 'Queenstown, New Zealand', 'image': 'https://images.unsplash.com/photo-1589802829985-817e51171b92?q=80&w=400&auto=format&fit=crop', 'emoji': '⛰️'},
    {'name': 'Marrakech, Morocco', 'image': 'https://images.unsplash.com/photo-1539020140153-e479b8b47c53?q=80&w=400&auto=format&fit=crop', 'emoji': '🐪'},
    {'name': 'Rio de Janeiro, Brazil', 'image': 'https://images.unsplash.com/photo-1483729558449-99ef09a8c325?q=80&w=400&auto=format&fit=crop', 'emoji': '💃'},
    {'name': 'London, UK', 'image': 'https://images.unsplash.com/photo-1513635269975-5969336ac521?q=80&w=400&auto=format&fit=crop', 'emoji': '💂'},
    {'name': 'Banff, Canada', 'image': 'https://images.unsplash.com/photo-1512273222628-4daea6e55abb?q=80&w=400&auto=format&fit=crop', 'emoji': '🌲'},
    {'name': 'Phuket, Thailand', 'image': 'https://images.unsplash.com/photo-1589394815804-964ce0fa5715?q=80&w=400&auto=format&fit=crop', 'emoji': '🐘'},
    {'name': 'Petra, Jordan', 'image': 'https://images.unsplash.com/photo-1579607629555-520336aabd1e?q=80&w=400&auto=format&fit=crop', 'emoji': '🏺'},
    {'name': 'Istanbul, Turkey', 'image': 'https://images.unsplash.com/photo-1524231757912-21f4fe3a08d2?q=80&w=400&auto=format&fit=crop', 'emoji': '🕌'},
    {'name': 'Cusco, Peru', 'image': 'https://images.unsplash.com/photo-1587595431973-160d0d94add1?q=80&w=400&auto=format&fit=crop', 'emoji': '🦙'},
    {'name': 'Prague, Czech Republic', 'image': 'https://images.unsplash.com/photo-1519677100203-a0e668c92439?q=80&w=400&auto=format&fit=crop', 'emoji': '🏰'},
    {'name': 'Venice, Italy', 'image': 'https://images.unsplash.com/photo-1514890547357-a9ee288728e0?q=80&w=400&auto=format&fit=crop', 'emoji': '🛶'},
    {'name': 'Havana, Cuba', 'image': 'https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=400&auto=format&fit=crop', 'emoji': '🚘'},
    {'name': 'Florence, Italy', 'image': 'https://images.unsplash.com/photo-1543429188-4e8c56fa2b0a?q=80&w=400&auto=format&fit=crop', 'emoji': '🎨'},
    {'name': 'Galapagos Islands', 'image': 'https://images.unsplash.com/photo-1563242060-e448bacc2cd9?q=80&w=400&auto=format&fit=crop', 'emoji': '🐢'}
  ];

  @override
  void initState() {
    super.initState();
    if (widget.preselectedDestination != null && widget.preselectedDestination!.isNotEmpty) {
      // Insert the AI-suggested destination at the beginning
      _destinations.insert(0, {
        'name': widget.preselectedDestination!,
        'image': widget.preselectedImageUrl ?? 'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?q=80&w=400&auto=format&fit=crop',
        'emoji': '✨',
      });
      _selectedDestination = widget.preselectedDestination!;
      _step = 1; // Skip destination selection and go straight to duration
    }
  }

  final List<Map<String, String>> _tiers = [
    {'name': 'Premium', 'desc': '4-star hotels · Group tours · Fine dining', 'icon': '⭐'},
    {'name': 'Elite Luxury', 'desc': '5-star resorts · Private guides · Michelin dining', 'icon': '💎'},
    {'name': 'Bespoke VIP', 'desc': 'Private jets · Exclusive access · Personal concierge', 'icon': '👑'},
  ];

  Future<void> _generateItinerary() async {
    if (_selectedDestination.isEmpty) _selectedDestination = _destinations[0]['name']!;
    setState(() => _isGenerating = true);

    try {
      final jsonStr = await _geminiService.generateItinerary(
        destination: _selectedDestination, days: _days, tier: _tiers[_selectedTier]['name']!,
      );
      final cleanedJson = jsonStr.replaceAll('```json', '').replaceAll('```', '').trim();
      final decoded = List<Map<String, dynamic>>.from(jsonDecode(cleanedJson));

      if (!mounted) return;
      setState(() => _isGenerating = false);

      Navigator.pushReplacement(context, PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => HypeTrailerScreen(
          destination: _selectedDestination, 
          days: _days,
          tier: _tiers[_selectedTier]['name']!, 
          itinerary: decoded,
          traits: const [],
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ItineraryResultScreen(
          destination: _selectedDestination, days: _days, tier: _tiers[_selectedTier]['name']!,
          itinerary: [{'day': 1, 'title': 'Error', 'desc': e.toString(), 'activities': const []}],
        ),
      ));
    }
  }

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
              const SizedBox(height: 16),
              _buildStepBar(),
              const SizedBox(height: 24),
              Expanded(child: _buildCurrentStep()),
              _buildBottomAction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Plan Your Escape",
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                ShaderMask(
                  shaderCallback: (bounds) => AppTheme.auroraGradient.createShader(bounds),
                  child: const Text("POWERED BY AI", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accentAmber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.2)),
            ),
            child: const Icon(LucideIcons.sparkles, color: AppTheme.accentAmber, size: 20),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildStepBar() {
    final labels = ['Where', 'Duration', 'Style'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: List.generate(5, (i) {
          if (i.isOdd) {
            // Connector line
            final half = i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: _step > half
                      ? AppTheme.amberGradient
                      : null,
                  color: _step > half ? null : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }
          final idx = i ~/ 2;
          final isActive = _step == idx;
          final isDone = _step > idx;
          return GestureDetector(
            onTap: isDone ? () => setState(() => _step = idx) : null,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isActive || isDone ? AppTheme.amberGradient : null,
                    color: isActive || isDone ? null : AppTheme.surfaceLight,
                    border: isActive ? null : Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(LucideIcons.check, color: AppTheme.primaryBlack, size: 14)
                        : Text('${idx + 1}', style: TextStyle(
                            color: isActive ? AppTheme.primaryBlack : AppTheme.textSecondary,
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(labels[idx], style: TextStyle(
                  color: isActive ? AppTheme.accentAmber : AppTheme.textSecondary.withValues(alpha: 0.6),
                  fontSize: 10, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                )),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0: return _buildDestinationStep();
      case 1: return _buildDurationStep();
      case 2: return _buildTierStep();
      default: return const SizedBox();
    }
  }

  Widget _buildDestinationStep() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85,
      ),
      itemCount: _destinations.length,
      itemBuilder: (ctx, i) {
        final d = _destinations[i];
        final selected = _selectedDestination == d['name'];
        return GestureDetector(
          onTap: () => setState(() => _selectedDestination = d['name']!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppTheme.accentAmber : Colors.transparent,
                width: selected ? 2 : 0,
              ),
              boxShadow: selected ? [BoxShadow(color: AppTheme.accentAmber.withValues(alpha: 0.2), blurRadius: 16)] : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(imageUrl: d['image']!, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(color: AppTheme.surfaceDark)),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        stops: const [0.3, 1.0],
                        colors: [Colors.transparent, AppTheme.primaryBlack.withValues(alpha: 0.9)],
                      ),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      top: 10, right: 10,
                      child: Container(
                        width: 26, height: 26,
                        decoration: const BoxDecoration(
                          gradient: AppTheme.amberGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.check, color: AppTheme.primaryBlack, size: 14),
                      ),
                    ),
                  Positioned(
                    bottom: 14, left: 14, right: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['emoji']!, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(d['name']!, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 50 * i)).scale(begin: const Offset(0.95, 0.95));
      },
    );
  }

  Widget _buildDurationStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("$_days",
              style: const TextStyle(color: AppTheme.accentAmber, fontSize: 80, fontWeight: FontWeight.w800, height: 1))
              .animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
          const Text("days", style: TextStyle(color: AppTheme.accentAmber, fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: 3)),
          const SizedBox(height: 8),
          Text("Select trip duration", style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.6), fontSize: 14)),
          const SizedBox(height: 48),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.accentAmber,
              inactiveTrackColor: AppTheme.surfaceLight,
              thumbColor: AppTheme.accentAmber,
              overlayColor: AppTheme.accentAmber.withValues(alpha: 0.1),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(value: _days.toDouble(), min: 2, max: 14, divisions: 12,
                onChanged: (v) => setState(() => _days = v.round())),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("2 days", style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.4), fontSize: 12)),
                Text("14 days", style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.4), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierStep() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemCount: _tiers.length,
      itemBuilder: (ctx, i) {
        final selected = _selectedTier == i;
        final colors = [
          [AppTheme.accentTeal, AppTheme.accentTeal.withValues(alpha: 0.1)],
          [AppTheme.accentAmber, AppTheme.accentAmber.withValues(alpha: 0.1)],
          [AppTheme.accentViolet, AppTheme.accentViolet.withValues(alpha: 0.1)],
        ];
        return GestureDetector(
          onTap: () => setState(() => _selectedTier = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: selected ? colors[i][1] : AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? colors[i][0] : Colors.white.withValues(alpha: 0.06),
                width: selected ? 2 : 1,
              ),
              boxShadow: selected ? [BoxShadow(color: colors[i][0].withValues(alpha: 0.15), blurRadius: 16)] : null,
            ),
            child: Row(
              children: [
                Text(_tiers[i]['icon']!, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_tiers[i]['name']!, style: TextStyle(
                          color: selected ? colors[i][0] : AppTheme.textPrimary,
                          fontWeight: FontWeight.w700, fontSize: 17)),
                      const SizedBox(height: 4),
                      Text(_tiers[i]['desc']!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                if (selected)
                  Icon(LucideIcons.checkCircle2, color: colors[i][0], size: 22),
              ],
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 100 * i));
      },
    );
  }

  Widget _buildBottomAction() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: _isGenerating
          ? Column(
              children: [
                const CircularProgressIndicator(color: AppTheme.accentAmber),
                const SizedBox(height: 14),
                ShaderMask(
                  shaderCallback: (bounds) => AppTheme.auroraGradient.createShader(bounds),
                  child: const Text("Crafting your bespoke journey...",
                      style: TextStyle(color: Colors.white, fontStyle: FontStyle.italic, fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ],
            )
          : GoldButton(
              text: _step < 2 ? "Continue" : "Generate Itinerary",
              icon: _step < 2 ? LucideIcons.arrowRight : LucideIcons.sparkles,
              onPressed: () {
                if (_step == 0 && _selectedDestination.isEmpty) _selectedDestination = _destinations[0]['name']!;
                if (_step < 2) { setState(() => _step++); } else { _generateItinerary(); }
              },
            ),
    );
  }
}
