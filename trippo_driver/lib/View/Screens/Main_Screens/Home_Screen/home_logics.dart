import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:trippo_driver/Container/Repositories/address_parser_repo.dart';
import 'package:trippo_driver/Container/Repositories/firestore_repo.dart';
import 'package:trippo_driver/Container/utils/error_notification.dart';
import 'package:trippo_driver/View/Screens/Main_Screens/Home_Screen/home_providers.dart';

class HomeLogics {
  void getDriverLoc(BuildContext context, WidgetRef ref,
      MapController controller) async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final latLng = LatLng(pos.latitude, pos.longitude);
      controller.move(latLng, 14);
      ref.read(homeScreenDriverLocationProvider.notifier).state = latLng;

      if (context.mounted) {
        await ref
            .read(globalAddressParserProvider)
            .humanReadableAddress(pos, context, ref);
      }
    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "An Error Occurred $e");
      }
    }
  }

  void getDriverOnline(
      BuildContext context, WidgetRef ref, MapController controller) async {
    try {
      final driverLocation = ref.read(homeScreenDriverLocationProvider);
      if (driverLocation == null) return;

      ref
          .read(globalFirestoreRepoProvider)
          .setDriverLocationStatus(context, driverLocation);

      Geolocator.getPositionStream().listen((event) {
        final newLatLng = LatLng(event.latitude, event.longitude);
        ref.read(homeScreenDriverLocationProvider.notifier).state = newLatLng;
        ref
            .read(globalFirestoreRepoProvider)
            .setDriverLocationStatus(context, newLatLng);
      });

      controller.move(driverLocation, 14);

      ref.read(globalFirestoreRepoProvider).setDriverStatus(context, "Idle");
      ref.read(homeScreenIsDriverActiveProvider.notifier).state = true;
    } catch (e) {
      ErrorNotification().showError(context, "An Error Occurred $e");
    }
  }

  void getDriverOffline(BuildContext context, WidgetRef ref) async {
    try {
      ref.read(homeScreenIsDriverActiveProvider.notifier).state = false;

      ref.read(globalFirestoreRepoProvider).setDriverStatus(context, "offline");

      ref
          .read(globalFirestoreRepoProvider)
          .setDriverLocationStatus(context, null);

      await Future.delayed(const Duration(seconds: 2));

      SystemChannels.platform.invokeMethod("SystemNavigator.pop");
      if (context.mounted) {
        ErrorNotification().showSuccess(context, "You are now Offline");
      }
    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "An Error Occurred $e");
      }
    }
  }

  Future<dynamic> sendNotificationToUser(
      BuildContext context, String driverRes) async {
    try {
      await Dio().post("https://fcm.googleapis.com/fcm/send",
          options: Options(headers: {
            HttpHeaders.contentTypeHeader: "application/json",
            HttpHeaders.authorizationHeader:
                "Bearer AAAA7vDmw2Y:APA91bH44PYH1e9Idr_iOA76pQmowxa5nFZsEJ3CoxjUeAi4B9L-3GAezzskpynDU-wHYo144fCpbglxLdP6jJZUIHjKA-Q3gDiffy3OK-bWrDw7mQh2FeEwAWxEX1G4Ey_7MEkDanXs"
          }),

          data: {
            "data": {"screen": "home"},
            "notification": {
              "title": "Driver's Response",
              "status" : driverRes,
              "body":
                  " The Driver has $driverRes your request. ${driverRes == "accepted" ? "The Driver will be arriving soon." : "Sorry! The Driver is not available."}"
            },
            "to":
                "eHeH0bV9QbSMvINPFDoo9k:APA91bHrFlYWx5cnoV4cvzwLDrzG_1EYKFAzU0M0CPQyw983SubqiWALhiAVxHntXnaAiUKNPCTfXdK_Ws9LDgc9aJUT_5jvOe9CznTUMxDVFbX4YE7Iu75OMcIj4PTHLiQP0iRgCcm4"
          });
    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "$e");
      }
    }
  }
}
