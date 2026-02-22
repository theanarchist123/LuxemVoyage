import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../collections/presentation/screens/collections_screen.dart';
import '../../../planner/presentation/screens/mood_board_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;
    final displayName = user?.displayName ?? 'Traveller';
    final email = user?.email ?? '';

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // ── Profile Card ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [AppTheme.accentAmber.withOpacity(0.1), AppTheme.accentViolet.withOpacity(0.06)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: AppTheme.accentAmber.withOpacity(0.12)),
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.accentAmber, width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: AppTheme.surfaceDark,
                            backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                            child: photoUrl == null || photoUrl.isEmpty
                                ? const Icon(LucideIcons.user, size: 36, color: AppTheme.accentAmber)
                                : null,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: AppTheme.amberGradient,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primaryBlack, width: 2),
                          ),
                          child: const Icon(LucideIcons.pencil, size: 12, color: AppTheme.primaryBlack),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(displayName,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(gradient: AppTheme.amberGradient, borderRadius: BorderRadius.circular(8)),
                      child: const Text("Elite Traveller", style: TextStyle(color: AppTheme.primaryBlack, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0),

              const SizedBox(height: 20),
              // ── Stats ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: AppTheme.glassCardDecoration(borderRadius: 22),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _stat("12", "Trips"),
                    _divider(),
                    _stat("8", "Countries"),
                    _divider(),
                    _stat("47", "Memories"),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 28),
              _section("My Journeys"),
              _tile(LucideIcons.bookMarked, "Collections", context, onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectionsScreen()));
              }),
              _tile(LucideIcons.sparkles, "Discover Destinations", context, onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MoodBoardScreen()));
              }),
              const SizedBox(height: 20),
              _section("Account"),
              _tile(LucideIcons.user, "Personal Details", context),
              _tile(LucideIcons.heart, "Saved Destinations", context),
              _tile(LucideIcons.sliders, "Travel Preferences", context),
              const SizedBox(height: 20),
              _section("App"),
              _tile(LucideIcons.bell, "Notifications", context),
              _tile(LucideIcons.shield, "Privacy & Security", context),
              _tile(LucideIcons.helpCircle, "Help & Support", context),
              const SizedBox(height: 20),
              _tile(LucideIcons.logOut, "Sign Out", context, isDestructive: true, onTap: () async {
                await AuthService().signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                }
              }),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(children: [
      Text(value, style: const TextStyle(color: AppTheme.accentAmber, fontSize: 24, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
    ]);
  }

  Widget _divider() => Container(height: 36, width: 1, color: Colors.white.withOpacity(0.06));

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
      ),
    );
  }

  Widget _tile(IconData icon, String label, BuildContext context,
      {bool isDestructive = false, VoidCallback? onTap}) {
    final color = isDestructive ? Colors.redAccent : AppTheme.accentAmber;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: ListTile(
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(label, style: TextStyle(color: isDestructive ? Colors.redAccent : AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
        trailing: Icon(LucideIcons.chevronRight, color: AppTheme.textSecondary.withOpacity(0.3), size: 16),
        onTap: onTap ?? () {},
      ),
    );
  }
}
