import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/screens/home_dashboard.dart';
import 'features/map/presentation/screens/map_screen.dart';
import 'features/planner/presentation/screens/trip_planner_screen.dart';
import 'features/vault/presentation/screens/memory_vault.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/chat/presentation/screens/chat_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  late final PageController _pageController;

  final List<Widget> _screens = const [
    HomeDashboard(),
    MapScreen(),
    TripPlannerScreen(),
    MemoryVault(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onTabTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: _buildConciergeOrb(context),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
          ),
        ),
        child: CircleNavBar(
          activeIcons: [
            const Icon(LucideIcons.home, color: AppTheme.primaryBlack, size: 22),
            const Icon(LucideIcons.map, color: AppTheme.primaryBlack, size: 22),
            const Icon(LucideIcons.compass, color: AppTheme.primaryBlack, size: 22),
            const Icon(LucideIcons.image, color: AppTheme.primaryBlack, size: 22),
            _buildProfileIcon(true),
          ],
          inactiveIcons: [
            Icon(LucideIcons.home, color: AppTheme.textSecondary.withValues(alpha: 0.5), size: 20),
            Icon(LucideIcons.map, color: AppTheme.textSecondary.withValues(alpha: 0.5), size: 20),
            Icon(LucideIcons.compass, color: AppTheme.textSecondary.withValues(alpha: 0.5), size: 20),
            Icon(LucideIcons.image, color: AppTheme.textSecondary.withValues(alpha: 0.5), size: 20),
            _buildProfileIcon(false),
          ],
          color: AppTheme.surfaceDark.withValues(alpha: 0.95),
          circleColor: AppTheme.accentAmber,
          height: 62,
          circleWidth: 52,
          activeIndex: _currentIndex,
          onTap: _onTabTap,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildProfileIcon(bool isActive) {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? AppTheme.primaryBlack : Colors.transparent,
            width: 2,
          ),
        ),
        child: CircleAvatar(
          radius: isActive ? 13 : 11,
          backgroundImage: CachedNetworkImageProvider(photoUrl),
        ),
      );
    }

    return Icon(
      LucideIcons.user,
      color: isActive ? AppTheme.primaryBlack : AppTheme.textSecondary.withValues(alpha: 0.6),
      size: isActive ? 24 : 22,
    );
  }

  Widget _buildConciergeOrb(BuildContext context) {
    // Feature 5: Live Concierge Mode — Glowing Teal Orb
    // In a real app, logic would check if an itinerary is "active" today.
    // For presentation, we assume it is active.
    const String activeTripContext = "Welcome to Paris! You're on Day 2 of your Elite luxury journey. The Arc de Triomphe opens in 2 hours — shall I find you a table nearby for breakfast?";

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppTheme.accentTeal, AppTheme.accentTeal.withValues(alpha: 0.7)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentTeal.withValues(alpha: 0.4),
            blurRadius: 18, spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 400),
              pageBuilder: (_, __, ___) => const ChatScreen(initialContextMessage: activeTripContext),
              transitionsBuilder: (_, animation, __, child) {
                return SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
            ),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(LucideIcons.compass, color: AppTheme.primaryBlack, size: 24),
      ),
    );
  }
}

