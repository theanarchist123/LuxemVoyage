import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'firestore_service.dart';

class PlaceData {
  final String id;
  final String name;
  final String location; // Address
  final String formattedAddress;
  final LatLng latLng;
  final double rating;
  final String? photoReference;

  PlaceData({
    required this.id,
    required this.name,
    required this.location,
    required this.formattedAddress,
    required this.latLng,
    required this.rating,
    this.photoReference,
  });

  factory PlaceData.fromJson(Map<String, dynamic> json) {
    String? photoRef;
    if (json['photos'] != null && (json['photos'] as List).isNotEmpty) {
      photoRef = json['photos'][0]['photo_reference'];
    }

    return PlaceData(
      id: json['place_id'] ?? '',
      name: json['name'] ?? '',
      location: json['vicinity'] ?? json['formatted_address'] ?? 'Unknown Location',
      formattedAddress: json['formatted_address'] ?? '',
      latLng: LatLng(
        json['geometry']['location']['lat'],
        json['geometry']['location']['lng'],
      ),
      rating: (json['rating'] ?? 0.0).toDouble(),
      photoReference: photoRef,
    );
  }
}

class PlacesService {
  // Uses the same API key as defined in AndroidManifest.xml
  static const String _apiKey = 'AIzaSyBItX7wzj21AldWuL1xiUoZr36JzE67chU';
  final FirestoreService _firestoreService = FirestoreService();

  Future<List<PlaceData>> searchPlaces(String query) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$query&key=$_apiKey'
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List results = jsonResponse['results'];
      
      final places = results.map((e) => PlaceData.fromJson(e)).toList();

      // Caching logic: save the first 5 results to Firestore to save costs later
      for (var place in places.take(5)) {
        await _firestoreService.cachePlace(place);
      }

      return places;
    } else {
      throw Exception('Failed to load places');
    }
  }

  /// Returns the URL to load a place photo given its photo reference.
  String getPhotoUrl(String photoReference, {int maxWidth = 400}) {
    return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=$maxWidth&photo_reference=$photoReference&key=$_apiKey';
  }
}
