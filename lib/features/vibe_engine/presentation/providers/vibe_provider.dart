import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/vibe_model.dart';

/// The active vibe state for the application.
class VibeNotifier extends StateNotifier<VibePayload> {
  VibeNotifier() : super(VibePayload.standard) {
    _initializeVibe();
  }

  Future<void> _initializeVibe() async {
    // In a real app, this would hit the backend API
    // e.g. final payload = await vibeRepository.fetchActiveVibe();
    await Future.delayed(const Duration(seconds: 2)); // Simulate network boot

    // --- TEST MODE ---
    // Simulating it is Holi today for demonstration purposes.
    // To see the standard theme, you would yield `VibePayload.standard`
    state = VibePayload.testHoli; 
  }

  /// Called by the "Vibe Pill" to revert to standard theme instantly.
  void clearVibe() {
    state = VibePayload.standard;
  }

  /// Just for testing - forces a specific vibe
  void setVibe(VibePayload vibe) {
    state = vibe;
  }
}

/// The provider exposing the active VibePayload to the app.
final vibeProvider = StateNotifierProvider<VibeNotifier, VibePayload>((ref) {
  return VibeNotifier();
});
