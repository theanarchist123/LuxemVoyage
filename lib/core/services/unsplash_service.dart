import 'dart:convert';
import 'package:http/http.dart' as http;

class UnsplashService {
  // ⚠️ Note: In a production app, the Access Key should be kept secure (e.g. via backend or env variables).
  // The user will need to provide their own Unsplash Access Key. For now, leaving a placeholder or using a demo key if provided later.
  static const String _accessKey = 'YOUR_UNSPLASH_ACCESS_KEY_HERE';

  Future<String?> getDestinationImageUrl(String query) async {
    // If the user hasn't provided an API key, don't even try to fetch. 
    // This saves latency and prevents 401 Unauthorized log spam.
    if (_accessKey == 'YOUR_UNSPLASH_ACCESS_KEY_HERE' || _accessKey.isEmpty) {
      return _getFallbackImage(query);
    }

    final url = Uri.parse(
      'https://api.unsplash.com/search/photos?query=${Uri.encodeComponent(query)}&orientation=landscape&per_page=1&client_id=$_accessKey'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          return data['results'][0]['urls']['regular'] as String;
        }
      }
    } catch (e) {
      print('Error fetching image from Unsplash: $e');
    }
    
    return _getFallbackImage(query);
  }

  String _getFallbackImage(String query) {
    // Use a more robust hash than simple summing
    final hash = query.hashCode.abs();
    
    // A robust list of extremely high-quality, permanent Unsplash IDs for various vibes
    final fallbackIds = [
      '1476514525535-07fb3b4ae5f1', // Lake (Nature/Boat)
      '1507525428034-b723cf961d3e', // Beach (Tropical)
      '1518684079-3c830dcef090', // Desert (Adventure)
      '1506905925346-21bda4d32df4', // Mountains (Hiking/Winter)
      '1519046904884-53103b34b206', // Palm trees (Island)
      '1499856871958-5b9627545d1a', // Paris (Architecture/City)
      '1512453979798-5ea266f8880c', // Dubai (Luxury/Neon)
      '1504150558240-6b4e7c458ee4', // Coffee (Aesthetic)
      '1515238152737-224711762c90', // Pool (Resort/Zen)
      '1551524559-8af4e6624178', // Skiing (Action)
      '1533105079780-92b9be482077', // Santorini (Culture)
      '1528360983277-13d401cdc186', // Kyoto (Zen/Temple)
    ];
    
    final selectedId = fallbackIds[hash % fallbackIds.length];
    return 'https://images.unsplash.com/photo-$selectedId?q=80&w=800&auto=format&fit=crop';
  }
}
