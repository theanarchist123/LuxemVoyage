import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/gemini_service.dart';

class TripJournalScreen extends StatefulWidget {
  const TripJournalScreen({super.key});

  @override
  State<TripJournalScreen> createState() => _TripJournalScreenState();
}

class _TripJournalScreenState extends State<TripJournalScreen> {
  final List<TextEditingController> _memoryControllers = [
    TextEditingController()
  ];
  bool _isGenerating = false;
  String? _generatedJournal;

  void _addMemoryField() {
    if (_memoryControllers.length >= 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 7 memory fragments allowed for optimal narrative.')),
      );
      return;
    }
    setState(() {
      _memoryControllers.add(TextEditingController());
    });
  }

  void _removeMemoryField(int index) {
    if (_memoryControllers.length > 1) {
      setState(() {
        _memoryControllers[index].dispose();
        _memoryControllers.removeAt(index);
      });
    }
  }

  Future<void> _weaveMemories() async {
    final memories = _memoryControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (memories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one memory spark!')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedJournal = null;
    });

    try {
      final story = await GeminiService().generateTravelJournal(memories);
      if (mounted) {
        setState(() {
          _generatedJournal = story;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to weave memories. The ink dried up!')),
        );
      }
    }
  }

  @override
  void dispose() {
    for (var c in _memoryControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                child: _isGenerating
                    ? _buildLoadingState()
                    : _generatedJournal != null
                        ? _buildJournalResult()
                        : _buildInputState(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12),
            ),
            child: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Text(
            'MEMORY WEAVER',
            style: GoogleFonts.inter(
              color: AppTheme.accentTeal,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 48), // Balance for back button
        ],
      ),
    );
  }

  Widget _buildInputState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What did you\nexperience today?",
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ).animate().fadeIn(duration: 600.ms, curve: Curves.easeOut).slideY(begin: 0.1),
          const SizedBox(height: 16),
          Text(
            "Drop in a few short fragments. A sight, a taste, a feeling. Our AI writer will weave them into a nostalgic journal entry.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
          const SizedBox(height: 48),
          ...List.generate(_memoryControllers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildMemoryField(index),
            ).animate().fadeIn().slideX(begin: 0.05);
          }),
          
          if (_memoryControllers.length < 7)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addMemoryField,
                icon: const Icon(LucideIcons.plus, color: AppTheme.accentTeal, size: 18),
                label: const Text(
                  "Add another spark",
                  style: TextStyle(color: AppTheme.accentTeal, fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  backgroundColor: AppTheme.accentTeal.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ).animate().fadeIn(delay: 400.ms),
            ),
            
          const SizedBox(height: 64),
          
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _weaveMemories,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentAmber,
                foregroundColor: AppTheme.primaryBlack,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(LucideIcons.feather, size: 20),
                  SizedBox(width: 12),
                  Text(
                    "Weave Memories",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMemoryField(int index) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(LucideIcons.sparkles, color: Colors.white38, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _memoryControllers[index],
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: _getHintText(index),
                hintStyle: TextStyle(color: Colors.white24, fontSize: 16),
                border: InputBorder.none,
                isDense: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          if (_memoryControllers.length > 1)
            IconButton(
              icon: const Icon(LucideIcons.x, color: Colors.white38, size: 18),
              onPressed: () => _removeMemoryField(index),
            ),
        ],
      ),
    );
  }

  String _getHintText(int index) {
    const hints = [
      "e.g., Ate messy pistachio gelato",
      "e.g., Got lost in a cobblestone alley",
      "e.g., Watched the sunset turn the sky pink",
      "e.g., The smell of fresh rain on hot pavement",
      "e.g., Found a hidden bookstore",
      "e.g., Laughed until tears came",
      "e.g., A quiet morning coffee on the balcony",
    ];
    return hints[index % hints.length];
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.feather, color: AppTheme.accentAmber, size: 48)
            .animate(onPlay: (controller) => controller.repeat())
            .shake(hz: 2, curve: Curves.easeInOut)
            .shimmer(duration: 2000.ms, color: Colors.white54),
          const SizedBox(height: 32),
          Text(
            "Dipping quill in ink...",
            style: GoogleFonts.playfairDisplay(
              color: Colors.white70,
              fontSize: 24,
              fontStyle: FontStyle.italic,
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(begin: 0.5, end: 1.0),
        ],
      ),
    );
  }

  Widget _buildJournalResult() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F6F0), // Warm paper color
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Journal Entry",
                  style: GoogleFonts.inter(
                    color: Colors.black38,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 24),
                // Decorative divider
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(height: 1, width: 40, color: Colors.black26),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(LucideIcons.flower2, color: AppTheme.accentAmber, size: 16),
                    ),
                    Container(height: 1, width: 40, color: Colors.black26),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  _generatedJournal ?? "",
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.black.withOpacity(0.85),
                    fontSize: 18,
                    height: 1.8,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                const Icon(LucideIcons.penTool, color: Colors.black26, size: 24),
              ],
            ),
          ).animate().fadeIn(duration: 800.ms, curve: Curves.easeOut).slideY(begin: 0.1),
          
          const SizedBox(height: 40),
          
          TextButton.icon(
            onPressed: () {
              setState(() {
                _generatedJournal = null;
                for (var controller in _memoryControllers) {
                  controller.clear();
                }
              });
            },
            icon: const Icon(LucideIcons.rotateCcw, color: Colors.white70, size: 18),
            label: const Text(
              "Start a new page",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
