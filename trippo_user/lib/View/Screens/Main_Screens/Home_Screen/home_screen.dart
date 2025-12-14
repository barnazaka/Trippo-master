import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:trippo_user/Container/utils/firebase_messaging.dart';
import 'package:trippo_user/View/Routes/routes.dart';
import 'package:trippo_user/View/Screens/Main_Screens/Home_Screen/home_logics.dart';
import 'package:trippo_user/View/Screens/Main_Screens/Home_Screen/home_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController whereToController = TextEditingController();
  final MapController mapController = MapController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    MessagingService().init(context, ref);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HomeScreenLogics().getUserLoc(context, ref, mapController);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.sizeOf(context);
    final currentPosition = ref.watch(homeScreenPickUpLocationProvider);

    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            children: [
              FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: currentPosition != null
                      ? LatLng(currentPosition.locationLatitude!, currentPosition.locationLongitude!)
                      : const LatLng(0.0, 0.0),
                  initialZoom: 14,
                  onPositionChanged: (position, hasGesture) {
                    if (ref.read(homeScreenDropOffLocationProvider) == null) {
                      ref.read(homeScreenCameraMovementProvider.notifier).state =
                          position.center!;
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500), () {
                        HomeScreenLogics().getAddressfromCordinates(context, ref);
                      });
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  PolylineLayer(
                    polylines: ref.watch(homeScreenMainPolylinesProvider),
                  ),
                  MarkerLayer(
                    markers: ref.watch(homeScreenMainMarkersProvider),
                  ),
                ],
              ),
              if (ref.watch(homeScreenDropOffLocationProvider) == null)
                const Align(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.location_on,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              Positioned(
                bottom: 0,
                child: Container(
                  height: 320,
                  width: size.width,
                  decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20))),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 10.0),
                            child: Text(
                              "From",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Container(
                              width: size.width * 0.9,
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                  border: Border(
                                      bottom:
                                          BorderSide(color: Colors.blue))),
                              child: Row(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(right: 10.0),
                                    child: Icon(
                                      Icons.start_outlined,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  SizedBox(
                                    width: size.width * 0.7,
                                    child: Text(
                                      ref
                                              .watch(
                                                  homeScreenPickUpLocationProvider)
                                              ?.humanReadableAddress ??
                                          "Loading ...",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 10.0),
                            child: Text(
                              "To",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              await context.pushNamed(Routes().whereTo,
                                  extra: mapController);
                              if (context.mounted) {
                                HomeScreenLogics().openWhereToScreen(
                                    context, ref, mapController);
                              }
                            },
                            child: Container(
                              width: size.width * 0.9,
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                  border: Border(
                                      bottom:
                                          BorderSide(color: Colors.blue))),
                              child: Row(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(right: 10.0),
                                    child: Icon(
                                      Icons.pin_drop_outlined,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  SizedBox(
                                    width: size.width * 0.7,
                                    child: Text(
                                      ref
                                              .watch(
                                                  homeScreenDropOffLocationProvider)
                                              ?.locationName ??
                                          "Where To",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: () => HomeScreenLogics()
                                      .changePickUpLoc(
                                          context, ref, mapController),
                                  child: Container(
                                    alignment: Alignment.center,
                                    height: 50,
                                    width: size.width * 0.4,
                                    decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(14.0),
                                        color: Colors.blue),
                                    child: Text(
                                      "Change Pickup Location",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    HomeScreenLogics().requestARide(
                                        size, context, ref, mapController);
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    height: 50,
                                    width: size.width * 0.4,
                                    decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(14.0),
                                        color: Colors.orange),
                                    child: Text(
                                      "Request a Ride",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ]),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
