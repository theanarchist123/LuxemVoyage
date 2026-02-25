import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../audio_guide/presentation/screens/audio_guide_player.dart';

class CreateExperienceScreen extends StatefulWidget {
  final String? prefilledLocation;
  final double? latitude;
  final double? longitude;

  const CreateExperienceScreen({
    super.key,
    this.prefilledLocation,
    this.latitude,
    this.longitude,
  });

  @override
  State<CreateExperienceScreen> createState() => _CreateExperienceScreenState();
}

class _CreateExperienceScreenState extends State<CreateExperienceScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _storyCtrl = TextEditingController();
  int _currentStep = 0;
  String? _selectedPhotoPath;
  bool _isGenerating = false;
  String _generatingStatus = '';

  final GeminiService _gemini = GeminiService();
  final FirestoreService _firestore = FirestoreService();

  @override
  void initState() {
    super.initState();
    if (widget.prefilledLocation != null) {
      _nameCtrl.text = widget.prefilledLocation!;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _storyCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _generateExperience();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _selectedPhotoPath = picked.path);
  }

  Future<void> _generateExperience() async {
    if (_nameCtrl.text.trim().isEmpty || _storyCtrl.text.trim().isEmpty) return;
    setState(() { _isGenerating = true; _generatingStatus = 'Reading your story...'; });

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _generatingStatus = 'Exploring the location...');
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _generatingStatus = 'Crafting your guide...');

    try {
      final script = await _gemini.generateCustomAudioScript(
        placeName: _nameCtrl.text.trim(),
        userStory: _storyCtrl.text.trim(),
        locationHint: widget.prefilledLocation,
      );

      // Save to Firestore
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await _firestore.saveCustomExperience(uid, {
          'placeName': _nameCtrl.text.trim(),
          'userStory': _storyCtrl.text.trim(),
          'script': script,
          'latitude': widget.latitude,
          'longitude': widget.longitude,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      if (!mounted) return;
      setState(() => _isGenerating = false);

      // Navigate to Audio Guide Player with the custom script
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => AudioGuidePlayer(
            placeName: _nameCtrl.text.trim(),
            customScript: script,
          ),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween(begin: 0.92, end: 1.0).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: SafeArea(
          child: _isGenerating ? _buildGenerating() : _buildFlow(),
        ),
      ),
    );
  }

  Widget _buildGenerating() {
    final statusSteps = ['Reading your story...', 'Exploring the location...', 'Crafting your guide...'];
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Aurora pulsing orb
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.auroraGradient,
              boxShadow: [BoxShadow(color: AppTheme.accentAmber.withValues(alpha: 0.3), blurRadius: 40)],
            ),
            child: const Center(child: Icon(LucideIcons.sparkles, color: Colors.white, size: 36)),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.05, 1.05), duration: 1200.ms),
          const SizedBox(height: 36),
          ...statusSteps.map((s) {
            final isDone = statusSteps.indexOf(s) < statusSteps.indexOf(_generatingStatus);
            final isActive = s == _generatingStatus;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? AppTheme.accentTeal : isActive ? AppTheme.accentAmber : Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(s, style: TextStyle(
                    color: isActive ? AppTheme.textPrimary : isDone ? AppTheme.accentTeal : AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  )),
                ],
              ),
            );
          }),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildFlow() {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: _currentStep > 0 ? _prevStep : () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Icon(_currentStep > 0 ? LucideIcons.arrowLeft : LucideIcons.x,
                      color: AppTheme.textPrimary, size: 18),
                ),
              ),
              Expanded(
                child: Center(
                  child: ShaderMask(
                    shaderCallback: (b) => AppTheme.auroraGradient.createShader(b),
                    child: const Text('CREATE EXPERIENCE',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.5)),
                  ),
                ),
              ),
              // Step indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${_currentStep + 1} / 4',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),

        // Step dots
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == _currentStep ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                gradient: i == _currentStep ? AppTheme.amberGradient : null,
                color: i == _currentStep ? null : (i < _currentStep ? AppTheme.accentTeal : Colors.white.withValues(alpha: 0.12)),
                borderRadius: BorderRadius.circular(4),
              ),
            )),
          ),
        ),

        // Pages
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [_buildStep1(), _buildStep2(), _buildStep3(), _buildStep4()],
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return _stepWrapper(
      title: "Name this place",
      subtitle: "What do you call this spot?",
      icon: LucideIcons.mapPin,
      child: Column(
        children: [
          Container(
            decoration: AppTheme.glassCardDecoration(borderRadius: 18),
            child: TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'My Eiffel Tower Spot...',
                hintStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5), fontSize: 16),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
          ),
          const SizedBox(height: 32),
          _nextButton('Next →', enabled: true),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return _stepWrapper(
      title: "Tell your story",
      subtitle: "What makes this place uniquely yours?",
      icon: LucideIcons.heart,
      child: Column(
        children: [
          Container(
            height: 180,
            decoration: AppTheme.glassCardDecoration(borderRadius: 18),
            child: TextField(
              controller: _storyCtrl,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, height: 1.7),
              maxLines: null,
              expands: true,
              decoration: InputDecoration(
                hintText: 'We watched the sun set from right here, and everything changed...',
                hintStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.4), fontSize: 13, fontStyle: FontStyle.italic),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ValueListenableBuilder(
              valueListenable: _storyCtrl,
              builder: (_, __, ___) => Text('${_storyCtrl.text.length} words',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ),
          ),
          const SizedBox(height: 24),
          _nextButton('Next →', enabled: true),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return _stepWrapper(
      title: "Add a photo",
      subtitle: "Optional — a memory from this place",
      icon: LucideIcons.image,
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.2), style: BorderStyle.solid),
              ),
              child: _selectedPhotoPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CachedNetworkImage(imageUrl: _selectedPhotoPath!, fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _photoPlaceholder()),
                    )
                  : _photoPlaceholder(),
            ),
          ),
          const SizedBox(height: 32),
          Row(children: [
            Expanded(child: _nextButton('Generate My Guide ✦', enabled: true)),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _generateExperience,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Text('Skip', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildStep4() => _buildStep3(); // Step 4 is handled by generate

  Widget _photoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: AppTheme.accentAmber.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.camera, color: AppTheme.accentAmber, size: 24),
        ),
        const SizedBox(height: 12),
        const Text('Tap to add a photo', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _stepWrapper({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppTheme.accentAmber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: AppTheme.accentAmber, size: 22),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 28),
          child,
        ],
      ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.03, end: 0),
    );
  }

  Widget _nextButton(String label, {required bool enabled}) {
    return GestureDetector(
      onTap: enabled ? _nextStep : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: enabled ? AppTheme.amberGradient : null,
          color: enabled ? null : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [BoxShadow(color: AppTheme.accentAmber.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 5))]
              : null,
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                color: enabled ? AppTheme.primaryBlack : AppTheme.textSecondary,
                fontSize: 15, fontWeight: FontWeight.w700,
              )),
        ),
      ),
    );
  }
}
