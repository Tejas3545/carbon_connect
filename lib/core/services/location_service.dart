import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

final locationServiceProvider = Provider((ref) => LocationService());

class LocationService {
  final _supabase = Supabase.instance.client;

  Future<void> updateUserLocation(String userId) async {
    try {
      debugPrint('Starting location update for user: $userId');
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable them in device settings.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable them in App Settings.');
      }

      debugPrint('Fetching current position...');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      String locationString = "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, 
          position.longitude
        ).timeout(const Duration(seconds: 10));
        
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final city = place.locality ?? place.subAdministrativeArea ?? '';
          final state = place.administrativeArea ?? '';
          if (city.isNotEmpty && state.isNotEmpty) {
            locationString = "$city, $state";
          } else if (city.isNotEmpty) {
            locationString = city;
          }
        }
      } catch (e) {
        debugPrint('Reverse Geocoding Failed: $e');
      }

      await _supabase.from('users').update({
        'location': locationString,
      }).eq('id', userId);
      
      debugPrint('Location Updated in DB: $locationString');
    } catch (e) {
      debugPrint('Location Update Exception: $e');
      rethrow;
    }
  }

  Future<String?> getCurrentLocationString() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    
    try {
      await updateUserLocation(user.id);
      final response = await _supabase.from('users').select('location').eq('id', user.id).single();
      return response['location'] as String?;
    } catch (e) {
      debugPrint('Error getting location string: $e');
      return null;
    }
  }
}
