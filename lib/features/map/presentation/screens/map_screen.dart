import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/places_service.dart';
import '../../../experiences/presentation/screens/create_experience_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final PlacesService _placesService = PlacesService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _isLoading = false;
  int _selectedPin = 0;

  final Map<MarkerId, Marker> _markers = {};
  PlaceData? _tappedPlace;
  List<PlaceData> _searchResults = [];

  final String _mapStyle = '''
  [
    {"elementType":"geometry","stylers":[{"color":"#0a0f1a"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#64748b"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#0a0f1a"}]},
    {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#f59e0b"}]},
    {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#94a3b8"}]},
    {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#111827"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1e293b"}]},
    {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#0f172a"}]},
    {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#64748b"}]},
    {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#1e293b"}]},
    {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#f59e0b"}]},
    {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#111827"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0c1929"}]},
    {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#334155"}]}
  ]
  ''';

  void _onMapTap(LatLng position) async {
    final markerId = MarkerId('tapped_${DateTime.now().millisecondsSinceEpoch}');
    setState(() {
      _markers[markerId] = Marker(
        markerId: markerId,
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      );
      _tappedPlace = PlaceData(
        id: markerId.value, name: 'Pinned Location',
        location: '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        formattedAddress: 'Loading address...',
        latLng: position, rating: 0,
      );
    });

    // Reverse geocode
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json&accept-language=en';
      final res = await http.get(Uri.parse(url), headers: {'User-Agent': 'LuxeVoyage/1.0'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final addr = data['display_name'] ?? 'Unknown';
        final name = data['address']?['city'] ?? data['address']?['town'] ?? data['address']?['village'] ?? 'Pinned Location';
        if (mounted) {
          setState(() {
            _tappedPlace = PlaceData(
              id: markerId.value, name: name,
              location: addr.toString().length > 60 ? '${addr.toString().substring(0, 60)}...' : addr.toString(),
              formattedAddress: addr.toString(),
              latLng: position, rating: 0,
            );
          });
        }
      }
    } catch (_) {}
  }

  void _onMapLongPress(LatLng position) async {
    // Show a loading indicator on the map (or ripple)
    HapticFeedback.heavyImpact();
    
    // Reverse geocode to get a good place name to pre-fill
    String prefilledLocation = 'Pinned Location';
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json&accept-language=en';
      final res = await http.get(Uri.parse(url), headers: {'User-Agent': 'LuxeVoyage/1.0'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        prefilledLocation = data['name'] ?? 
                            data['address']?['city'] ?? 
                            data['address']?['town'] ?? 
                            data['address']?['village'] ?? 
                            data['display_name']?.split(',').first ?? 
                            'Pinned Location';
      }
    } catch (_) {}

    if (mounted) {
      Navigator.push(context, PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => CreateExperienceScreen(
          prefilledLocation: prefilledLocation,
          latitude: position.latitude,
          longitude: position.longitude,
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ));
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) return;
    _searchFocus.unfocus();
    setState(() { _isLoading = true; _searchResults = []; });

    try {
      final results = await _placesService.searchPlaces(query);
      if (results.isNotEmpty && mounted) {
        _markers.clear();
        for (int i = 0; i < results.length; i++) {
          final markerId = MarkerId(results[i].id);
          _markers[markerId] = Marker(
            markerId: markerId,
            position: results[i].latLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              i == 0 ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueAzure,
            ),
            onTap: () => setState(() { _selectedPin = i; _tappedPlace = results[i]; }),
          );
        }
        setState(() {
          _searchResults = results;
          _selectedPin = 0;
          _tappedPlace = results[0];
          _isLoading = false;
        });
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(results[0].latLng, 13));
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Full map
            GoogleMap(
              initialCameraPosition: const CameraPosition(target: LatLng(48.8584, 2.2945), zoom: 5),
              markers: Set<Marker>.of(_markers.values),
              onMapCreated: (c) {
                _mapController = c;
                _mapController?.setMapStyle(_mapStyle);
              },
              onTap: _onMapTap,
              onLongPress: _onMapLongPress,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),

            // Search bar
            Positioned(
              top: 12, left: 16, right: 16,
              child: _buildSearchBar(),
            ),

            // Zoom + locate buttons
            Positioned(
              bottom: _tappedPlace != null ? 140 : 24,
              right: 16,
              child: Column(
                children: [
                  _mapBtn(LucideIcons.plus, () => _mapController?.animateCamera(CameraUpdate.zoomIn())),
                  const SizedBox(height: 8),
                  _mapBtn(LucideIcons.minus, () => _mapController?.animateCamera(CameraUpdate.zoomOut())),
                  const SizedBox(height: 8),
                  _mapBtn(LucideIcons.navigation, () {
                    if (_tappedPlace != null) {
                      _mapController?.animateCamera(CameraUpdate.newLatLng(_tappedPlace!.latLng));
                    }
                  }),
                ],
              ),
            ),

            // Place card
            if (_tappedPlace != null)
              Positioned(
                bottom: 16, left: 16, right: 16,
                child: _buildPlaceCard(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Icon(LucideIcons.search, color: AppTheme.accentAmber, size: 19),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              textInputAction: TextInputAction.search,
              onSubmitted: _searchPlaces,
              decoration: InputDecoration(
                hintText: "Search destinations, hotels...",
                hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.4), fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              ),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentAmber)),
            )
          else if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.x, color: AppTheme.textSecondary, size: 16),
              onPressed: () { _searchController.clear(); setState(() {}); },
            )
          else
            const SizedBox(width: 14),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.15, end: 0);
  }

  Widget _buildPlaceCard() {
    final place = _tappedPlace!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.accentAmber.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.accentAmber.withOpacity(0.15), AppTheme.accentTeal.withOpacity(0.08)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(LucideIcons.mapPin, color: AppTheme.accentAmber, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(place.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(place.location, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (place.rating > 0) ...[
                  const SizedBox(height: 5),
                  Row(children: [
                    const Icon(Icons.star_rounded, color: AppTheme.accentAmber, size: 14),
                    const SizedBox(width: 3),
                    Text(place.rating.toStringAsFixed(1), style: const TextStyle(color: AppTheme.accentAmber, fontSize: 13, fontWeight: FontWeight.w700)),
                  ]),
                ],
              ],
            ),
          ),
          // Close
          GestureDetector(
            onTap: () => setState(() => _tappedPlace = null),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.x, color: AppTheme.textSecondary, size: 16),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.15, end: 0);
  }

  Widget _mapBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 10)],
        ),
        child: Icon(icon, color: AppTheme.accentAmber, size: 18),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }
}
