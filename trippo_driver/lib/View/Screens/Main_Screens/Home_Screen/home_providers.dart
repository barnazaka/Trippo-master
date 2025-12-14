import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

final homeScreenDriverLocationProvider = StateProvider<LatLng?>((ref) {
  return null;
});

final homeScreenMainPolylinesProvider = StateProvider<List<Polyline>>((ref) {
  return [];
});

final homeScreenMainMarkersProvider = StateProvider<List<Marker>>((ref) {
  return [];
});

final homeScreenIsDriverActiveProvider = StateProvider<bool>((ref) {
  return false;
});
