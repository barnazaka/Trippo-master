import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:trippo_driver/Container/Repositories/firestore_repo.dart';
import 'package:trippo_driver/Container/utils/firebase_messaging.dart';
import 'package:trippo_driver/View/Screens/Main_Screens/Home_Screen/home_logics.dart';
import 'package:trippo_driver/View/Screens/Main_Screens/Home_Screen/home_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final MapController mapController = MapController();

  @override
  void initState() {
    super.initState();
    MessagingService().init(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HomeLogics().getDriverLoc(context, ref, mapController);
      ref.read(globalFirestoreRepoProvider).getDriverDetails(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.sizeOf(context);
    final driverLocation = ref.watch(homeScreenDriverLocationProvider);

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
                  initialCenter: driverLocation ?? const LatLng(0.0, 0.0),
                  initialZoom: 14,
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
              if (!ref.watch(homeScreenIsDriverActiveProvider))
                Container(
                  height: size.height,
                          width: size.width,
                          color: Colors.black54),
                  Positioned(
                      top: !ref.watch(homeScreenIsDriverActiveProvider)
                          ? size.height * 0.45
                          : 45,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: () {
                              if (!ref
                                  .watch(homeScreenIsDriverActiveProvider)) {
                                HomeLogics()
                                    .getDriverOnline(context, ref, controller!);
                              } else {
                                HomeLogics().getDriverOffline(context, ref);
                              }
                            },
                            child: Container(
                              alignment: Alignment.center,
                              height: 45,
                              width: 200,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: Colors.blue),
                              child: !ref
                                      .watch(homeScreenIsDriverActiveProvider)
                                  ? const Text("You are Offline")
                                  : const Icon(Icons.phonelink_ring_outlined,
                                      color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ))
                ],
              ))),
    );
  }
}
