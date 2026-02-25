import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/gemini_service.dart';

class SmartPackingScreen extends StatefulWidget {
  final String destination;
  final List<dynamic> itinerary;

  const SmartPackingScreen({super.key, required this.destination, required this.itinerary});

  @override
  State<SmartPackingScreen> createState() => _SmartPackingScreenState();
}

class _SmartPackingScreenState extends State<SmartPackingScreen> {
  final GeminiService _gemini = GeminiService();
  bool _isLoading = true;
  Map<String, dynamic> _packingList = {};
  
  // Track checked items: Map<DayKey, List<int>> (list of indices of packed items)
  final Map<String, List<int>> _packedItems = {};

  @override
  void initState() {
    super.initState();
    _fetchPackingList();
  }

  Future<void> _fetchPackingList() async {
    final list = await _gemini.generatePackingList(widget.destination, widget.itinerary);
    if (!mounted) return;
    setState(() {
      _packingList = list;
      for (var key in _packingList.keys) {
        _packedItems[key] = [];
      }
      _isLoading = false;
    });
  }

  void _toggleItem(String dayKey, int itemIndex) {
    setState(() {
      final packedForDay = _packedItems[dayKey]!;
      if (packedForDay.contains(itemIndex)) {
        packedForDay.remove(itemIndex);
      } else {
        packedForDay.add(itemIndex);
      }
    });
  }

  double get _progress {
    if (_packingList.isEmpty) return 0.0;
    int totalItems = 0;
    int packedItems = 0;
    
    _packingList.forEach((key, items) {
      final List list = items as List;
      totalItems += list.length;
      packedItems += _packedItems[key]?.length ?? 0;
    });
    
    if (totalItems == 0) return 0.0;
    return packedItems / totalItems;
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
              if (_isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator(color: AppTheme.accentTeal)))
              else ...[
                _buildProgressBar(),
                Expanded(child: _buildList()),
              ]
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
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary, size: 18),
                ),
              ),
              const Expanded(child: SizedBox()),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.accentTeal.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.sparkles, color: AppTheme.accentTeal, size: 14),
                    SizedBox(width: 6),
                    Text('AI Curated', style: TextStyle(color: AppTheme.accentTeal, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Smart Pack', style: TextStyle(color: AppTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text('Tailored for ${widget.destination}', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.7), fontSize: 14)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(_progress * 100).toInt()}% Packed', style: const TextStyle(color: AppTheme.accentTeal, fontSize: 13, fontWeight: FontWeight.w700)),
              if (_progress == 1.0)
                const Text('Ready to go!', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)).animate().fadeIn().slideX(),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 8, width: double.infinity, color: Colors.white.withValues(alpha: 0.05),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  width: MediaQuery.of(context).size.width * _progress,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppTheme.accentTeal, AppTheme.accentTeal.withValues(alpha: 0.6)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildList() {
    final keys = _packingList.keys.toList();
    // Sort keys logically if they are "Day 1", "Day 2", etc.
    keys.sort((a, b) {
      final aNum = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final bNum = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return aNum.compareTo(bNum);
    });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemCount: keys.length,
      itemBuilder: (ctx, i) {
        final dayKey = keys[i];
        final items = _packingList[dayKey] as List<dynamic>;
        
        // Find the title from the itinerary for this day
        final dayNumStr = dayKey.replaceAll(RegExp(r'[^0-9]'), '');
        String dayTitle = 'Activities';
        try {
           final dayNum = int.parse(dayNumStr);
           final match = widget.itinerary.firstWhere((element) => element['day'] == dayNum, orElse: () => null);
           if (match != null) dayTitle = match['title'] ?? 'Activities';
        } catch (_) {}

        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: ExpansionTile(
              initiallyExpanded: i == 0,
              iconColor: AppTheme.accentTeal,
              collapsedIconColor: AppTheme.textSecondary,
              title: Text(dayKey, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              subtitle: Text(dayTitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: items.asMap().entries.map((entry) {
                      final itemIndex = entry.key;
                      final itemName = entry.value.toString();
                      final isPacked = _packedItems[dayKey]?.contains(itemIndex) ?? false;
                      
                      return GestureDetector(
                        onTap: () => _toggleItem(dayKey, itemIndex),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 22, height: 22,
                                decoration: BoxDecoration(
                                  color: isPacked ? AppTheme.accentTeal : Colors.transparent,
                                  border: Border.all(color: isPacked ? AppTheme.accentTeal : AppTheme.textSecondary.withValues(alpha: 0.5), width: 1.5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: isPacked ? const Icon(LucideIcons.check, color: AppTheme.primaryBlack, size: 14) : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 250),
                                  style: TextStyle(
                                    color: isPacked ? AppTheme.textSecondary.withValues(alpha: 0.4) : AppTheme.textPrimary,
                                    fontSize: 14,
                                    decoration: isPacked ? TextDecoration.lineThrough : TextDecoration.none,
                                    decorationColor: AppTheme.textSecondary.withValues(alpha: 0.4),
                                    decorationThickness: 2,
                                  ),
                                  child: Text(itemName),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: Duration(milliseconds: 10 + (50 * i))).slideX(begin: 0.05, end: 0),
          ),
        );
      },
    );
  }
}
