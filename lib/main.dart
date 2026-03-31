import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/vibe_theme_extension.dart';
import 'features/vibe_engine/presentation/providers/vibe_provider.dart';
import 'features/splash/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: LuxeVoyageApp()));
}

class LuxeVoyageApp extends ConsumerWidget {
  const LuxeVoyageApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the vibe state
    final activeVibe = ref.watch(vibeProvider);

    // 2. Generate the dynamic Theme Extension
    final vibeExtension = VibeThemeExtension.fromPayload(activeVibe);

    return MaterialApp(
      title: 'LuxeVoyage',
      debugShowCheckedModeBanner: false,
      // 3. Inject it into the global theme
      theme: AppTheme.getTheme(vibeExtension: vibeExtension),
      home: const SplashScreen(),
    );
  }
}

