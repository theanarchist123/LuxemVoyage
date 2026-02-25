import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../../../main_scaffold.dart';
import '../../../../core/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final AuthService _authService = AuthService();

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const MainScaffold(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!_isLogin && name.isEmpty)) {
      _showError("Please fill in all fields");
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await _authService.login(email: email, password: password);
      } else {
        await _authService.signUp(name: name, email: email, password: password);
      }
      _navigateToHome();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleAuth() async {
    setState(() => _isLoading = true);
    try {
      final cred = await _authService.signInWithGoogle();
      if (cred != null) _navigateToHome();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: Stack(
          children: [
            // Aurora orbs
            Positioned(
              top: -60, right: -40,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppTheme.accentViolet.withValues(alpha: 0.12),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Positioned(
              top: 180, left: -80,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppTheme.accentTeal.withValues(alpha: 0.08),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            // Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Center(
                        child: Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [
                              AppTheme.accentAmber.withValues(alpha: 0.2),
                              AppTheme.accentAmber.withValues(alpha: 0.05),
                            ]),
                            border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.5)),
                          ),
                          child: Center(
                            child: Image.asset(
                              'ChatGPT_Image_Feb_22__2026__05_45_13_PM-removebg-preview.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8)),
                      const SizedBox(height: 28),
                      // Title
                      Center(
                        child: Text(
                          _isLogin ? "Welcome Back" : "Join LuxeVoyage",
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5),
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.15, end: 0),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _isLogin ? "Sign in to continue your journey" : "Create your exclusive account",
                          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                        ),
                      ).animate().fadeIn(delay: 150.ms),
                      const SizedBox(height: 40),

                      // Glass form card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.glassCardDecoration(borderRadius: 24),
                        child: Column(
                          children: [
                            _buildField("Email Address", LucideIcons.mail, false, _emailController),
                            const SizedBox(height: 14),
                            if (!_isLogin) ...[
                              _buildField("Full Name", LucideIcons.user, false, _nameController),
                              const SizedBox(height: 14),
                            ],
                            _buildField("Password", LucideIcons.lock, true, _passwordController),
                            const SizedBox(height: 24),
                            _isLoading
                                ? const Center(child: CircularProgressIndicator(color: AppTheme.accentAmber))
                                : GoldButton(text: _isLogin ? "Sign In" : "Create Account", onPressed: _handleAuth),
                          ],
                        ),
                      ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 28),
                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text("or", style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.6), fontSize: 13)),
                          ),
                          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08))),
                        ],
                      ).animate().fadeIn(delay: 350.ms),
                      const SizedBox(height: 20),
                      // Google sign-in
                      GestureDetector(
                        onTap: _isLoading ? null : _handleGoogleAuth,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: AppTheme.glassDecoration(borderRadius: 14, opacity: 0.04),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.chrome, color: AppTheme.textSecondary, size: 20),
                              SizedBox(width: 10),
                              Text("Continue with Google",
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: 32),
                      // Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isLogin ? "New here?  " : "Already a member?  ",
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _isLogin = !_isLogin),
                            child: Text(
                              _isLogin ? "Create Account" : "Sign In",
                              style: const TextStyle(color: AppTheme.accentAmber, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 450.ms),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, IconData icon, bool obscure, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5)),
        filled: true,
        fillColor: AppTheme.surfaceLight.withValues(alpha: 0.5),
        prefixIcon: Icon(icon, color: AppTheme.accentAmber.withValues(alpha: 0.7), size: 19),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.accentAmber, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
        ),
      ),
    );
  }
}
