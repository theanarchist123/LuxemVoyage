import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/places_service.dart';
import '../../../../core/services/weather_service.dart';
import '../../../place_detail/presentation/screens/place_detail_screen.dart';
import '../../../../features/planner/presentation/screens/mood_board_screen.dart';
import '../../../../features/planner/presentation/screens/trip_planner_screen.dart';
import '../../../../features/experiences/presentation/screens/traveller_feed_screen.dart';
import '../../../../features/collections/presentation/screens/collections_screen.dart';
import '../../../../features/costs/presentation/screens/cost_diary_screen.dart';
import '../../../../features/map/presentation/screens/map_screen.dart';
import '../../../../features/audio_guide/presentation/screens/audio_guide_player.dart';
import '../../../../features/planner/presentation/screens/blind_trip_setup_screen.dart';
import '../../../../features/planner/presentation/screens/swipe_match_screen.dart';
import '../../../../features/planner/presentation/screens/trip_journal_screen.dart';
import '../../../../features/gamification/presentation/screens/digital_passport_screen.dart';

// ─── Fallback curated experiences ────────────────────────────────────────────
const List<Map<String, String>> _fallbackExperiences = [
  {'name': 'Santorini Suites', 'location': 'Santorini, Greece', 'rating': '4.9', 'price': '\$\$\$', 'image': 'https://images.unsplash.com/photo-1533105079780-92b9be482077?q=80&w=600&auto=format&fit=crop'},
  {'name': 'Maldives Villa', 'location': 'Maldives', 'rating': '5.0', 'price': '\$\$\$\$', 'image': 'https://images.unsplash.com/photo-1573843981267-be1999ff37cd?q=80&w=600&auto=format&fit=crop'},
  {'name': 'Amalfi Resort', 'location': 'Amalfi Coast, Italy', 'rating': '4.8', 'price': '\$\$\$', 'image': 'https://images.unsplash.com/photo-1612698093158-e07ac200d44e?q=80&w=600&auto=format&fit=crop'},
  {'name': 'Kyoto Ryokan', 'location': 'Kyoto, Japan', 'rating': '4.9', 'price': '\$\$\$', 'image': 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?q=80&w=600&auto=format&fit=crop'},
  {'name': 'Swiss Chalet', 'location': 'Zermatt, Switzerland', 'rating': '4.7', 'price': '\$\$\$\$', 'image': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?q=80&w=600&auto=format&fit=crop'},
];

// Hero background images
final List<Map<String, String>> _heroImages = [
  {'image': 'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?q=80&w=900&auto=format&fit=crop'},
  {'image': 'https://images.unsplash.com/photo-1501785888041-af3ef285b470?q=80&w=900&auto=format&fit=crop'},
  {'image': 'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?q=80&w=900&auto=format&fit=crop'},
];

// Quick-action chips with their search queries for Places API
const List<Map<String, dynamic>> _quickActions = [
  {'label': 'Flights', 'icon': LucideIcons.planeTakeoff, 'query': 'flight airport'},
  {'label': 'Hotels', 'icon': LucideIcons.hotel, 'query': 'luxury hotel'},
  {'label': 'Packages', 'icon': LucideIcons.package, 'query': 'travel packages tours'},
  {'label': 'Experiences', 'icon': LucideIcons.star, 'query': 'tourist attractions'},
  {'label': 'Guides', 'icon': LucideIcons.bookOpen, 'query': 'audio guide tours'},
];

// Trending destination queries — fetched from Places API
const List<Map<String, String>> _trendingQueries = [
  {'name': 'Tokyo', 'subtitle': 'Japan', 'tag': 'Culture', 'query': 'tourist attractions Tokyo Japan', 'fallback': 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?q=80&w=400&auto=format&fit=crop'},
  {'name': 'Dubai', 'subtitle': 'UAE', 'tag': 'Luxury', 'query': 'luxury experiences Dubai UAE', 'fallback': 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?q=80&w=400&auto=format&fit=crop'},
  {'name': 'Bali', 'subtitle': 'Indonesia', 'tag': 'Retreat', 'query': 'resort retreat Bali Indonesia', 'fallback': 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?q=80&w=400&auto=format&fit=crop'},
  {'name': 'Iceland', 'subtitle': 'Europe', 'tag': 'Adventure', 'query': 'adventure tours Iceland', 'fallback': 'https://images.unsplash.com/photo-1504829857797-ddff29c27927?q=80&w=400&auto=format&fit=crop'},
];

// ─── Main widget ──────────────────────────────────────────────────────────────

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({Key? key}) : super(key: key);

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final PlacesService _placesService = PlacesService();
  final WeatherService _weatherService = WeatherService();

  late Future<List<PlaceData>> _curatedExperiencesFuture;
  late Future<WeatherData?> _weatherFuture;

  // Trending: resolved as a list of {name, subtitle, tag, imageUrl}
  late Future<List<Map<String, String>>> _trendingFuture;

  int _heroIndex = 0;
  Timer? _heroTimer;

  // Search
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _curatedExperiencesFuture = _placesService.searchPlaces('luxury hotel resort');
    _weatherFuture = _weatherService.getWeather();
    _trendingFuture = _fetchTrendingDestinations();

    // Auto-advance hero every 4s
    _heroTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        setState(() => _heroIndex = (_heroIndex + 1) % _heroImages.length);
      }
    });
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Fetch a representative photo for each trending destination via Places API.
  Future<List<Map<String, String>>> _fetchTrendingDestinations() async {
    final List<Map<String, String>> results = [];
    for (final item in _trendingQueries) {
      String imageUrl = item['fallback']!;
      try {
        final places = await _placesService.searchPlaces(item['query']!);
        if (places.isNotEmpty && places.first.photoReference != null) {
          imageUrl = _placesService.getPhotoUrl(places.first.photoReference!, maxWidth: 600);
        }
      } catch (_) {
        // keep fallback
      }
      results.add({
        'name': item['name']!,
        'subtitle': item['subtitle']!,
        'tag': item['tag']!,
        'imageUrl': imageUrl,
        'query': item['query']!,
      });
    }
    return results;
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning ☀️';
    if (h < 17) return 'Good Afternoon 🌤';
    return 'Good Evening 🌙';
  }

  void _onQuickAction(Map<String, dynamic> action) {
    final label = action['label'] as String;
    final query = action['query'] as String;

    switch (label) {
      case 'Guides':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AudioGuidePlayer()));
        break;
      case 'Packages':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TripPlannerScreen()));
        break;
      default:
        // Flights, Hotels, Experiences → open Map with pre-filled search
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
        break;
    }
  }

  void _onSearch(String query) {
    if (query.trim().isEmpty) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeroSection()),
            SliverToBoxAdapter(child: const SizedBox(height: 32)),
            SliverToBoxAdapter(child: _buildSectionHeader('The AI Suite', LucideIcons.sparkles)),
            SliverToBoxAdapter(child: const SizedBox(height: 16)),
            SliverToBoxAdapter(child: _buildFeaturedInnovationsCarousel()),
            SliverToBoxAdapter(child: const SizedBox(height: 36)),
            SliverToBoxAdapter(child: _buildSectionHeader('Travel Toolkit', LucideIcons.briefcase)),
            SliverToBoxAdapter(child: const SizedBox(height: 16)),
            SliverToBoxAdapter(child: _buildToolkitGrid()),
            SliverToBoxAdapter(child: const SizedBox(height: 36)),
            SliverToBoxAdapter(child: _buildQuickActions()),
            SliverToBoxAdapter(child: const SizedBox(height: 36)),
            SliverToBoxAdapter(child: _buildSectionHeader('Curated Experiences', LucideIcons.compass, onSeeAll: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TravellerFeedScreen()));
            })),
            SliverToBoxAdapter(child: const SizedBox(height: 16)),
            SliverToBoxAdapter(child: _buildExperiencesList()),
            SliverToBoxAdapter(child: const SizedBox(height: 36)),
            SliverToBoxAdapter(child: _buildSectionHeader('Trending Destinations', LucideIcons.trendingUp, onSeeAll: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
            })),
            SliverToBoxAdapter(child: const SizedBox(height: 16)),
            SliverToBoxAdapter(child: _buildTrendingSection()),
            SliverToBoxAdapter(child: const SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  // ─── Hero Section ────────────────────────────────────────────────────────────
  Widget _buildHeroSection() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? user.displayName!.split(' ').first
        : 'Traveller';
    final photoUrl = user?.photoURL;
    final heroUrl = _heroImages[_heroIndex]['image']!;

    return Stack(
      children: [
        // Hero image
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            child: SizedBox(
              key: ValueKey(heroUrl),
              height: 310,
              width: double.infinity,
              child: Image.network(heroUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: AppTheme.surfaceDark)),
            ),
          ),
        ),

        // Gradient overlay
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          child: SizedBox(
            height: 310,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.35, 0.7, 1.0],
                  colors: [
                    AppTheme.primaryBlack.withOpacity(0.72),
                    AppTheme.primaryBlack.withOpacity(0.28),
                    AppTheme.primaryBlack.withOpacity(0.55),
                    AppTheme.primaryBlack.withOpacity(0.97),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Top bar: greeting + avatar
        Positioned(
          top: 18, left: 22, right: 22,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_getGreeting(),
                      style: TextStyle(fontSize: 13, color: AppTheme.textPrimary.withOpacity(0.75), fontWeight: FontWeight.w500)),
                    const SizedBox(height: 3),
                    Row(children: [
                      Text(displayName,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(gradient: AppTheme.amberGradient, borderRadius: BorderRadius.circular(7)),
                        child: const Text('PRO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.primaryBlack, letterSpacing: 1.2)),
                      ),
                    ]),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectionsScreen()));
                },
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.auroraGradient),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryBlack),
                    child: CircleAvatar(
                      radius: 21,
                      backgroundColor: AppTheme.surfaceDark,
                      backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null || photoUrl.isEmpty
                          ? const Icon(LucideIcons.user, color: AppTheme.accentAmber, size: 20)
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.06, end: 0),
        ),

        // Tagline
        Positioned(
          top: 110, left: 22, right: 22,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (b) => AppTheme.auroraGradient.createShader(b),
                child: const Text('Where to next?',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.0, height: 1.1)),
              ),
              const SizedBox(height: 6),
              Text('Discover world-class destinations',
                style: TextStyle(fontSize: 14, color: AppTheme.textPrimary.withOpacity(0.7), fontWeight: FontWeight.w400)),
            ],
          ).animate().fadeIn(delay: 150.ms, duration: 600.ms).slideY(begin: 0.06, end: 0),
        ),

        // Dot indicators (tappable)
        Positioned(
          top: 215, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_heroImages.length, (i) {
              return GestureDetector(
                onTap: () => setState(() => _heroIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _heroIndex == i ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _heroIndex == i ? AppTheme.accentAmber : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ),

        // Glass search bar
        Positioned(
          bottom: 0, left: 18, right: 18,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Show the search sheet
                  _showSearchSheet();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.search, color: AppTheme.accentAmber, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Search destinations, hotels…',
                          style: TextStyle(color: AppTheme.textPrimary.withOpacity(0.55), fontSize: 14)),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const TripPlannerScreen()));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppTheme.accentAmber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.slidersHorizontal, color: AppTheme.accentAmber, size: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.08, end: 0),
        ),
      ],
    );
  }

  void _showSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SearchSheet(onSearch: (q) {
        Navigator.pop(context);
        _onSearch(q);
      }),
    );
  }

  // ─── Quick-action chips ──────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _quickActions.length,
        itemBuilder: (ctx, i) {
          final item = _quickActions[i];
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () => _onQuickAction(item),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.07)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Icon(item['icon'] as IconData, color: AppTheme.accentAmber, size: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(item['label'] as String,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 60 * i)).slideY(begin: 0.08, end: 0);
        },
      ),
    );
  }


  // ─── Section Header ──────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        ShaderMask(
          shaderCallback: (b) => AppTheme.auroraGradient.createShader(b),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Text(title,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        const Spacer(),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text('See all',
              style: TextStyle(color: AppTheme.accentAmber.withOpacity(0.85), fontSize: 13, fontWeight: FontWeight.w600)),
          ),
      ]),
    ).animate().fadeIn(delay: 200.ms);
  }

  // ─── Curated experiences horizontal scroll ───────────────────────────────────
  Widget _buildExperiencesList() {
    return SizedBox(
      height: 270,
      child: FutureBuilder<List<PlaceData>>(
        future: _curatedExperiencesFuture,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.accentAmber, strokeWidth: 2));
          }
          List<Map<String, dynamic>> cards;
          if (snap.hasData && snap.data!.isNotEmpty) {
            cards = snap.data!.take(5).map((p) => <String, dynamic>{
              'name': p.name, 'location': p.location, 'rating': p.rating.toString(),
              'price': '\$\$\$',
              'image': p.photoReference != null
                  ? PlacesService().getPhotoUrl(p.photoReference!)
                  : _fallbackExperiences[0]['image']!,
            }).toList();
          } else {
            cards = _fallbackExperiences.map((e) => <String, dynamic>{...e}).toList();
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: cards.length,
            itemBuilder: (ctx, i) => _ExperienceCard(
              imageUrl: cards[i]['image']!,
              name: cards[i]['name']!,
              location: cards[i]['location']!,
              rating: cards[i]['rating']!,
              price: cards[i]['price']!,
            ).animate().fadeIn(delay: Duration(milliseconds: 70 * i)).slideX(begin: 0.06, end: 0),
          );
        },
      ),
    );
  }

  // ─── Trending (real Places API photos) ──────────────────────────────────────
  Widget _buildTrendingSection() {
    return SizedBox(
      height: 200,
      child: FutureBuilder<List<Map<String, String>>>(
        future: _trendingFuture,
        builder: (ctx, snap) {
          final tagColors = [AppTheme.accentAmber, AppTheme.accentTeal, AppTheme.accentViolet, AppTheme.accentAmber];

          // While loading, show skeleton shimmer cards using fallbacks
          final items = snap.data ??
              _trendingQueries.map((t) => {'name': t['name']!, 'subtitle': t['subtitle']!, 'tag': t['tag']!, 'imageUrl': t['fallback']!, 'query': t['query']!}).toList();

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final t = items[i];
              return GestureDetector(
                onTap: () {
                  // Navigate to PlaceDetailScreen with the city info
                  Navigator.push(context, PageRouteBuilder(
                    pageBuilder: (_, __, ___) => PlaceDetailScreen(
                      name: t['name']!,
                      location: t['subtitle']!,
                      imageUrl: t['imageUrl']!,
                      rating: '4.8',
                    ),
                    transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
                  ));
                },
                child: Container(
                  width: 155,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 8))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(t['imageUrl']!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: AppTheme.surfaceDark)),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft, end: Alignment.bottomCenter,
                              stops: const [0.1, 1.0],
                              colors: [Colors.transparent, AppTheme.primaryBlack.withOpacity(0.9)],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12, left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: tagColors[i % tagColors.length].withOpacity(0.92),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(t['tag']!,
                              style: const TextStyle(color: AppTheme.primaryBlack, fontSize: 10, fontWeight: FontWeight.w800)),
                          ),
                        ),
                        Positioned(
                          bottom: 14, left: 14, right: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t['name']!,
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                              const SizedBox(height: 2),
                              Row(children: [
                                Icon(LucideIcons.mapPin, color: AppTheme.accentAmber.withOpacity(0.8), size: 11),
                                const SizedBox(width: 3),
                                Text(t['subtitle']!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 80 * i)).scale(begin: const Offset(0.95, 0.95));
            },
          );
        },
      ),
    );
  }

  // ─── The AI Suite (Premium Glassmorphic Stack layout) ────────────────────────
  Widget _buildFeaturedInnovationsCarousel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Top Row: Two Squares
          Row(
            children: [
              Expanded(
                child: _buildGlassFeatureCard(
                  title: 'Swipe Match',
                  subtitle: 'Vibe & travel.',
                  icon: LucideIcons.layers,
                  gradient: const RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.5,
                    colors: [Color(0xFFDD2476), Color(0xFFFF512F)],
                  ),
                  height: 160,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TravelSwipeMatchScreen())),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildGlassFeatureCard(
                  title: 'Blind Trip',
                  subtitle: 'Take a risk.',
                  icon: LucideIcons.dices,
                  gradient: const RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.5,
                    colors: [Color(0xFF8B0000), Color(0xFF4B0082)],
                  ),
                  height: 160,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlindTripSetupScreen())),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Bottom Row: One wide rectangle + one tall one
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildGlassFeatureCard(
                  title: 'AI Trip Journal',
                  subtitle: 'Weave your memories.',
                  icon: LucideIcons.feather,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF3A1C71), Color(0xFFD76D77), Color(0xFFFFAF7B)],
                  ),
                  height: 140,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TripJournalScreen())),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: _buildGlassFeatureCard(
                  title: 'Passport',
                  subtitle: 'Haptic stamps.',
                  icon: LucideIcons.fingerprint,
                  gradient: const LinearGradient(
                    begin: Alignment.bottomLeft, end: Alignment.topRight,
                    colors: [Color(0xFF141E30), Color(0xFF243B55)],
                  ),
                  height: 140,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DigitalPassportScreen())),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required double height,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Massive background icon for texture
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(icon, size: 100, color: Colors.white.withOpacity(0.08)),
              ),
              // Glass noise/blur overlay
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.white.withOpacity(0.02),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Icon(icon, color: Colors.white, size: 22),
                        ),
                        Icon(LucideIcons.arrowUpRight, color: Colors.white.withOpacity(0.5), size: 18),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, 
                          maxLines: 1,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text(subtitle, 
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Quick Toolkit Grid (Magazine Layout) ────────────────────────────────────
  Widget _buildToolkitGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 5,
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen())),
                  child: FutureBuilder<WeatherData?>(
                    future: _weatherFuture,
                    builder: (ctx, snap) {
                      final w = snap.data;
                      return Container(
                        height: 105,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(w?.icon ?? '🌤️', style: const TextStyle(fontSize: 32)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    w != null ? '${w.tempC.round()}°C' : '—',
                                    style: const TextStyle(color: AppTheme.accentTeal, fontSize: 22, fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    w?.city ?? (snap.connectionState == ConnectionState.waiting ? 'Wait…' : 'None'),
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(width: 14),
              Expanded(
                flex: 4,
                child: _buildToolkitCard(
                  title: 'Cost Diary',
                  icon: LucideIcons.pieChart,
                  color: AppTheme.accentAmber,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CostDiaryScreen())),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildToolkitCard(
                  title: 'Feed',
                  icon: LucideIcons.headphones,
                  color: AppTheme.accentViolet,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TravellerFeedScreen())),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoodBoardScreen())),
                  child: Container(
                    height: 105,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.amberGradient,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [BoxShadow(color: AppTheme.accentAmber.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: AppTheme.primaryBlack, shape: BoxShape.circle),
                          child: const Icon(LucideIcons.sparkles, color: AppTheme.accentAmber, size: 16),
                        ),
                        const Spacer(),
                        const Text('Find Your Vibe', style: TextStyle(color: AppTheme.primaryBlack, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5)),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolkitCard({required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 105,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 18),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

// ─── Search bottom sheet ──────────────────────────────────────────────────────
class _SearchSheet extends StatefulWidget {
  final void Function(String query) onSearch;
  const _SearchSheet({required this.onSearch});

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final TextEditingController _ctrl = TextEditingController();

  final List<String> _suggestions = [
    'Luxury hotels in Paris', 'Beach resorts Maldives', 'Temples in Kyoto',
    'Hiking trails Switzerland', 'Safari Kenya', 'Street food Bangkok',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
            ),
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // drag handle
                Center(
                  child: Container(width: 36, height: 4,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 20),
                // Search input
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accentAmber.withOpacity(0.3)),
                  ),
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Where do you want to go?',
                      hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6)),
                      prefixIcon: const Icon(LucideIcons.search, color: AppTheme.accentAmber, size: 18),
                      suffixIcon: GestureDetector(
                        onTap: () => widget.onSearch(_ctrl.text),
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppTheme.amberGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.arrowRight, color: AppTheme.primaryBlack, size: 16),
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: widget.onSearch,
                  ),
                ),
                const SizedBox(height: 20),
                Text('Popular Searches', style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _suggestions.map((s) => GestureDetector(
                    onTap: () => widget.onSearch(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.trendingUp, color: AppTheme.accentAmber, size: 12),
                          const SizedBox(width: 6),
                          Text(s, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Experience Card ──────────────────────────────────────────────────────────
class _ExperienceCard extends StatelessWidget {
  final String imageUrl, name, location, rating, price;

  const _ExperienceCard({
    Key? key,
    required this.imageUrl,
    required this.name,
    required this.location,
    required this.rating,
    required this.price,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => PlaceDetailScreen(
            name: name, location: location, imageUrl: imageUrl, rating: rating,
          ),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        ),
      ),
      child: Container(
        width: 210,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.38), blurRadius: 22, offset: const Offset(0, 10))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(imageUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: AppTheme.surfaceDark,
                      child: const Icon(LucideIcons.image, color: AppTheme.accentAmber, size: 36))),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.32, 1.0],
                    colors: [Colors.transparent, Colors.transparent, AppTheme.primaryBlack.withOpacity(0.96)],
                  ),
                ),
              ),
              // Rating badge
              Positioned(
                top: 14, right: 14,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlack.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: AppTheme.accentAmber, size: 13),
                          const SizedBox(width: 3),
                          Text(rating, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16, left: 16, right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w800, height: 1.25, letterSpacing: -0.2)),
                    const SizedBox(height: 7),
                    Row(children: [
                      Icon(LucideIcons.mapPin, color: AppTheme.accentAmber.withOpacity(0.85), size: 11),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(location, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.accentAmber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(price, style: TextStyle(color: AppTheme.accentAmber.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
