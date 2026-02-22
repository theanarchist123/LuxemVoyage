import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /// Android config — values from google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAV1FZs5uTcoHCxtb7m7Z6FLTshL4OmsnU',
    appId: '1:204872344046:android:3f77787aa596eff0d26eff',
    messagingSenderId: '204872344046',
    projectId: 'luxevoyage-a5033',
    storageBucket: 'luxevoyage-a5033.firebasestorage.app',
  );

  /// Web config — from Firebase Console → Project Settings → Your Apps → Web
  /// TODO: Replace these values with your actual web app config from Firebase Console
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAV1FZs5uTcoHCxtb7m7Z6FLTshL4OmsnU',
    appId: '1:204872344046:web:116c3f673fdd9e43d26eff',
    messagingSenderId: '204872344046',
    projectId: 'luxevoyage-a5033',
    storageBucket: 'luxevoyage-a5033.firebasestorage.app',
    authDomain: 'luxevoyage-a5033.firebaseapp.com',
  );
}
