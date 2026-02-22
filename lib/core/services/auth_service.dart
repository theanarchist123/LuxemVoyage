import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Web needs the OAuth 2.0 Web Client ID from Firebase Console
  // (Firebase Console → Authentication → Sign-in method → Google → Web SDK configuration)
  static const String _webClientId =
      '204872344046-oh1ssoh53l54t770tjbn1mnl0q51mqcm.apps.googleusercontent.com';

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _webClientId : null,
    scopes: ['email', 'profile'],
  );

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Email/Password Sign Up
  Future<UserCredential?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Create Firestore user document
    await _db.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'name': name,
      'email': email,
      'profileImage': '',
      'role': 'user',
      'travelPreferences': {},
      'savedDestinations': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return cred;
  }

  /// Email/Password Login
  Future<UserCredential?> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      UserCredential userCred;

      if (kIsWeb) {
        // On web, use Firebase's built-in popup flow
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        userCred = await _auth.signInWithPopup(provider);
      } else {
        // On Android/iOS, use google_sign_in package
        final GoogleSignInAccount? gUser = await _googleSignIn.signIn();
        if (gUser == null) return null;

        final GoogleSignInAuthentication gAuth = await gUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken,
          idToken: gAuth.idToken,
        );
        userCred = await _auth.signInWithCredential(credential);
      }

      // Upsert user in Firestore
      final docSnap = await _db.collection('users').doc(userCred.user!.uid).get();
      if (!docSnap.exists) {
        await _db.collection('users').doc(userCred.user!.uid).set({
          'uid': userCred.user!.uid,
          'name': userCred.user!.displayName ?? 'Traveller',
          'email': userCred.user!.email ?? '',
          'profileImage': userCred.user!.photoURL ?? '',
          'role': 'user',
          'travelPreferences': {},
          'savedDestinations': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return userCred;
    } catch (e) {
      debugPrint('Google Sign In Error: $e');
      rethrow; // Let the UI show the real error
    }
  }

  /// Sign Out
  Future<void> signOut() async => _auth.signOut();
}
