import 'package:dio/dio.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:trippo_user/Model/direction_polyline_details_model.dart';
import 'package:trippo_user/View/Screens/Main_Screens/Home_Screen/home_providers.dart';
import 'package:polyline_decode/polyline_decode.dart';

import '../utils/error_notification.dart';

final globalDirectionPolylinesRepoProvider =
    Provider<DirectionPolylines>((ref) {
  return DirectionPolylines();
});

class DirectionPolylines {
  List<LatLng> pLinesCoordinatedList = [];

  void setNewDirectionPolylines(
      WidgetRef ref, BuildContext context, MapController controller) async {
    try {
      DirectionPolylineDetails? model =
          await getDirectionsPolylines(context, ref);
      if (model == null) return;

      await calculateRideRate(context, ref, model);

      Polyline_decoder decoder = Polyline_decoder();
      List<List<double>> decodedCoordinates =
          decoder.decode(model.epoints!);

      pLinesCoordinatedList.clear();

      if (decodedCoordinates.isNotEmpty) {
        for (var point in decodedCoordinates) {
          pLinesCoordinatedList.add(LatLng(point[0], point[1]));
        }
      }

      ref.read(homeScreenMainPolylinesProvider.notifier).state = [];

      Polyline newPolyline = Polyline(
        points: pLinesCoordinatedList,
        strokeWidth: 4.0,
        color: Colors.blue,
      );

      ref
          .read(homeScreenMainPolylinesProvider.notifier)
          .update((state) => [newPolyline]);

      final pickUpLatLng = LatLng(
        ref.read(homeScreenPickUpLocationProvider)!.locationLatitude!,
        ref.read(homeScreenPickUpLocationProvider)!.locationLongitude!,
      );
      final dropOffLatLng = LatLng(
        ref.read(homeScreenDropOffLocationProvider)!.locationLatitude!,
        ref.read(homeScreenDropOffLocationProvider)!.locationLongitude!,
      );

      var bounds = LatLngBounds(pickUpLatLng, dropOffLatLng);
      controller.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));

    } catch (e) {
      ElegantNotification.error(
          description: Text(
        "An Error Occurred $e",
        style: const TextStyle(color: Colors.black),
      )).show(context);
    }
  }

  Future<DirectionPolylineDetails?> getDirectionsPolylines(
      BuildContext context, WidgetRef ref) async {
    try {
      final pickUpDestination = ref.read(homeScreenPickUpLocationProvider)!;
      final dropOffDestination = ref.read(homeScreenDropOffLocationProvider)!;

      final pickUpCoords =
          '${pickUpDestination.locationLongitude},${pickUpDestination.locationLatitude}';
      final dropOffCoords =
          '${dropOffDestination.locationLongitude},${dropOffDestination.locationLatitude}';

      String url =
          "http://router.project-osrm.org/route/v1/driving/$pickUpCoords;$dropOffCoords?overview=full&geometries=polyline";

      Response res = await Dio().get(url);

      if (res.statusCode == 200) {
        DirectionPolylineDetails model = DirectionPolylineDetails(
          epoints: res.data["routes"][0]["geometry"],
          distanceValue: res.data["routes"][0]["distance"],
          durationValue: res.data["routes"][0]["duration"],
        );
        return model;
      } else {
        ErrorNotification().showError(context, "Failed to get data");
        return null;
      }
    } catch (e) {
      ErrorNotification().showError(context, "An Error Occurred $e");
      return null;
    }
  }

  Future<void> calculateRideRate(BuildContext context, WidgetRef ref,
      DirectionPolylineDetails model) async {
    try {
      double travelFarePerMin = (model.durationValue! / 60) * 0.1;
      double distanceFarePerKM = (model.distanceValue! / 1000) * 0.1;

      double totalFare = travelFarePerMin + distanceFarePerKM;

      ref
          .read(homeScreenRateProvider.notifier)
          .update((state) => double.parse(totalFare.toStringAsFixed(2)));
    } catch (e) {
      ElegantNotification.error(
          description: Text(
        "An Error Occurred $e",
        style: const TextStyle(color: Colors.black),
      )).show(context);
    }
  }
}
