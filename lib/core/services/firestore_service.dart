import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Places ──────────────────────────────────────────────

  /// Fetch paginated places, optionally filtered by category
  Stream<QuerySnapshot> getPlaces({String? category, int limit = 10}) {
    Query query = _db.collection('places').orderBy('rating', descending: true).limit(limit);
    if (category != null) query = query.where('category', isEqualTo: category);
    return query.snapshots();
  }

  /// Get a single place document
  Future<DocumentSnapshot> getPlace(String placeId) =>
      _db.collection('places').doc(placeId).get();

  /// Cache a place from the Places API to Firestore
  Future<void> cachePlace(dynamic placeData) async {
    final docRef = _db.collection('places').doc(placeData.id);
    final docSnap = await docRef.get();
    
    // Only cache if it doesn't exist to save writes, or if you want to implement TTL
    if (!docSnap.exists) {
      await docRef.set({
        'id': placeData.id,
        'name': placeData.name,
        'location': placeData.location,
        'latitude': placeData.latLng.latitude,
        'longitude': placeData.latLng.longitude,
        'rating': placeData.rating,
        'photoReference': placeData.photoReference,
        'cachedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ── Reviews ─────────────────────────────────────────────

  /// Add a review to a place
  Future<void> addReview(String placeId, Map<String, dynamic> review) =>
      _db.collection('places').doc(placeId).collection('reviews').add(review);

  // ── Memories ────────────────────────────────────────────

  /// Stream of user memories ordered by date
  Stream<QuerySnapshot> getMemories(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('memories')
      .orderBy('createdAt', descending: true)
      .snapshots();

  /// Add a memory
  Future<void> addMemory(String uid, Map<String, dynamic> memory) =>
      _db.collection('users').doc(uid).collection('memories').add(memory);

  // ── Itineraries ─────────────────────────────────────────

  Stream<QuerySnapshot> getItineraries(String uid) => _db
      .collection('users').doc(uid).collection('itineraries')
      .orderBy('createdAt', descending: true).snapshots();

  Future<void> saveItinerary(String uid, Map<String, dynamic> itinerary) =>
      _db.collection('users').doc(uid).collection('itineraries').add(itinerary);

  /// Delete an itinerary
  Future<void> deleteItinerary(String uid, String itineraryId) =>
      _db.collection('users').doc(uid).collection('itineraries').doc(itineraryId).delete();

  /// Update itinerary status: 'dreaming' | 'planning' | 'completed'
  Future<void> updateItineraryStatus(String uid, String itineraryId, String status) =>
      _db.collection('users').doc(uid).collection('itineraries').doc(itineraryId)
          .update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});

  // ── Custom Experiences ───────────────────────────────────

  Stream<QuerySnapshot> getCustomExperiences(String uid) => _db
      .collection('users').doc(uid).collection('customExperiences')
      .orderBy('createdAt', descending: true).snapshots();

  Future<void> saveCustomExperience(String uid, Map<String, dynamic> experience) =>
      _db.collection('users').doc(uid).collection('customExperiences').add(experience);

  // ── Saved Destinations ───────────────────────────────────

  Future<void> saveDestination(String uid, String placeId) =>
      _db.collection('users').doc(uid).update({
        'savedDestinations': FieldValue.arrayUnion([placeId]),
      });

  Future<void> removeDestination(String uid, String placeId) =>
      _db.collection('users').doc(uid).update({
        'savedDestinations': FieldValue.arrayRemove([placeId]),
      });

  // ── AI Journals ──────────────────────────────────────────

  Stream<QuerySnapshot> getJournals(String uid) => _db
      .collection('users').doc(uid).collection('journals')
      .orderBy('createdAt', descending: true).snapshots();

  Future<void> saveJournal(String uid, Map<String, dynamic> journal) =>
      _db.collection('users').doc(uid).collection('journals').add(journal);
}

