import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firestore_service.dart';
import 'journal_entry_screen.dart';

class TripJournalScreen extends StatefulWidget {
  const TripJournalScreen({super.key});

  @override
  State<TripJournalScreen> createState() => _TripJournalScreenState();
}

class _TripJournalScreenState extends State<TripJournalScreen> {
  final FirestoreService _firestore = FirestoreService();
  final List<QueryDocumentSnapshot> _selectedMemories = [];
  static const int _maxPhotos = 8;

  void _toggleSelection(QueryDocumentSnapshot doc) {
    setState(() {
      if (_selectedMemories.contains(doc)) {
        _selectedMemories.remove(doc);
      } else if (_selectedMemories.length < _maxPhotos) {
        _selectedMemories.add(doc);
      }
    });
  }

  void _writeStory() {
    if (_selectedMemories.isEmpty) return;
    
    // Sort memories by createdAt ascending so the story flows chronologically
    final sortedMemories = List<QueryDocumentSnapshot>.from(_selectedMemories);
    sortedMemories.sort((a, b) {
      final t1 = (a.data() as Map)['createdAt'] as Timestamp?;
      final t2 = (b.data() as Map)['createdAt'] as Timestamp?;
      if (t1 == null || t2 == null) return 0;
      return t1.compareTo(t2);
    });

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) => JournalEntryScreen(selectedMemories: sortedMemories),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(backgroundColor: AppTheme.primaryBlack);

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.getMemories(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.accentAmber));
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) return _buildEmptyState();
                    return _buildFilmStrip(docs);
                  },
                ),
              ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary, size: 18),
                ),
              ),
              const Expanded(child: SizedBox()),
              ShaderMask(
                shaderCallback: (b) => AppTheme.auroraGradient.createShader(b),
                child: const Text('AI JOURNAL', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.5)),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('Curate your journey', style: TextStyle(color: AppTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('Select up to $_maxPhotos memories to weave into a story', style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7), fontSize: 14)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.imageOff, color: AppTheme.textSecondary.withOpacity(0.3), size: 48),
          const SizedBox(height: 16),
          const Text("No memories to draw from", style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildFilmStrip(List<QueryDocumentSnapshot> docs) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: docs.length,
      itemBuilder: (ctx, i) {
        final doc = docs[i];
        final data = doc.data() as Map<String, dynamic>;
        final isSelected = _selectedMemories.contains(doc);
        final selectionIndex = _selectedMemories.indexOf(doc) + 1;

        return GestureDetector(
          onTap: () => _toggleSelection(doc),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.accentAmber : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: AppTheme.accentAmber.withOpacity(0.3), blurRadius: 16, spreadRadius: 2)]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13), // 16 - 3 border
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(data['url'] ?? '', fit: BoxFit.cover),
                  if (isSelected) Container(color: AppTheme.primaryBlack.withOpacity(0.2)),
                  
                  // Label / Caption gradient
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 30, 12, 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                        ),
                      ),
                      child: Text(data['location'] ?? 'Unknown location', 
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),

                  // Selection Badge
                  if (isSelected)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        width: 26, height: 26,
                        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.amberGradient),
                        child: Center(
                          child: Text('$selectionIndex', style: const TextStyle(color: AppTheme.primaryBlack, fontSize: 13, fontWeight: FontWeight.w800)),
                        ),
                      ).animate().scale(duration: 250.ms, curve: Curves.easeOutBack),
                    ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 50 * i)).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildBottomBar() {
    final count = _selectedMemories.length;
    final progress = count / _maxPhotos;
    final canWrite = count > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(0, -5), blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                count == 0 ? "Select photos to begin" : "$count of $_maxPhotos selected",
                style: TextStyle(color: canWrite ? AppTheme.accentAmber : AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              if (canWrite)
                const Text("Story getting richer...", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 4, width: double.infinity, color: Colors.white.withOpacity(0.05),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  width: MediaQuery.of(context).size.width * progress,
                  decoration: const BoxDecoration(gradient: AppTheme.amberGradient),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: canWrite ? _writeStory : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: canWrite ? AppTheme.amberGradient : null,
                color: canWrite ? null : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                boxShadow: canWrite ? [BoxShadow(color: AppTheme.accentAmber.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 5))] : null,
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.penTool, color: canWrite ? AppTheme.primaryBlack : AppTheme.textSecondary, size: 18),
                    const SizedBox(width: 8),
                    Text('Write My Story', style: TextStyle(color: canWrite ? AppTheme.primaryBlack : AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
