import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/vibe_provider.dart';

class VibePill extends ConsumerWidget {
  const VibePill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeVibe = ref.watch(vibeProvider);

    // Don't show the pill if no vibe is active
    if (!activeVibe.isVibeActive) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _showVibeDetails(context, ref, activeVibe.eventName),
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: AppTheme.glassDecoration(
          borderRadius: 30,
          opacity: 0.15,
          borderColor: activeVibe.primaryColor?.withValues(alpha: 0.5) ?? Colors.white24,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              activeVibe.greetingText.isNotEmpty ? activeVibe.greetingText : '🎉 Celebrating ${activeVibe.eventName}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  void _showVibeDetails(BuildContext context, WidgetRef ref, String eventName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.glassCardDecoration(
            borderRadius: 32,
          ).copyWith(
            color: AppTheme.surfaceDark,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Exploring a New Vibe',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'The app is currently themed for $eventName. We update the look of LuxeVoyage for special global and cultural events to keep your experience magical.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ref.read(vibeProvider.notifier).clearVibe();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Return to Classic Theme'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
