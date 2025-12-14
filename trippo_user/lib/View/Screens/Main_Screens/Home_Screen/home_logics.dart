import 'dart:io';

import 'package:elegant_notification/elegant_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart' as lottie;
import 'package:trippo_user/Container/Repositories/address_parser_repo.dart';
import 'package:trippo_user/Container/Repositories/direction_polylines_repo.dart';
import 'package:trippo_user/Container/Repositories/firestore_repo.dart';
import 'package:trippo_user/Container/utils/error_notification.dart';
import 'package:trippo_user/Model/direction_model.dart';
import 'package:trippo_user/View/Components/all_components.dart';
import 'package:trippo_user/View/Screens/Main_Screens/Home_Screen/home_providers.dart';
import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';

class HomeScreenLogics {
  void changePickUpLoc(
      BuildContext context, WidgetRef ref, MapController controller) async {
    try {
      ref.read(homeScreenDropOffLocationProvider.notifier).state = null;

      ref.read(homeScreenMainMarkersProvider.notifier).update((state) {
        state.removeWhere((element) => element.key == const Key("pickUpId"));
        state.removeWhere((element) => element.key == const Key("dropOffId"));
        return List.from(state);
      });

      ref.read(homeScreenMainPolylinesProvider.notifier).state = [];

      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      controller.move(LatLng(pos.latitude, pos.longitude), 14);
    } catch (e) {
      if (context.mounted) {
        ElegantNotification.error(
            description: Text(
          "An Error Occurred $e",
          style: const TextStyle(color: Colors.black),
        )).show(context);
      }
    }
  }

  void getUserLoc(
      BuildContext context, WidgetRef ref, MapController controller) async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      controller.move(LatLng(pos.latitude, pos.longitude), 14);

      if (context.mounted) {
        await ref
            .read(globalAddressParserProvider)
            .humanReadableAddress(pos, context, ref);
      }
      if (context.mounted) {
        ref
            .read(globalFirestoreRepoProvider)
            .getDriverData(context, ref, LatLng(pos.latitude, pos.longitude));
      }
    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "An Error Occurred $e");
      }
    }
  }

  void getAddressfromCordinates(BuildContext context, WidgetRef ref) async {
    try {
      final center = ref.read(homeScreenCameraMovementProvider);
      if (center == null) return;

      List<Placemark> placemarks =
          await placemarkFromCoordinates(center.latitude, center.longitude);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address =
            '${placemark.street}, ${placemark.locality}, ${placemark.postalCode}, ${placemark.country}';

        Direction model = Direction(
          locationLatitude: center.latitude,
          locationLongitude: center.longitude,
          humanReadableAddress: address,
        );

        ref.read(homeScreenPickUpLocationProvider.notifier).state = model;
      }
    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "An Error Occurred $e");
      }
    }
  }

  void openWhereToScreen(
      BuildContext context, WidgetRef ref, MapController controller) async {
    try {
      final dropOffLocation = ref.watch(homeScreenDropOffLocationProvider);
      final pickUpLocation = ref.watch(homeScreenPickUpLocationProvider);
      if (dropOffLocation == null || pickUpLocation == null) {
        return;
      }

      var pickUpMarker = Marker(
        key: const Key("pickUpId"),
        point:
            LatLng(pickUpLocation.locationLatitude!, pickUpLocation.locationLongitude!),
        child: const Icon(Icons.location_on, color: Colors.green),
      );

      var dropOffMarker = Marker(
        key: const Key("dropOffId"),
        point: LatLng(
            dropOffLocation.locationLatitude!, dropOffLocation.locationLongitude!),
        child: const Icon(Icons.location_on, color: Colors.red),
      );

      ref
          .read(homeScreenMainMarkersProvider.notifier)
          .update((state) => [...state, pickUpMarker, dropOffMarker]);

      ref
          .read(globalDirectionPolylinesRepoProvider)
          .setNewDirectionPolylines(ref, context, controller);


    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "An Error Occurred $e");
      }
    }
  }

  double calculateDistance(
    lat1,
    lon1,
    lat2,
    lon2,
  ) {
    double calculatedDistance = Geolocator.distanceBetween(
      lat1,
      lon1,
      lat2,
      lon2,
    );

    return calculatedDistance;
  }

  dynamic requestARide(
      size, BuildContext context, WidgetRef ref, MapController controller) {
    if (ref.watch(homeScreenDropOffLocationProvider) == null) {
      ErrorNotification().showError(context, "Please add destination first");
      return;
    }
    return showModalBottomSheet(
        context: context,
        builder: (context) {
          return Consumer(
            builder: (context, ref, child) {
              return Container(
                  width: size.width,
                  height: 400,
                  decoration: const BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.0),
                          topRight: Radius.circular(16.0))),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    child: ref.watch(homeScreenStartDriverSearch)
                        ? Column(
                            key: const Key("sec"),
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              lottie.Lottie.asset(
                                "assets/jsons/dribbble.json",
                                height: 200,
                                width: 200,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 15.0),
                                child: Text(
                                    "Waiting For Driver's Response. You will be notified about your ride's status."),
                              )
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            key: const Key("first"),
                            children: [
                              SizedBox(
                                width: size.width,
                                height: 300,
                                child: ListView.builder(
                                    itemCount: ref
                                        .read(
                                            homeScreenAvailableDriversProvider)
                                        .length,
                                    itemBuilder: (context, index) {
                                      double distanceToDriver = calculateDistance(
                                          ref
                                              .read(
                                                  homeScreenPickUpLocationProvider)!
                                              .locationLatitude,
                                          ref
                                              .read(
                                                  homeScreenPickUpLocationProvider)!
                                              .locationLongitude,
                                          ref
                                              .watch(homeScreenAvailableDriversProvider)[
                                                  index]
                                              .driverLoc
                                              .latitude,
                                          ref
                                              .watch(homeScreenAvailableDriversProvider)[
                                                  index]
                                              .driverLoc
                                              .longitude);

                                      if (distanceToDriver < 50 && index == ref.watch(homeScreenSelectedRideProvider) && ref.watch(homeScreenStartDriverSearch) ) {
                                        context.pop();
                                        sendNotificationToUserAboutDriverArrival(
                                            context);
                                      }

                                      double carType = ref
                                                  .read(homeScreenAvailableDriversProvider)[
                                                      index]
                                                  .carType ==
                                              "Car"
                                          ? 2
                                          : ref
                                                      .read(homeScreenAvailableDriversProvider)[
                                                          index]
                                                      .carType ==
                                                  "SUV"
                                              ? 3
                                              : 1;
                                      String userFare = ref.read(
                                                  homeScreenRateProvider) !=
                                              null
                                          ? (((ref.read(homeScreenRateProvider)! *
                                                      carType) *
                                                  5))
                                              .toString()
                                          : "Loading...";

                                      if (ref
                                          .read(
                                              homeScreenAvailableDriversProvider)
                                          .isEmpty) {
                                        return const Text("Loading...");
                                      }
                                      return Container(
                                        margin: const EdgeInsets.only(
                                            top: 20, right: 20, left: 20),
                                        decoration: BoxDecoration(
                                            color: ref.watch(
                                                        homeScreenSelectedRideProvider) ==
                                                    index
                                                ? Colors.blue
                                                : Colors.grey,
                                            borderRadius:
                                                BorderRadius.circular(14.0)),
                                        child: InkWell(
                                          onTap: () {
                                            ref
                                                .read(
                                                    homeScreenSelectedRideProvider
                                                        .notifier)
                                                .update((state) => index);


                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(15.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 12.0),
                                                      child: Image.asset(
                                                        ref
                                                                    .read(homeScreenAvailableDriversProvider)[
                                                                        index]
                                                                    .carType ==
                                                                "Car"
                                                            ? "assets/imgs/car.png"
                                                            : ref
                                                                        .read(homeScreenAvailableDriversProvider)[
                                                                            index]
                                                                        .carType ==
                                                                    "SUV"
                                                                ? "assets/imgs/suv.png"
                                                                : "assets/imgs/motorbike.png",
                                                        width: 60,
                                                        height: 60,
                                                      ),
                                                    ),
                                                    Column(
                                                      children: [
                                                        Text(ref
                                                            .read(homeScreenAvailableDriversProvider)[
                                                                index]
                                                            .carName),
                                                        Text(
                                                          "${(distanceToDriver / 1000).toStringAsFixed(0)} KM away.",
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall!
                                                                  .copyWith(
                                                                    fontSize:
                                                                        10,
                                                                  ),
                                                        ),
                                                        Text(
                                                          ref
                                                              .read(homeScreenAvailableDriversProvider)[
                                                                  index]
                                                              .name,
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall!
                                                                  .copyWith(
                                                                    fontSize:
                                                                        10,
                                                                  ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                Text("PKR $userFare")
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                              ),
                              InkWell(
                                onTap: ref.watch(
                                            homeScreenSelectedRideProvider) ==
                                        null
                                    ? null
                                    : () {
                                      int seletectedDriver = int.parse(ref.read(
                                            homeScreenSelectedRideProvider).toString());
                                        ref
                                            .read(homeScreenStartDriverSearch
                                                .notifier)
                                            .update((state) => true);

                                             ref
                                                .read(
                                                    globalFirestoreRepoProvider)
                                                .addUserRideRequestToDB(
                                                    context, ref, ref.read(homeScreenAvailableDriversProvider)[seletectedDriver].email);

                                        sendNotificationToDriver(context, ref);
                                      },
                                child: Components().mainButton(
                                    size,
                                    "Submit",
                                    context,
                                    ref.watch(homeScreenSelectedRideProvider) ==
                                            null
                                        ? Colors.grey
                                        : Colors.blue),
                              )
                            ],
                          ),
                  ));
            },
          );
        }).whenComplete(() {
      ref
          .watch(homeScreenSelectedRideProvider.notifier)
          .update((state) => null);
      ref.read(homeScreenStartDriverSearch.notifier).update((state) => false);
    });
  }

  Future<dynamic> sendNotificationToDriver(
      BuildContext context, WidgetRef ref) async {
    try {
      await Dio().post("https://fcm.googleapis.com/fcm/send",
          options: Options(headers: {
            HttpHeaders.contentTypeHeader: "application/json",
            HttpHeaders.authorizationHeader:
                "Bearer AAAA7vDmw2Y:APA91bH44PYH1e9Idr_iOA76pQmowxa5nFZsEJ3CoxjUeAi4B9L-3GAezzskpynDU-wHYo144fCpbglxLdP6jJZUIHjKA-Q3gDiffy3OK-bWrDw7mQh2FeEwAWxEX1G4Ey_7MEkDanXs"
          }),
          data: {
            "data": {"screen": "/navigationScreen"},
            "notification": {
              "title": "Customer Alert",
              "body":
                  "A Customer is requesting driver at ${ref.read(homeScreenPickUpLocationProvider)!.locationName.toString()} heading towards ${ref.read(homeScreenDropOffLocationProvider)!.locationName.toString()}"
            },
            "to":
                "dfPljtkfTo-uhP_KKpTKtR:APA91bGymnaMAIedOXIhSAD4gnPRU5EOfp_4pdpoM6HIbz_8L4MMCXQVpc6sfMoAPv44sLRaAjsOmqm8t7x9pk0wV27V1GhlUwDm_OP7kEIqq_VhyRKqWPaVgIOzhHsGhSkiJAsh5pC7"
          });
    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "$e");
      }
    }
  }

  Future<dynamic> sendNotificationToUserAboutDriverArrival(
      BuildContext context) async {
    try {
      await Dio().post("https://fcm.googleapis.com/fcm/send",
          options: Options(headers: {
            HttpHeaders.contentTypeHeader: "application/json",
            HttpHeaders.authorizationHeader:
                "Bearer AAAA7vDmw2Y:APA91bH44PYH1e9Idr_iOA76pQmowxa5nFZsEJ3CoxjUeAi4B9L-3GAezzskpynDU-wHYo144fCpbglxLdP6jJZUIHjKA-Q3gDiffy3OK-bWrDw7mQh2FeEwAWxEX1G4Ey_7MEkDanXs"
          }),
          data: {
            "data": {"screen": "/home"},
            "notification": {
              "title": "Driver is here",
              "body": "Be ready the Driver is just arround the corner"
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
