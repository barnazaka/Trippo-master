import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:trippo_user/Model/driver_model.dart';
import 'package:trippo_user/View/Screens/Main_Screens/Home_Screen/home_providers.dart';

import '../utils/error_notification.dart';

final globalFirestoreRepoProvider = Provider<FirestoreRepo>((ref) {
  return FirestoreRepo();
});

class FirestoreRepo {
  FirebaseFirestore db = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  void getDriverData(
      BuildContext context, WidgetRef ref, LatLng userPos) async {
    try {
      Stream<QuerySnapshot<Map<String, dynamic>>> drivers =
          db.collection("Drivers").snapshots();

      drivers.listen((event) {
        final availableDrivers = <DriverModel>[];
        final driverMarkers = <Marker>[];
        for (var driver in event.docs) {
          final driverData = driver.data();
          final geoPoint = driverData["driverLoc"]["geopoint"] as GeoPoint;
          final driverLoc = LatLng(geoPoint.latitude, geoPoint.longitude);

          DriverModel model = DriverModel(
              driverData["Car Name"],
              driverData["Car Plate Num"],
              driverData["Car Type"],
              driverLoc,
              driverData["driverStatus"],
              driverData["email"],
              driverData["name"]);

          if (driverData["driverStatus"] == "Idle") {
            availableDrivers.add(model);
            driverMarkers.add(Marker(
              key: Key(driverData["Car Name"]),
              point: driverLoc,
              child: Image.asset(
                driverData["Car Type"] == "Car"
                    ? "assets/imgs/sedan.png"
                    : driverData["Car Type"] == "MotorCycle"
                        ? "assets/imgs/motorbike.png"
                        : "assets/imgs/suv.png",
                width: 40,
                height: 40,
              ),
            ));
          }
        }
        ref.read(homeScreenAvailableDriversProvider.notifier).state =
            availableDrivers;
        ref.read(homeScreenMainMarkersProvider.notifier).state = driverMarkers;
      });
    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "An Error Occurred $e");
      }
    }
  }

  void addUserRideRequestToDB(
      context, WidgetRef ref, String driverEmail) async {
    try {
      await db.collection(auth.currentUser!.email.toString()).add({
        "OriginLat":
            ref.read(homeScreenPickUpLocationProvider)!.locationLatitude,
        "OriginLng":
            ref.read(homeScreenPickUpLocationProvider)!.locationLongitude,
        "OriginAddress":
            ref.read(homeScreenPickUpLocationProvider)!.humanReadableAddress,
        "destinationLat":
            ref.read(homeScreenDropOffLocationProvider)!.locationLatitude,
        "destinationLng":
            ref.read(homeScreenDropOffLocationProvider)!.locationLongitude,
        "destinationAddress":
            ref.read(homeScreenDropOffLocationProvider)!.humanReadableAddress,
        "time": DateTime.now(),
        "userEmail": auth.currentUser!.email.toString(),
        "driverEmail": driverEmail
      });
    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "An Error Occurred $e");
      }
    }
  }

  void nullifyUserRides(context) async {
    try {
      var data = await db.collection(auth.currentUser!.email.toString()).get();

      for (var alldata in data.docs) {
        alldata.reference.delete();
      }
    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "An Error Occurred $e");
      }
    }
  }

  void setDriverStatus(context, String driverEmail, String driverStatus) async {
    try {
      QuerySnapshot<Map<String, dynamic>> drivers = await db
          .collection("Drivers")
          .where("email", isEqualTo: driverEmail)
          .get();

      for (var driver in drivers.docs) {
        driver.reference.update({"driverStatus": driverStatus});
      }
    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "An Error Occurred $e");
      }
    }
  }
}
