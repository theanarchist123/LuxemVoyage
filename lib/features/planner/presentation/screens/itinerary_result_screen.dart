import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../collections/presentation/screens/collections_screen.dart';
import '../../../costs/presentation/screens/cost_diary_screen.dart';
import 'smart_packing_screen.dart';

class ItineraryResultScreen extends StatefulWidget {
  final String destination;
  final int days;
  final String tier;
  final List<Map<String, dynamic>> itinerary;

  const ItineraryResultScreen({
    super.key,
    required this.destination,
    required this.days,
    required this.tier,
    required this.itinerary,
  });

  @override
  State<ItineraryResultScreen> createState() => _ItineraryResultScreenState();
}

class _ItineraryResultScreenState extends State<ItineraryResultScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSaving = false;
  bool _isSaved = false;

  Future<void> _saveItinerary() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save items.'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _firestoreService.saveItinerary(user.uid, {
        'destination': widget.destination, 'days': widget.days, 'tier': widget.tier,
        'itinerary': widget.itinerary,
        'status': 'dreaming',
        'createdAt': DateTime.now().toIso8601String(),
      });
      HapticFeedback.mediumImpact();
      setState(() => _isSaved = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildTripSummary(),
              const SizedBox(height: 4),
              Expanded(child: _buildTimeline()),
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text("Your Itinerary",
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: AppTheme.amberGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.sparkles, color: AppTheme.primaryBlack, size: 12),
                SizedBox(width: 4),
                Text("AI", style: TextStyle(color: AppTheme.primaryBlack, fontSize: 11, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildTripSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withOpacity(0.7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            _chip(LucideIcons.mapPin, widget.destination),
            Container(width: 1, height: 20, color: Colors.white.withOpacity(0.06)),
            _chip(LucideIcons.calendar, '${widget.days} days'),
            Container(width: 1, height: 20, color: Colors.white.withOpacity(0.06)),
            _chip(LucideIcons.crown, widget.tier),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _chip(IconData icon, String label) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.accentAmber, size: 13),
          const SizedBox(width: 5),
          Flexible(
            child: Text(label,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    if (widget.itinerary.isEmpty) {
      return const Center(child: Text("Failed to generate.", style: TextStyle(color: AppTheme.textPrimary)));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 16, 20, 16),
      physics: const BouncingScrollPhysics(),
      itemCount: widget.itinerary.length,
      itemBuilder: (ctx, i) {
        final day = widget.itinerary[i];
        final activities = day['activities'] as List<dynamic>? ?? [];
        final isLast = i == widget.itinerary.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline track
              SizedBox(
                width: 50,
                child: Column(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        gradient: AppTheme.amberGradient,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppTheme.accentAmber.withOpacity(0.3), blurRadius: 10)],
                      ),
                      child: Center(
                        child: Text('${day['day'] ?? (i + 1)}',
                            style: const TextStyle(color: AppTheme.primaryBlack, fontSize: 12, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [AppTheme.accentAmber.withOpacity(0.5), AppTheme.accentAmber.withOpacity(0.05)],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Day card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16, left: 4),
                  padding: const EdgeInsets.all(18),
                  decoration: AppTheme.glassCardDecoration(borderRadius: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(day['title']?.toString() ?? 'Experiences',
                          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                      if (day['desc'] != null) ...[
                        const SizedBox(height: 6),
                        Text(day['desc'].toString(),
                            style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7), fontSize: 13, height: 1.5)),
                      ],
                      if (activities.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...activities.map((act) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              width: 5, height: 5,
                              margin: const EdgeInsets.only(top: 7, right: 10),
                              decoration: const BoxDecoration(color: AppTheme.accentAmber, shape: BoxShape.circle),
                            ),
                            Expanded(
                              child: Text(act.toString(),
                                  style: TextStyle(color: AppTheme.textPrimary.withOpacity(0.8), fontSize: 13, height: 1.5)),
                            ),
                          ]),
                        )),
                      ],
                      if (day['hotel'] != null) ...[
                        const SizedBox(height: 10),
                        _infoPill(LucideIcons.hotel, day['hotel'].toString(), AppTheme.accentAmber),
                      ],
                      if (day['dining'] != null) ...[
                        const SizedBox(height: 8),
                        _infoPill(LucideIcons.utensilsCrossed, day['dining'].toString(), AppTheme.accentTeal),
                      ],
                    ],
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 80 * i)).slideX(begin: 0.05, end: 0),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoPill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.9),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (!_isSaved)
          GoldButton(
            text: _isSaving ? "Saving..." : "Save to Collections",
            icon: _isSaving ? null : LucideIcons.bookmark,
            onPressed: _isSaving ? null : _saveItinerary,
          )
        else
          Column(children: [
            // Success row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.accentTeal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.accentTeal.withOpacity(0.25)),
              ),
              child: Row(children: [
                const Icon(LucideIcons.checkCircle2, color: AppTheme.accentTeal, size: 18),
                const SizedBox(width: 10),
                const Text("Saved to Collections",
                    style: TextStyle(color: AppTheme.accentTeal, fontWeight: FontWeight.w700, fontSize: 14)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CollectionsScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.accentTeal.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text("View →",
                        style: TextStyle(color: AppTheme.accentTeal, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
            
            const SizedBox(height: 12),
            
            // Track Expenses Button
            GestureDetector(
              onTap: () {
                // Future Implementation: pass the itinerary ID
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CostDiaryScreen()));
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.accentViolet.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.accentViolet.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.wallet, color: AppTheme.accentViolet, size: 18),
                    SizedBox(width: 8),
                    Text("Track Expenses", style: TextStyle(color: AppTheme.accentViolet, fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 12),

            // Smart Pack Button
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => SmartPackingScreen(
                  destination: widget.destination,
                  itinerary: widget.itinerary,
                )));
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.accentAmber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.accentAmber.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.briefcase, color: AppTheme.accentAmber, size: 18),
                    SizedBox(width: 8),
                    Text("Smart Pack", style: TextStyle(color: AppTheme.accentAmber, fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),

          ]),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("← Plan Another Trip",
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ),
      ]),
    );
  }
}
