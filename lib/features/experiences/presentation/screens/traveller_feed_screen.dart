import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../audio_guide/presentation/screens/audio_guide_player.dart';
import '../../../../core/services/places_service.dart';

class TravellerFeedScreen extends StatefulWidget {
  const TravellerFeedScreen({super.key});

  @override
  State<TravellerFeedScreen> createState() => _TravellerFeedScreenState();
}

class _TravellerFeedScreenState extends State<TravellerFeedScreen> {
  final PlacesService _placesService = PlacesService();
  late Future<List<Map<String, dynamic>>> _feedFuture;
  
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Trending', 'Near You', 'Hidden Gems', 'User Picks'];

  final List<Map<String, dynamic>> _feedItems = [
    {
      'title': 'Midnight in Montmartre',
      'location': 'Paris, France',
      'creator': '@ElenaWanders',
      'image': 'https://images.unsplash.com/photo-1511739001486-6bfe10ce785f?q=80&w=800',
      'isHero': true,
      'script': 'The streets of Montmartre at midnight are completely silent, save for the distant sound of a saxophone...',
    },
    {
      'title': 'Dawn at the Caldera',
      'location': 'Santorini, Greece',
      'creator': '@MarcusTrips',
      'image': 'https://images.unsplash.com/photo-1533105079780-92b9be482077?q=80&w=600',
      'isHero': false,
      'script': 'Waking up before the sun here isn\'t a chore, it\'s a privilege. The white walls turn soft pink...',
    },
    {
      'title': 'Lost in the Medina',
      'location': 'Marrakech, Morocco',
      'creator': '@SaharaSoul',
      'image': 'https://images.unsplash.com/photo-1539020140153-e479b8b47c53?q=80&w=600',
      'isHero': false,
      'script': 'Spices, silk, and shadows. The Medina is a labyrinth designed to make you forget time...',
    },
    {
      'title': 'Neon Rain',
      'location': 'Tokyo, Japan',
      'creator': '@CyberNomad',
      'image': 'https://images.unsplash.com/photo-1519501025264-65ba15a82390?q=80&w=800',
      'isHero': true,
      'script': 'When it rains in Shinjuku, the city becomes a mirror. Neon lights bleed into the asphalt...',
    },
    {
      'title': 'Glacier Silence',
      'location': 'Vatnajökull, Iceland',
      'creator': '@FrostWalker',
      'image': 'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?q=80&w=600',
      'isHero': false,
      'script': 'The ancient ice groans. It is the only sound in this frozen cathedral...',
    },
  ];

  @override
  void initState() {
    super.initState();
    _feedFuture = _fetchRealFeed();
  }

  Future<List<Map<String, dynamic>>> _fetchRealFeed() async {
    final List<Map<String, dynamic>> results = [];
    for (var item in _feedItems) {
      String imageUrl = item['image']; // Default to fallback
      try {
        final query = '${item['title']} ${item['location']}';
        final places = await _placesService.searchPlaces(query);
        if (places.isNotEmpty && places.first.photoReference != null) {
          imageUrl = _placesService.getPhotoUrl(places.first.photoReference!, maxWidth: 800);
        }
      } catch (_) {}
      
      results.add({...item, 'image': imageUrl});
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildFilters(),
              Expanded(child: _buildFeed()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle),
              child: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          const Text('Traveller Feed', style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle),
            child: const Icon(LucideIcons.search, color: AppTheme.textSecondary, size: 18),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        itemBuilder: (ctx, i) {
          final filter = _filters[i];
          final isSelected = filter == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? AppTheme.accentAmber : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? AppTheme.accentAmber : AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildFeed() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _feedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accentAmber),
          );
        }
        
        final items = snapshot.data ?? _feedItems;
        
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          physics: const BouncingScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final item = items[i];
            if (item['isHero'] == true) {
              return _buildHeroCard(item).animate().fadeIn(delay: Duration(milliseconds: 100 * i)).slideY(begin: 0.1, end: 0);
            } else {
              return _buildStandardCard(item).animate().fadeIn(delay: Duration(milliseconds: 100 * i)).slideY(begin: 0.1, end: 0);
            }
          },
        );
      },
    );
  }

  Widget _buildHeroCard(Map<String, dynamic> item) {
    return Container(
      height: 340,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(image: NetworkImage(item['image']), fit: BoxFit.cover),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                stops: const [0.4, 1.0],
                colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
              ),
            ),
          ),
          Positioned(
            bottom: 20, left: 20, right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, color: AppTheme.accentAmber, size: 14),
                    const SizedBox(width: 6),
                    Text(item['location'], style: const TextStyle(color: AppTheme.accentAmber, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(item['title'], style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.1)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['creator'], style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                    _buildPlayButton(item),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardCard(Map<String, dynamic> item) {
    // standard horizontal card
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.glassCardDecoration(borderRadius: 20),
      child: Row(
        children: [
          Container(
            width: 110,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              image: DecorationImage(image: NetworkImage(item['image']), fit: BoxFit.cover),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item['location'], style: const TextStyle(color: AppTheme.accentTeal, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(item['title'], maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700, height: 1.2)),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item['creator'], style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7), fontSize: 12)),
                      _buildPlayButton(item, small: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton(Map<String, dynamic> item, {bool small = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => AudioGuidePlayer(
          placeName: item['location'],
          customScript: item['script'],
        )));
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: small ? 10 : 16, vertical: small ? 6 : 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.play, color: Colors.white, size: small ? 14 : 16),
            SizedBox(width: small ? 4 : 8),
            Text('Listen', style: TextStyle(color: Colors.white, fontSize: small ? 11 : 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
