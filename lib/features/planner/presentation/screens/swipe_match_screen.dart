import 'dart:math' as math;
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/unsplash_service.dart';
import '../../../../core/services/gemini_service.dart';
import 'itinerary_result_screen.dart';

class TravelSwipeMatchScreen extends StatefulWidget {
  const TravelSwipeMatchScreen({super.key});

  @override
  State<TravelSwipeMatchScreen> createState() => _TravelSwipeMatchScreenState();
}

class _TravelSwipeMatchScreenState extends State<TravelSwipeMatchScreen> {
  final List<String> _matchedVibes = [];
  final int _targetMatches = 5;
  bool _isGenerating = false;

  // Static list of vibes to iterate through
  final List<Map<String, String>> _vibeDeck = [
    {'title': 'Rooftop Cocktails', 'query': 'luxury rooftop bar city night'},
    {'title': 'Hidden Beaches', 'query': 'secret pristine beach ocean'},
    {'title': 'Ancient Architecture', 'query': 'ancient ruins historical architecture'},
    {'title': 'Deep Sea Diving', 'query': 'scuba diving coral reef'},
    {'title': 'Aesthetic Cafes', 'query': 'aesthetic cozy cafe'},
    {'title': 'Street Food Tours', 'query': 'asian night market street food'},
    {'title': 'Snowy Cabins', 'query': 'cozy snow cabin winter'},
    {'title': 'Desert Safaris', 'query': 'desert sand dunes sunset'},
    {'title': 'High-End Shopping', 'query': 'luxury fashion shopping street'},
    {'title': 'Zen Retreats', 'query': 'zen garden meditation nature'},
    {'title': 'Neon Cityscapes', 'query': 'cyberpunk neon city street'},
    {'title': 'Wilderness Hiking', 'query': 'epic mountain hiking trail'},
    {'title': 'Art Museum Gazing', 'query': 'modern art museum gallery'},
    {'title': 'Jungle Canopy', 'query': 'tropical rainforest waterfall'},
    {'title': 'Vineyard Tastings', 'query': 'wine tasting vineyard sunset'},
  ];

  // We will load images dynamically into this list for the top cards
  List<Map<String, dynamic>> _loadedCards = [];
  int _deckIndex = 0;
  bool _isLoadingBatch = false;

  @override
  void initState() {
    super.initState();
    _vibeDeck.shuffle();
    _loadNextBatch();
  }

  Future<void> _loadNextBatch() async {
    if (_isLoadingBatch) return;
    _isLoadingBatch = true;

    // Load images for the next 3 cards to avoid massive API spam
    final nextBatch = _vibeDeck.skip(_deckIndex).take(3).toList();
    if (nextBatch.isEmpty) {
      _isLoadingBatch = false;
      return; // ran out of vibes
    }

    _deckIndex += nextBatch.length;

    for (var vibe in nextBatch) {
      final imgUrl = await UnsplashService().getDestinationImageUrl(vibe['query']!);
      if (mounted) {
        setState(() {
          // Double check to prevent any accidental duplicate key inserts
          if (!_loadedCards.any((c) => c['id'] == vibe['title'])) {
            _loadedCards.insert(0, { // Insert at 0 so the first item loaded is at the bottom of the stack
              'id': vibe['title'],
              'title': vibe['title'],
              'imageUrl': imgUrl!,
            });
          }
        });
      }
    }
    
    if (mounted) {
      setState(() => _isLoadingBatch = false);
    } else {
      _isLoadingBatch = false;
    }
  }

  void _onSwipe(bool isRightSwipe) async {
    if (_loadedCards.isEmpty) return;

    final topCard = _loadedCards.removeLast(); // The card currently on top
    
    if (isRightSwipe) {
      _matchedVibes.add(topCard['title']);
    }

    setState(() {}); // trigger rebuild to show next card
    _loadNextBatch(); // load more in background

    if (_matchedVibes.length >= _targetMatches) {
      _generateFinalItinerary();
    }
  }

  Future<void> _generateFinalItinerary() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    try {
      final jsonResponse = await GeminiService().generateItineraryFromMatches(_matchedVibes);
      
      if (!mounted) return;
      setState(() => _isGenerating = false);

      // Clean similar to Blind Trip
      final cleaned = jsonResponse.replaceAll('```json', '').replaceAll('```', '').trim();
      final data = jsonDecode(cleaned);

      final itinerary = (data['itinerary'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final dest = data['destination'] ?? 'Custom Match';

      Navigator.pushReplacement(context, PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) => ItineraryResultScreen(
          destination: dest,
          days: itinerary.length,
          tier: 'Curated VIP',
          itinerary: itinerary,
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ));

    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generation failed. Keep swiping!')));
        _matchedVibes.clear(); // reset on error
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.screenGradient)),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildProgressIndicator(),
                Expanded(
                  child: _isGenerating 
                      ? _buildGeneratingOverlay() 
                      : _buildCardStack(),
                ),
                if (!_isGenerating) _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle),
              child: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary, size: 18),
            ),
          ),
          ShaderMask(
            shaderCallback: (b) => AppTheme.auroraGradient.createShader(b),
            child: const Text('CURATE YOUR VIBE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.5)),
          ),
          const SizedBox(width: 38),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildProgressIndicator() {
    final progress = _matchedVibes.length / _targetMatches;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: Column(
        children: [
          Text("${_matchedVibes.length} / $_targetMatches Matches", style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentAmber),
              minHeight: 6,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildCardStack() {
    if (_loadedCards.isEmpty && _vibeDeck.isNotEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentTeal));
    }
    if (_loadedCards.isEmpty) {
      return const Center(child: Text("Out of vibes! Try resetting.", style: TextStyle(color: Colors.white)));
    }

    // Sanitize the list to guarantee absolute uniqueness (fixes hot reload memory artifacts)
    final List<Map<String, dynamic>> secureCards = [];
    final Set<String> seenIds = {};
    for (var card in _loadedCards) {
      if (!seenIds.contains(card['id'])) {
        secureCards.add(card);
        seenIds.add(card['id']);
      }
    }

    return Stack(
      alignment: Alignment.center,
      children: secureCards.map((card) {
        final isTopCard = card == secureCards.last;
        return _SwipeableCard(
          key: ValueKey(card['id']),
          cardData: card,
          isTopCard: isTopCard,
          onSwipe: _onSwipe,
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCircleButton(LucideIcons.x, Colors.redAccent, () => _onSwipe(false)),
          _buildCircleButton(LucideIcons.heart, AppTheme.accentTeal, () => _onSwipe(true)),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildCircleButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.5), width: 2),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Icon(icon, color: color, size: 32),
      ),
    );
  }

  Widget _buildGeneratingOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80, height: 80,
            child: CircularProgressIndicator(color: AppTheme.accentTeal, strokeWidth: 3),
          ),
          const SizedBox(height: 32),
          ShaderMask(
            shaderCallback: (b) => AppTheme.auroraGradient.createShader(b),
            child: const Text("Stitching your vibe...", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 12),
          Text(
            _matchedVibes.join(" • "),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.8), fontSize: 13, height: 1.5),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 1.seconds),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

// Custom Draggable Card
class _SwipeableCard extends StatefulWidget {
  final Map<String, dynamic> cardData;
  final bool isTopCard;
  final Function(bool isRight) onSwipe;

  const _SwipeableCard({super.key, required this.cardData, required this.isTopCard, required this.onSwipe});

  @override
  State<_SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<_SwipeableCard> {
  Offset _position = Offset.zero;
  double _angle = 0;
  final double _swipeRatioThreshold = 0.3;

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isTopCard) return;
    setState(() {
      _position += details.delta;
      _angle = 45 * (_position.dx / MediaQuery.of(context).size.width);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isTopCard) return;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final swipeRatio = _position.dx / screenWidth;

    if (swipeRatio > _swipeRatioThreshold) {
      widget.onSwipe(true);
    } else if (swipeRatio < -_swipeRatioThreshold) {
      widget.onSwipe(false);
    } else {
      setState(() {
        _position = Offset.zero;
        _angle = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardWidth = size.width * 0.85;
    final cardHeight = size.height * 0.55;

    Widget card = Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: widget.isTopCard ? [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))] : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: widget.cardData['imageUrl'], 
              fit: BoxFit.cover,
              errorWidget: (context, url, error) {
                // Fallback if Unsplash URL returns 404 or fails to load
                return Container(
                  color: AppTheme.surfaceDark,
                  child: const Center(
                    child: Icon(LucideIcons.imageOff, color: Colors.white24, size: 48),
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 30, left: 24, right: 24,
              child: Text(
                widget.cardData['title'],
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1, height: 1.1),
              ),
            ),
            // Overlay Tint for swiping
            if (_position.dx != 0 && widget.isTopCard)
              Container(
                color: _position.dx > 0 ? AppTheme.accentTeal.withOpacity(math.min(0.5, _position.dx / 200)) : Colors.redAccent.withOpacity(math.min(0.5, _position.dx.abs() / 200)),
              ),
          ],
        ),
      ),
    );

    if (widget.isTopCard) {
      card = GestureDetector(
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: card,
      );
    } else {
      // Background cards scale down slightly
      card = Transform.scale(
        scale: 0.95,
        child: Transform.translate(
          offset: const Offset(0, -15),
          child: card,
        ),
      );
    }

    return AnimatedContainer(
      duration: _position == Offset.zero ? const Duration(milliseconds: 300) : Duration.zero,
      curve: Curves.easeOutBack,
      transform: Matrix4.translationValues(_position.dx, _position.dy, 0),
      child: Transform.rotate(
        angle: _angle * (math.pi / 180),
        child: card,
      ),
    );
  }
}
