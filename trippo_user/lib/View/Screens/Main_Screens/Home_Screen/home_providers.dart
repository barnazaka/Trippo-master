import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:trippo_user/Model/driver_model.dart';

import '../../../../Model/direction_model.dart';

final homeScreenCameraMovementProvider = StateProvider<LatLng?>((ref) {
  return null;
});
final homeScreenPickUpLocationProvider = StateProvider<Direction?>((ref) {
  return null;
});
final homeScreenDropOffLocationProvider = StateProvider<Direction?>((ref) {
  return null;
});
final homeScreenSelectedRideProvider = StateProvider<int?>((ref) {
  return null;
});
final homeScreenStartDriverSearch = StateProvider<bool>((ref) {
  return false;
});
final homeScreenRateProvider = StateProvider<double?>((ref) {
  return null;
});

final homeScreenAvailableDriversProvider = StateProvider<List<DriverModel>>((ref) {
  return [];
});

final homeScreenAddressProvider = StateProvider<String?>((ref) {
  return null;
});

final homeScreenMainPolylinesProvider = StateProvider<List<Polyline>>((ref) {
  return [];
});

final homeScreenMainMarkersProvider = StateProvider<List<Marker>>((ref) {
  return [];
});
