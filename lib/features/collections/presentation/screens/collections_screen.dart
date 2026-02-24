import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../features/planner/presentation/screens/itinerary_result_screen.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  String _filter = 'all'; // 'all', 'dreaming', 'planning', 'completed'

  final Map<String, Map<String, dynamic>> _statusConfig = {
    'dreaming': {'label': '✈️ Dreaming', 'color': AppTheme.accentViolet},
    'planning': {'label': '📅 Planning', 'color': AppTheme.accentAmber},
    'completed': {'label': '✅ Done', 'color': AppTheme.accentTeal},
  };

  final Map<String, String> _destinationImages = {
    'Paris': 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?q=80&w=600',
    'Maldives': 'https://images.unsplash.com/photo-1573843981267-be1999ff37cd?q=80&w=600',
    'Santorini': 'https://images.unsplash.com/photo-1533105079780-92b9be482077?q=80&w=600',
    'Kyoto': 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?q=80&w=600',
    'Amalfi': 'https://images.unsplash.com/photo-1612698093158-e07ac200d44e?q=80&w=600',
    'Bali': 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?q=80&w=600',
    'Dubai': 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?q=80&w=600',
    'Machu': 'https://images.unsplash.com/photo-1526392060635-9d6019884377?q=80&w=600',
  };

  String _getImageForDestination(String destination) {
    for (final key in _destinationImages.keys) {
      if (destination.toLowerCase().contains(key.toLowerCase())) {
        return _destinationImages[key]!;
      }
    }
    return 'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?q=80&w=600';
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
              _buildFilterRow(),
              Expanded(child: _buildCollectionsList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('My Collections',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              ShaderMask(
                shaderCallback: (b) => AppTheme.auroraGradient.createShader(b),
                child: const Text('YOUR DREAM LIBRARY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2)),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildFilterRow() {
    final filters = [
      {'key': 'all', 'label': 'All Trips'},
      {'key': 'dreaming', 'label': '✈️ Dreaming'},
      {'key': 'planning', 'label': '📅 Planning'},
      {'key': 'completed', 'label': '✅ Done'},
    ];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = filters[i];
          final isActive = _filter == f['key'];
          return GestureDetector(
            onTap: () => setState(() => _filter = f['key']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                gradient: isActive ? AppTheme.amberGradient : null,
                color: isActive ? null : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: isActive ? null : Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Text(f['label']!,
                  style: TextStyle(
                    color: isActive ? AppTheme.primaryBlack : AppTheme.textSecondary,
                    fontSize: 13, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  )),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildCollectionsList() {
    if (_uid == null) return _emptyState('Please log in to view your collections.');

    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getItineraries(_uid!),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.accentAmber));
        }

        var docs = snap.data?.docs ?? [];
        if (_filter != 'all') {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return (data['status'] ?? 'dreaming') == _filter;
          }).toList();
        }

        if (docs.isEmpty) {
          return _emptyState(_filter == 'all'
              ? 'No trips saved yet.\nGenerate an itinerary and save it!'
              : 'No trips with this status yet.');
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          physics: const BouncingScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            return _buildTripCard(doc.id, data, i);
          },
        );
      },
    );
  }

  Widget _buildTripCard(String docId, Map<String, dynamic> data, int index) {
    final destination = data['destination'] as String? ?? 'Unknown';
    final days = data['days'] as int? ?? 0;
    final tier = data['tier'] as String? ?? 'Premium';
    final status = data['status'] as String? ?? 'dreaming';
    final imageUrl = _getImageForDestination(destination);
    final statusConf = _statusConfig[status] ?? _statusConfig['dreaming']!;

    final tierColors = {
      'Premium': AppTheme.accentTeal,
      'Elite Luxury': AppTheme.accentAmber,
      'Bespoke VIP': AppTheme.accentViolet,
    };
    final tierColor = tierColors[tier] ?? AppTheme.accentAmber;

    return GestureDetector(
      onTap: () {
        final itinerary = List<Map<String, dynamic>>.from(data['itinerary'] ?? []);
        Navigator.push(context, PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => ItineraryResultScreen(
            destination: destination, days: days, tier: tier, itinerary: itinerary,
          ),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: Tween(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ), child: child),
          ),
        ));
      },
      child: Container(
        height: 200,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              Image.network(imageUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: AppTheme.surfaceDark)),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Colors.transparent, AppTheme.primaryBlack.withOpacity(0.85)],
                  ),
                ),
              ),

              // Status ribbon (top-right)
              Positioned(
                top: 14, right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (statusConf['color'] as Color).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: (statusConf['color'] as Color).withOpacity(0.5)),
                  ),
                  child: Text(statusConf['label'] as String,
                      style: TextStyle(color: statusConf['color'] as Color, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),

              // Content bottom
              Positioned(
                left: 20, right: 20, bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(destination,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('$days days', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: tierColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: tierColor.withOpacity(0.3)),
                        ),
                        child: Text(tier, style: TextStyle(color: tierColor, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      // Status change + delete menu
                      GestureDetector(
                        onTap: () => _showOptionsSheet(docId, status),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(LucideIcons.moreHorizontal, color: AppTheme.textSecondary, size: 16),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 80 * index)).slideY(begin: 0.06, end: 0);
  }

  void _showOptionsSheet(String docId, String currentStatus) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Update Trip Status', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...['dreaming', 'planning', 'completed'].map((s) {
              final conf = _statusConfig[s]!;
              final isActive = s == currentStatus;
              return ListTile(
                leading: Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(color: conf['color'] as Color, shape: BoxShape.circle),
                ),
                title: Text(conf['label'] as String, style: TextStyle(color: isActive ? conf['color'] as Color : AppTheme.textPrimary)),
                trailing: isActive ? Icon(LucideIcons.checkCircle2, color: conf['color'] as Color, size: 18) : null,
                onTap: () {
                  Navigator.pop(context);
                  _firestoreService.updateItineraryStatus(_uid!, docId, s);
                },
              );
            }),
            const Divider(color: Colors.white12, height: 24),
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 20),
              title: const Text('Delete Trip', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                _firestoreService.deleteItinerary(_uid!, docId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76, height: 76,
            decoration: BoxDecoration(
              color: AppTheme.accentAmber.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.accentAmber.withOpacity(0.2)),
            ),
            child: const Icon(LucideIcons.bookMarked, color: AppTheme.accentAmber, size: 32),
          ),
          const SizedBox(height: 20),
          Text(message, textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.6)),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }
}
