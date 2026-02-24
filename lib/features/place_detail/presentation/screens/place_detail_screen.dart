import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../audio_guide/presentation/screens/audio_guide_player.dart';

class PlaceDetailScreen extends StatelessWidget {
  final String name;
  final String location;
  final String imageUrl;
  final String rating;

  const PlaceDetailScreen({
    Key? key,
    this.name = 'Louvre Private Tour',
    this.location = 'Paris, France',
    this.imageUrl = 'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?q=80&w=2920&auto=format&fit=crop',
    this.rating = '4.9',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 380,
                pinned: true,
                backgroundColor: AppTheme.primaryBlack,
                leading: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlack.withOpacity(0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary, size: 20),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlack.withOpacity(0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.bookmark, color: AppTheme.accentAmber, size: 20),
                      onPressed: () {},
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(imageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              color: AppTheme.surfaceDark,
                              child: const Icon(LucideIcons.image, color: AppTheme.accentAmber, size: 60))),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter, end: Alignment.bottomCenter,
                            stops: const [0.0, 0.5, 1.0],
                            colors: [Colors.transparent, Colors.transparent, AppTheme.primaryBlack],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.3))
                            .animate().fadeIn(duration: 400.ms),
                        const SizedBox(height: 12),
                        Row(children: [
                          const Icon(LucideIcons.mapPin, color: AppTheme.accentAmber, size: 15),
                          const SizedBox(width: 6),
                          Text(location, style: const TextStyle(color: AppTheme.accentAmber, fontSize: 14)),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.accentAmber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(children: [
                              const Icon(Icons.star_rounded, color: AppTheme.accentAmber, size: 14),
                              const SizedBox(width: 3),
                              Text(rating, style: const TextStyle(color: AppTheme.accentAmber, fontSize: 13, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ]).animate().fadeIn(delay: 100.ms),
                        const SizedBox(height: 28),
                        const Text("About this Experience",
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        const Text(
                          "Experience the world's most iconic destinations like never before. With our exclusive private access, you'll bypass the queues and enjoy a curated, intimate journey guided by an expert concierge — an experience that transcends ordinary tourism.",
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.7),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _highlight(LucideIcons.clock, "3 Hours"),
                            _highlight(LucideIcons.users, "Private"),
                            _highlight(LucideIcons.star, "5-Star"),
                          ],
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 28),
                        const Text("Reviews",
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        _review("Isabella M.", "Absolutely extraordinary experience. The private access made this feel truly exclusive.", "5.0"),
                        const SizedBox(height: 12),
                        _review("Thomas R.", "Impeccable service from start to finish. Worth every penny.", "4.9"),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ),
          // Bottom CTA
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [AppTheme.primaryBlack.withOpacity(0), AppTheme.primaryBlack],
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.amberGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppTheme.accentAmber.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AudioGuidePlayer(placeName: name))),
                    icon: const Icon(LucideIcons.headphones, size: 18),
                    label: const Text("Private Audio Guide", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: AppTheme.primaryBlack,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlight(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: AppTheme.glassCardDecoration(borderRadius: 16, withShadow: false),
      child: Column(children: [
        Icon(icon, color: AppTheme.accentAmber, size: 20),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _review(String reviewer, String comment, String stars) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCardDecoration(borderRadius: 16, withShadow: false),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(reviewer, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppTheme.accentAmber.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.star_rounded, color: AppTheme.accentAmber, size: 13),
              const SizedBox(width: 3),
              Text(stars, style: const TextStyle(color: AppTheme.accentAmber, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        Text(comment, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
      ]),
    );
  }
}
