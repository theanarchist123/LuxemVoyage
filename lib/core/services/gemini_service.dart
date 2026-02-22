import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // ⚠️  For production: move this key to a Cloud Function to avoid APK exposure.
  static const String _apiKey = 'AIzaSyAoOy2riUPF4CkFTpoPYxjuIMI0rDN0oGE';

  final GenerativeModel _chatModel = GenerativeModel(
    model: 'gemini-3-flash-preview',
    apiKey: _apiKey,
    systemInstruction: Content.system(
      'You are an elite luxury travel concierge for LuxeVoyage. '
      'Respond in a refined, knowledgeable, and helpful tone. '
      'Provide curated, exclusive travel recommendations.',
    ),
  );

  final GenerativeModel _plannerModel = GenerativeModel(
    model: 'gemini-3-flash-preview',
    apiKey: _apiKey,
    generationConfig: GenerationConfig(responseMimeType: 'application/json'),
  );

  /// AI Travel Chat
  Future<String> chat(String userMessage) async {
    final response = await _chatModel.generateContent([Content.text(userMessage)]);
    return response.text ?? 'I\'m sorry, I had trouble understanding that.';
  }

  /// AI Itinerary Generator — returns a structured JSON itinerary
  Future<String> generateItinerary({
    required String destination,
    required int days,
    required String tier,
  }) async {
    final prompt = '''
Generate a $days-day luxury travel itinerary for $destination.
Luxury tier: $tier.
Return a JSON array where each item has: { "day": number, "title": string, "activities": string[], "hotel": string, "dining": string }
''';
    final response = await _plannerModel.generateContent([Content.text(prompt)]);
    return response.text ?? '[]';
  }

  /// AI Recommendation Engine
  Future<String> getRecommendations(Map<String, dynamic> preferences) async {
    final prompt = '''
Based on these travel preferences: $preferences
Recommend 5 luxury destinations with brief descriptions.
Return JSON: [{ "name": string, "country": string, "reason": string, "bestFor": string }]
''';
    final response = await _plannerModel.generateContent([Content.text(prompt)]);
    return response.text ?? '[]';
  }

  /// AI Audio Guide Script Generator
  Future<String> generateAudioGuideScript({required String placeName}) async {
    final prompt = '''
You are an expert museum and travel audio guide narrator with an elegant, captivating voice.
Write a private audio guide script for: "$placeName".

Requirements:
- Length: approximately 250–350 words (2–3 minutes spoken)
- Start with a vivid, atmospheric opening sentence that sets the scene
- Include: history, architectural highlights, cultural significance, hidden details most visitors miss
- Use natural spoken language — no bullet points, no headers, just flowing paragraphs
- End with an evocative closing that leaves the listener with a sense of wonder
- Tone: refined, intimate, like a world-class private guide whispering in your ear

Write only the script itself — no title, no preamble, just the narration.
''';
    final response = await _chatModel.generateContent([Content.text(prompt)]);
    return response.text ?? 'Welcome to $placeName. This is a remarkable place with a rich history and cultural significance that continues to captivate visitors from around the world.';
  }

  /// Custom Experience Audio Guide — blends user's personal story with location history
  Future<String> generateCustomAudioScript({
    required String placeName,
    required String userStory,
    String? locationHint,
  }) async {
    final prompt = '''
You are a world-class audio guide narrator crafting a deeply personal experience.
Location: "$placeName"${locationHint != null ? ' ($locationHint)' : ''}
The traveller's personal story about this place: "$userStory"

Write a private audio guide script that:
- Weaves the traveller's personal story INTO the historical and cultural narrative
- Opens with the traveller's moment at this place, then expands into the location's story
- Length: 200–280 words — intimate and personal
- Tone: warm, cinematic, deeply personal — like a letter to their future self read aloud
- End by bringing it back to why THIS place will always belong to them

Write only the narration — no titles, no preamble.
''';
    final response = await _chatModel.generateContent([Content.text(prompt)]);
    return response.text ?? 'This place holds a story only you know. Let it speak.';
  }

  /// Mood Board Destination Matcher
  Future<Map<String, dynamic>> matchDestinationFromMoods(List<String> moods) async {
    final prompt = '''
A traveller has chosen these mood aesthetics: ${moods.join(', ')}.
Based on their vibe, recommend ONE perfect destination.

Return JSON with exactly these keys:
{
  "destination": "City, Country",
  "tagline": "One evocative sentence (max 12 words)",
  "why": "2-3 sentence explanation of why this destination matches their soul",
  "imageQuery": "A short search-friendly description of the destination for an image",
  "highlights": ["highlight1", "highlight2", "highlight3"]
}
''';
    final response = await _plannerModel.generateContent([Content.text(prompt)]);
    final text = response.text ?? '{}';
    final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
    try {
      return Map<String, dynamic>.from(jsonDecode(clean));
    } catch (_) {
      return {'destination': 'Santorini, Greece', 'tagline': 'Where the sun kisses the sea', 'why': 'Your chosen moods speak of beauty, serenity, and timeless elegance.', 'imageQuery': 'Santorini caldera sunset', 'highlights': ['Caldera views', 'White-washed villages', 'Volcanic beaches']};
    }
  }

  /// AI Trip Journal Generator — turns a list of photo descriptions into a cohesive travel story
  Future<String> generateTravelJournal(List<String> photoDescriptions) async {
    if (photoDescriptions.isEmpty) return 'No memories selected to tell a story.';

    final prompt = '''
You are an award-winning travel writer crafting a deeply personal, evocative journal entry.
The user has provided descriptions of photos they took on their trip:
${photoDescriptions.map((d) => '- $d').join('\n')}

Write a cohesive, beautiful story (300-400 words) that ties these moments together into a narrative.
- Tone: Nostalgic, poetic, and intimate
- Make it flow like a memory — not just a list of what happened, but how it felt
- Use sensory details (light, sound, texture)
- Do not use markdown headers or bullet points. Just beautifully written paragraphs.

Write only the story itself.
''';
    final response = await _chatModel.generateContent([Content.text(prompt)]);
    return response.text ?? 'These moments weave together a beautiful tapestry of memories. Each photo captures a piece of the journey that will be cherished forever.';
  }

  /// AI Packing Intelligence — Generates a day-by-day packing list based on the itinerary
  Future<Map<String, dynamic>> generatePackingList(String destination, List<dynamic> itinerary) async {
    final prompt = '''
You are an expert travel concierge. Based on this itinerary for $destination, generate a smart packing list.
Group the items strictly by DAY (Day 1, Day 2, etc.), based ONLY on the activities planned for that day.
Do NOT create generic categories like "Toiletries" or "Electronics". Only list items specific to the day's events.

Itinerary:
${itinerary.map((day) => 'Day ${day['day']}: ${day['title']} - ${(day['activities'] as List).join(', ')}').join('\n')}

Format as a JSON object where keys are the Day number (e.g., "Day 1", "Day 2") and values are arrays of strings (the items). 
Make the items specific (e.g., "Waterproof bag, motion tablets, sunscreen SPF 50, GoPro").
Limit to 3-5 items per day.

Return ONLY the JSON object.
''';

    final response = await _plannerModel.generateContent([Content.text(prompt)]);
    final text = response.text ?? '{}';
    final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
    
    try {
      return Map<String, dynamic>.from(jsonDecode(clean));
    } catch (_) {
      // Fallback
      Map<String, dynamic> fallback = {};
      for (var day in itinerary) {
        fallback['Day ${day['day']}'] = ['Comfortable shoes', 'Camera', 'Daypack', 'Water bottle'];
      }
      return fallback;
    }
  }
}


