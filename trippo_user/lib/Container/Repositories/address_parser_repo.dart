import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trippo_user/View/Screens/Main_Screens/Home_Screen/home_providers.dart';
import '../../Model/direction_model.dart';
import '../utils/error_notification.dart';

final globalAddressParserProvider = Provider<AddressParser>((ref) {
  return AddressParser();
});

class AddressParser {
  Future<String?> humanReadableAddress(
      Position userPosition, context, WidgetRef ref) async {
    try {
      String url =
          "https://nominatim.openstreetmap.org/reverse?format=json&lat=${userPosition.latitude}&lon=${userPosition.longitude}";

      Response res = await Dio().get(url);

      if (res.statusCode == 200) {
        Direction model = Direction(
            locationLatitude: userPosition.latitude,
            locationLongitude: userPosition.longitude,
            humanReadableAddress: res.data["display_name"]);
        ref.read(homeScreenPickUpLocationProvider.notifier).update((state) => model);

        return res.data["display_name"];
      } else {
        ErrorNotification().showError(context, "Failed to get data");
        return null;
      }
    } catch (e) {
      ErrorNotification().showError(context, "An Error Occurred $e");
      return null;
    }
  }
}
