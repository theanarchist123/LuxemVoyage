import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/gemini_service.dart';

class AudioGuidePlayer extends StatefulWidget {
  final String placeName;
  final String? customScript; // Pre-generated script (Custom Experience flow)
  const AudioGuidePlayer({super.key, this.placeName = 'Louvre', this.customScript});

  @override
  State<AudioGuidePlayer> createState() => _AudioGuidePlayerState();
}

class _AudioGuidePlayerState extends State<AudioGuidePlayer>
    with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  final GeminiService _geminiService = GeminiService();

  // State
  String? _script;
  bool _isLoadingScript = true;
  String? _scriptError;
  bool _isPlaying = false;
  bool _isPaused = false;
  double _progress = 0.0;
  int _currentWordIndex = 0;
  int _pausedWordIndex = 0;
  List<String> _words = [];
  double _speechRate = 0.45;
  double _pitch = 1.0;

  // For progress tracking (word count approximation)
  int _totalWords = 0;

  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _initTts();
    _loadScript();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(_speechRate);
    await _tts.setPitch(_pitch);
    await _tts.setVolume(1.0);

    // Try to pick a premium-sounding voice
    if (!kIsWeb) {
      final voices = await _tts.getVoices;
      if (voices != null) {
        final voiceList = voices as List;
        final preferred = voiceList.firstWhere(
          (v) => (v['name'] as String).toLowerCase().contains('en-us-x-sfg') ||
              (v['name'] as String).toLowerCase().contains('daniel') ||
              (v['name'] as String).toLowerCase().contains('en-gb'),
          orElse: () => null,
        );
        if (preferred != null) {
          await _tts.setVoice({'name': preferred['name'], 'locale': preferred['locale']});
        }
      }
    }

    _tts.setStartHandler(() {
      if (mounted) {
        setState(() => _isPlaying = true);
        _waveController.repeat(reverse: true);
      }
    });

    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _isPaused = false;
          _progress = 1.0;
          _currentWordIndex = _totalWords;
        });
        _waveController.stop();
        _waveController.reset();
      }
    });

    _tts.setCancelHandler(() {
      if (mounted) {
        setState(() => _isPlaying = false);
        _waveController.stop();
      }
    });

    _tts.setProgressHandler((text, start, end, word) {
      if (_totalWords > 0 && mounted) {
        _currentWordIndex++;
        setState(() => _progress = (_currentWordIndex / _totalWords).clamp(0.0, 1.0));
      }
    });
  }

  Future<void> _loadScript() async {
    // If a custom script was passed in (Custom Experience flow), use it directly
    if (widget.customScript != null) {
      setState(() {
        _script = widget.customScript;
        _words = widget.customScript!.split(RegExp(r'\s+'));
        _totalWords = _words.length;
        _isLoadingScript = false;
      });
      return;
    }
    setState(() { _isLoadingScript = true; _scriptError = null; });
    try {
      final script = await _geminiService.generateAudioGuideScript(
        placeName: widget.placeName,
      );
      if (mounted) {
        setState(() {
          _script = script;
          _words = script.split(RegExp(r'\s+'));
          _totalWords = _words.length;
          _isLoadingScript = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _scriptError = 'Failed to generate guide. Please try again.';
          _isLoadingScript = false;
        });
      }
    }
  }

  Future<void> _play() async {
    if (_script == null) return;
    if (_isPaused) {
      // Resume from where we paused by re-speaking remaining words
      final remainingText = _words.skip(_pausedWordIndex).join(' ');
      setState(() { _isPlaying = true; _isPaused = false; });
      _waveController.repeat(reverse: true);
      await _tts.speak(remainingText.isNotEmpty ? remainingText : _script!);
    } else {
      _currentWordIndex = 0;
      _pausedWordIndex = 0;
      setState(() { _progress = 0.0; });
      await _tts.speak(_script!);
    }
  }

  Future<void> _pause() async {
    await _tts.stop();
    setState(() { _isPlaying = false; _isPaused = true; _pausedWordIndex = _currentWordIndex; });
    _waveController.stop();
  }

  Future<void> _stop() async {
    await _tts.stop();
    setState(() {
      _isPlaying = false;
      _isPaused = false;
      _progress = 0.0;
      _currentWordIndex = 0;
      _pausedWordIndex = 0;
    });
    _waveController.stop();
    _waveController.reset();
  }

  String _formatProgress(double progress) {
    // Estimate duration: ~130 words/min at normal speed, slower at 0.45 rate
    final estimatedTotalSeconds = (_totalWords / 130.0 / _speechRate) * 60;
    final currentSeconds = (estimatedTotalSeconds * progress).round();
    final totalSeconds = estimatedTotalSeconds.round();

    String fmt(int s) {
      final m = s ~/ 60;
      final sec = s % 60;
      return '$m:${sec.toString().padLeft(2, '0')}';
    }

    return '${fmt(currentSeconds)} / ${fmt(totalSeconds)}';
  }

  @override
  void dispose() {
    _tts.stop();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          CachedNetworkImage(imageUrl: 
            'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?q=80&w=2920&auto=format&fit=crop',
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(color: AppTheme.surfaceDark),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryBlack.withValues(alpha: 0.65),
                  AppTheme.primaryBlack.withValues(alpha: 0.92),
                  AppTheme.primaryBlack,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                _buildTopBar(),

                Expanded(
                  child: _isLoadingScript
                      ? _buildLoadingState()
                      : _scriptError != null
                          ? _buildErrorState()
                          : _buildPlayerContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: const Icon(LucideIcons.chevronDown, color: AppTheme.textPrimary),
            ),
          ),
          Expanded(
            child: Center(
              child: ShaderMask(
                shaderCallback: (b) => AppTheme.auroraGradient.createShader(b),
                child: const Text("PRIVATE AUDIO GUIDE",
                    style: TextStyle(color: Colors.white, fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          GestureDetector(
            onTap: _loadScript,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: const Icon(LucideIcons.refreshCw, color: AppTheme.textSecondary, size: 18),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppTheme.accentAmber.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.3)),
          ),
          child: const Center(child: CircularProgressIndicator(color: AppTheme.accentAmber, strokeWidth: 2)),
        ),
        const SizedBox(height: 24),
        const Text("Crafting your personal guide...",
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (b) => AppTheme.auroraGradient.createShader(b),
          child: const Text("Powered by Gemini AI",
              style: TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.w500)),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.alertCircle, color: Colors.redAccent.withValues(alpha: 0.7), size: 48),
        const SizedBox(height: 16),
        Text(_scriptError!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _loadScript,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            decoration: BoxDecoration(gradient: AppTheme.amberGradient, borderRadius: BorderRadius.circular(12)),
            child: const Text("Try Again", style: TextStyle(color: AppTheme.primaryBlack, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Place info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                Text(widget.placeName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.accentAmber, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3))
                    .animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 6),
                const Text("Chapter 1 · Your Private Tour",
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))
                    .animate().fadeIn(delay: 100.ms),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Waveform visualizer
          _buildWaveform(),
          const SizedBox(height: 24),

          // Script text card
          _buildScriptCard(),
          const SizedBox(height: 24),

          // Player controls card
          _buildControlsCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(28, (i) {
          final heights = [12.0, 28.0, 18.0, 36.0, 22.0, 40.0, 16.0, 32.0, 24.0, 44.0,
              18.0, 38.0, 28.0, 48.0, 20.0, 34.0, 22.0, 42.0, 16.0, 38.0,
              26.0, 44.0, 18.0, 32.0, 24.0, 28.0, 16.0, 20.0];
          final h = heights[i % heights.length];

          final isActive = _isPlaying && (i / 28.0) <= _progress;

          return AnimatedBuilder(
            animation: _waveController,
            builder: (_, __) {
              final animH = _isPlaying
                  ? h * (0.5 + 0.5 * ((_waveController.value + i * 0.08) % 1.0))
                  : h * 0.4;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                width: 3,
                height: animH,
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.accentAmber : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildScriptCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCardDecoration(borderRadius: 22),
      constraints: const BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        child: Text(
          _script ?? '',
          style: const TextStyle(
            color: AppTheme.textSecondary, fontSize: 13, height: 1.8,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildControlsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCardDecoration(borderRadius: 28),
      child: Column(
        children: [
          // Progress bar
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.accentAmber,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
              thumbColor: AppTheme.accentAmber,
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayColor: AppTheme.accentAmber.withValues(alpha: 0.15),
            ),
            child: Slider(value: _progress, onChanged: (_) {}),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatProgress(_progress).split(' / ')[0],
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                Text(
                  _formatProgress(_progress).split(' / ')[1],
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Playback controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Speed button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _speechRate = _speechRate >= 0.7 ? 0.3 : _speechRate + 0.2;
                  });
                  _tts.setSpeechRate(_speechRate);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_speechRate.toStringAsFixed(1)}x',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              // Rewind (restart)
              GestureDetector(
                onTap: _stop,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.skipBack, color: AppTheme.textPrimary, size: 20),
                ),
              ),

              // Play/Pause main button
              GestureDetector(
                onTap: _isPlaying ? _pause : _play,
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: AppTheme.amberGradient,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppTheme.accentAmber.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 6))],
                  ),
                  child: Icon(
                    _isPlaying ? LucideIcons.pause : (_isPaused ? LucideIcons.play : LucideIcons.play),
                    color: AppTheme.primaryBlack, size: 30,
                  ),
                ),
              ),

              // Stop
              GestureDetector(
                onTap: _stop,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.square, color: AppTheme.textPrimary, size: 18),
                ),
              ),

              // Pitch toggle
              GestureDetector(
                onTap: () {
                  setState(() => _pitch = _pitch == 1.0 ? 1.2 : 1.0);
                  _tts.setPitch(_pitch);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _pitch > 1.0 ? AppTheme.accentAmber.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: _pitch > 1.0 ? Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.3)) : null,
                  ),
                  child: Icon(LucideIcons.mic, color: _pitch > 1.0 ? AppTheme.accentAmber : AppTheme.textSecondary, size: 18),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (_isPlaying ? AppTheme.accentTeal : _isPaused ? AppTheme.accentAmber : Colors.white).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: _isPlaying ? AppTheme.accentTeal : _isPaused ? AppTheme.accentAmber : Colors.white.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isPlaying ? 'Now Playing' : _isPaused ? 'Paused' : _progress >= 1.0 ? 'Completed' : 'Ready',
                  style: TextStyle(
                    color: _isPlaying ? AppTheme.accentTeal : _isPaused ? AppTheme.accentAmber : AppTheme.textSecondary,
                    fontSize: 12, fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05, end: 0);
  }
}
