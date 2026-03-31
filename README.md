<p align="center">
	<img src="assets/images/app_logo.png" alt="LuxeVoyage Logo" width="280" />
</p>

<h1 align="center">LuxeVoyage</h1>

<p align="center">
	AI-native smart travel companion for premium discovery, planning, and memory keeping.
</p>

<p align="center">
	<img src="https://cdn.simpleicons.org/flutter/02569B" alt="Flutter" width="34" height="34" style="background:#F3F8FF;padding:10px;border-radius:10px;margin:4px;" />
	<img src="https://cdn.simpleicons.org/dart/0175C2" alt="Dart" width="34" height="34" style="background:#EEF8FF;padding:10px;border-radius:10px;margin:4px;" />
	<img src="https://cdn.simpleicons.org/firebase/FFCA28" alt="Firebase" width="34" height="34" style="background:#FFF8E6;padding:10px;border-radius:10px;margin:4px;" />
	<img src="https://cdn.simpleicons.org/googlemaps/34A853" alt="Google Maps" width="34" height="34" style="background:#EEFFF3;padding:10px;border-radius:10px;margin:4px;" />
	<img src="https://cdn.simpleicons.org/googlegemini/1A73E8" alt="Gemini" width="34" height="34" style="background:#EDF3FF;padding:10px;border-radius:10px;margin:4px;" />
</p>

---

## Why LuxeVoyage

LuxeVoyage is not a standard travel app. It blends an editorial-grade interface with real-time AI concierge features, itinerary generation, map intelligence, and memory tools into one cohesive experience.

The product focus is simple:

- Discover faster with AI and map-native search.
- Plan deeply with premium multi-day itineraries.
- Capture and relive journeys through Memory Vault and AI journals.

---

## Feature Showcase

### AI Suite

- AI Concierge chat powered by Gemini.
- Structured itinerary generation with luxury tier selection.
- Blind Trip Roulette for surprise destination planning.
- Travel Persona and vibe-based destination matching.
- AI-powered audio guide script generation.

### Discovery and Navigation

- Google Maps-powered destination search and marker exploration.
- Reverse geocoding for pinned locations.
- Curated experiences feed and trending destination surfacing.
- Quick action routing for hotels, flights, experiences, and guides.

### Trip Operations

- Multi-step planner flow for destination, duration, and travel style.
- Collections to manage saved itineraries by status.
- Cost Diary for budget breakdown and expense logging.
- Digital Passport interaction flow.

### Memory Layer

- Memory Vault with image upload to Firebase Storage.
- Firestore-backed memory and journal streams.
- AI Trip Journal generation from selected moments.

---

## Product Surfaces (Implemented Screens)

- Splash and authentication
- Home dashboard
- Map search and pin exploration
- Trip planner and itinerary result flows
- Swipe Match, Mood Board, Blind Trip flows
- Audio Guide player
- Memory Vault and Trip Journal
- Traveller Feed
- Collections
- Cost Diary
- Digital Passport
- Profile

---

## Architecture Snapshot

```text
lib/
	core/
		services/      # auth, firestore, gemini, places, weather, unsplash
		theme/         # app theme + vibe theme extension
		widgets/       # shared reusable UI components
	features/
		auth/
		home/
		map/
		planner/
		chat/
		vault/
		experiences/
		collections/
		costs/
		gamification/
		profile/
		splash/
		audio_guide/
		place_detail/
		vibe_engine/
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter, Dart |
| State Management | Riverpod |
| Backend | Firebase Auth, Cloud Firestore, Firebase Storage |
| AI | Google Gemini (`google_generative_ai`) |
| Maps and Places | Google Maps Flutter, Google Places Text Search API |
| Geolocation and Weather | Geolocator, Open-Meteo, Nominatim |
| Media and UX | Flutter TTS, Cached Network Image, Flutter Animate |

---

## Quick Start

### 1. Prerequisites

- Flutter SDK (stable)
- Dart SDK (bundled with Flutter)
- Android Studio / Xcode (for device builds)
- Firebase project with Auth, Firestore, and Storage enabled
- Google Maps Platform API key with Places API enabled
- Gemini API key

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

- Keep `android/app/google-services.json` in place.
- Ensure `lib/firebase_options.dart` matches your Firebase project.
- For web sign-in, verify Google auth client ID in:
	- `web/index.html`
	- `lib/core/services/auth_service.dart`

### 4. Configure secrets

Add your Android Maps key to `android/local.properties`:

```properties
MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY
```

Add your AI/Places key to `lib/core/config/env.dart`:

```dart
class Env {
	static const String aiMapApiKey = 'YOUR_API_KEY';
}
```

### 5. Run the app

```bash
flutter run
```

For web:

```bash
flutter run -d chrome
```

---

## Firestore Shape (Current Usage)

```text
users/{uid}
	memories/{memoryId}
	journals/{journalId}
	itineraries/{itineraryId}
	customExperiences/{experienceId}

places/{placeId}
	reviews/{reviewId}
```

---

## Developer Commands

```bash
flutter analyze
flutter test
```

---

## Security Note

Current code reads API secrets from source/config files. For production, migrate to a secure secret strategy such as build-time variables (`--dart-define`) and CI-managed secrets. Never commit real keys.

---

## Roadmap Ideas

- Cinematic trip reveal transitions with generated share cards
- Offline memory caching and smart sync
- AI-generated post-trip recap video script
- Collaborative group planning sessions

---

## License

This project is currently private/unlicensed. Add a `LICENSE` file before public distribution.
