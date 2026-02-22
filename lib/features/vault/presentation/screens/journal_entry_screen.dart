import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/services/firestore_service.dart';

class JournalEntryScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot> selectedMemories;
  const JournalEntryScreen({Key? key, required this.selectedMemories}) : super(key: key);

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> with TickerProviderStateMixin {
  final GeminiService _gemini = GeminiService();
  final FirestoreService _firestore = FirestoreService();
  
  bool _isGenerating = true;
  bool _isSaving = false;
  String? _story;
  String _streamedStory = '';
  
  // Cinematic background slides
  late PageController _bgController;
  int _currentBgIndex = 0;
  Timer? _bgTimer;

  // Typewriter effect
  Timer? _typewriterTimer;
  int _charIndex = 0;

  @override
  void initState() {
    super.initState();
    _bgController = PageController();
    _startBackgroundSlideshow();
    _generateStory();
  }

  Future<void> _saveToLibrary() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _story == null || _isSaving) return;

    setState(() => _isSaving = true);
    
    try {
      final firstMem = widget.selectedMemories.first.data() as Map<String, dynamic>;
      final locationName = firstMem['location'] ?? 'A Journey Remembered';
      final firstUrl = firstMem['url'] ?? '';

      // Collect URLs used
      final photoUrls = widget.selectedMemories.map((m) => (m.data() as Map<String,dynamic>)['url'] as String).toList();

      await _firestore.saveJournal(user.uid, {
        'title': locationName,
        'story': _story,
        'coverImage': firstUrl,
        'photoUrls': photoUrls,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Journal saved to library!')));
        Navigator.pop(context); // Go back after saving
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _bgTimer?.cancel();
    _typewriterTimer?.cancel();
    _bgController.dispose();
    super.dispose();
  }

  void _startBackgroundSlideshow() {
    if (widget.selectedMemories.isEmpty) return;
    _bgTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      setState(() {
        _currentBgIndex = (_currentBgIndex + 1) % widget.selectedMemories.length;
      });
      _bgController.animateToPage(
        _currentBgIndex,
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _generateStory() async {
    // Artificial dramatic pause
    await Future.delayed(const Duration(milliseconds: 2000));

    // Construct photo descriptions from captions and locations
    final List<String> descriptions = widget.selectedMemories.map<String>((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final cap = data['caption'] ?? '';
      final loc = data['location'] ?? '';
      if (cap.isEmpty && loc.isEmpty) return 'A beautiful memory';
      if (cap.isNotEmpty && loc.isNotEmpty) return '$loc: $cap';
      return cap.isNotEmpty ? cap : loc;
    }).toList();

    try {
      final story = await _gemini.generateTravelJournal(descriptions);
      if (!mounted) return;
      setState(() {
        _story = story;
        _isGenerating = false;
      });
      _startTypewriterEffect();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _story = "The ink ran dry. We couldn't write the story this time.";
        _isGenerating = false;
      });
      _startTypewriterEffect();
    }
  }

  void _startTypewriterEffect() {
    if (_story == null) return;
    final chars = _story!.split('');
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_charIndex < chars.length) {
        setState(() {
          _streamedStory += chars[_charIndex];
          _charIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedMemories.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text('No memories selected', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Cinematic Ken Burns Background
          PageView.builder(
            controller: _bgController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.selectedMemories.length,
            itemBuilder: (context, index) {
              final data = widget.selectedMemories[index].data() as Map<String, dynamic>;
              return SizedBox.expand(
                child: Image.network(data['url'] ?? '', fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppTheme.surfaceDark))
                   .animate(onPlay: (c) => c.repeat())
                   .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 20.seconds), // Ken burns slow zoom
              );
            },
          ),

          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryBlack.withOpacity(0.4),
                  AppTheme.primaryBlack.withOpacity(0.85),
                  AppTheme.primaryBlack,
                ],
                stops: const [0.0, 0.4, 0.9],
              ),
            ),
          ),

          SafeArea(
            child: _isGenerating ? _buildLoadingState() : _buildStoryState(),
          ),

          // Close Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(LucideIcons.x, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.accentAmber.withOpacity(0.3), width: 2),
            ),
            child: const Center(child: Icon(LucideIcons.penTool, color: AppTheme.accentAmber, size: 32)),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 1500.ms)
           .shimmer(color: Colors.white24, duration: 2.seconds),
          
          const SizedBox(height: 32),
          const Text("Weaving your memories together...",
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, letterSpacing: 0.5, fontStyle: FontStyle.italic))
              .animate().fadeIn(duration: 800.ms),
        ],
      ),
    );
  }

  Widget _buildStoryState() {
    final firstMem = widget.selectedMemories.first.data() as Map<String, dynamic>;
    final locationName = firstMem['location'] ?? 'A Journey Remembered';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Journal Title
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(text: 'Chapter: ', style: TextStyle(color: AppTheme.accentAmber, fontSize: 16, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, letterSpacing: 1)),
                TextSpan(text: locationName, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1, height: 1.1)),
              ],
            ),
          ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0),
          
          const SizedBox(height: 48),

          // The streamed story
          Text(
            _streamedStory,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              height: 1.8,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3, // Journal-like spacing
            ),
          ),

          // Wait until generation is fully complete to show actions
          if (_charIndex >= (_story?.length ?? 0)) ...[
            const SizedBox(height: 60),
            
            // Photo strip inline
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: widget.selectedMemories.length,
                itemBuilder: (ctx, i) {
                  final mData = widget.selectedMemories[i].data() as Map<String, dynamic>;
                  return Container(
                    width: 76,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      image: DecorationImage(
                        image: NetworkImage(mData['url'] ?? ''),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: 100 * i)).slideX(begin: 0.1, end: 0);
                },
              ),
            ),

            const SizedBox(height: 48),

            // Share / Save buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.share, color: AppTheme.textPrimary, size: 18),
                        SizedBox(width: 8),
                        Text('Share PDF', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _isSaving ? null : _saveToLibrary,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: _isSaving ? null : AppTheme.amberGradient,
                        color: _isSaving ? Colors.white.withOpacity(0.06) : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _isSaving ? [] : [BoxShadow(color: AppTheme.accentAmber.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 5))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isSaving)
                            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentAmber))
                          else ...[
                            const Icon(LucideIcons.bookmark, color: AppTheme.primaryBlack, size: 18),
                            const SizedBox(width: 8),
                            const Text('Save to Library', style: TextStyle(color: AppTheme.primaryBlack, fontSize: 14, fontWeight: FontWeight.w800)),
                          ]
                        ],
                      ),
                    ).animate().fadeIn(delay: 800.ms),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}
