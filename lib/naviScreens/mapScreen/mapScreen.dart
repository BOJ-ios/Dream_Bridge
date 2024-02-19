import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import 'dart:developer';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  static const CameraPosition initPosition = CameraPosition(
    target: LatLng(36.05, 127.75),
    zoom: 7.2,
  );

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  Set<Circle> circles = {};
  Set<Polygon> polygons = {};

  CameraPosition _currentCameraPosition = initPosition;

  Map<PolygonId,List<LatLng>> SIDO = {};
  List<Polygon> SIDOPolygon = [];
  Map<PolygonId,List<Polygon>> SIGUNGU = {};
  List<Polygon> SIGUNGUPolygon = [];

  Map<PolygonId,LatLngBounds> polyBounds = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            polylines: polylines,
            circles: circles,
            polygons: polygons,
            markers: markers,
            initialCameraPosition: initPosition,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            onTap: (LatLng latLng) async {
              final GoogleMapController controller = await _controller.future;

              // setState(() {
              //   markers.add(Marker(
              //     markerId: MarkerId(latLng.toString()),
              //     position: latLng,
              //     infoWindow: InfoWindow(title: "${latLng.latitude}/${latLng.longitude}"),
              //   ));
              //   controller.animateCamera(CameraUpdate.newLatLng(latLng));
              // });
            },
            onCameraMove: (CameraPosition position) {
              _currentCameraPosition = position;
            },
            onCameraIdle: () async {
              //showCurrentCenterPosition();
            },
          ),
          Positioned(
              bottom: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    child: const Text('시도 표시'),
                    onPressed: () async {
                      if(SIDOPolygon.isEmpty){
                        final String SIDOgeoJsonString =await  rootBundle.loadString(
                            'assets/GeoJSON/BND_SIDO_PG.json');
                        final SIDOgeoJsonData = jsonDecode(SIDOgeoJsonString);
                        for (var feature in SIDOgeoJsonData['features']) {
                          var geometry = feature['geometry'];
                          var type = geometry['type'];
                          var coordinates = geometry['coordinates'];
                          String id = feature['properties']['SIDO_CD']
                              .toString();
                          List<LatLng> poly=[];
                          if (type == 'Polygon') {
                            poly = coordinates[0].map<LatLng>((
                                coord) => LatLng(coord[1].toDouble(), coord[0].toDouble())).toList();
                            SIDOPolygon.add(Polygon(
                                polygonId: PolygonId(id),
                                points: poly,
                                fillColor: Colors.black38,
                                strokeColor: Colors.blue,
                                strokeWidth: 3,
                                zIndex:1,
                                consumeTapEvents : true,
                                onTap: () => onPolygonTapped(PolygonId(id))
                            ));
                            SIDO[PolygonId(id)] = poly;
                          } else if (type == 'MultiPolygon') {
                            Set<LatLng> allPoly ={};
                            for (var i = 0; i < coordinates.length; i++) {
                              poly = coordinates[i][0].map<LatLng>((
                                  coord) => LatLng(coord[1].toDouble(), coord[0].toDouble())).toList();
                              allPoly.addAll(poly);
                              SIDOPolygon.add(Polygon(
                                  polygonId: PolygonId("$id-$i"),
                                  points: poly,
                                  fillColor: Colors.black38,
                                  strokeColor: Colors.blue,
                                  strokeWidth: 3,
                                  consumeTapEvents : true,
                                  onTap: () =>
                                      onPolygonTapped(PolygonId(id))
                              ));
                            }
                            SIDO[PolygonId(id)] = allPoly.toList();
                          }
                        }
                      }
                      if(SIGUNGUPolygon.isEmpty){
                        final String SIGUNGUgeoJsonString =await  rootBundle.loadString(
                            'assets/GeoJSON/BND_SIGUNGU_PG.json');
                        final SIGUNGUgeoJsonData = jsonDecode(SIGUNGUgeoJsonString);

                        for (var feature in SIGUNGUgeoJsonData['features']) {
                          var geometry = feature['geometry'];
                          if (geometry != null) {
                            var type = geometry['type'];
                            var coordinates = geometry['coordinates'];
                            String id = feature['properties']['SIGUNGU_CD']
                                .toString();
                            String mainID = id.substring(0, 2);
                            List<LatLng> poly = [];
                            if (type == 'Polygon') {
                              poly = coordinates[0].map<LatLng>((coord) =>
                                  LatLng(
                                      coord[1].toDouble(), coord[0].toDouble()))
                                  .toList();
                              Polygon polygon = Polygon(
                                polygonId: PolygonId(id),
                                points: poly,
                                fillColor: Colors.black38,
                                strokeColor: Colors.blue,
                                strokeWidth: 3,
                                zIndex: 1,
                              );
                              SIGUNGUPolygon.add(polygon);

                              List<Polygon>? temp = SIGUNGU[PolygonId(mainID)];
                              if (temp != null) {
                                temp.add(polygon);
                                SIGUNGU[PolygonId(mainID)] = temp;
                              } else {
                                SIGUNGU[PolygonId(mainID)] = [polygon];
                              }
                            } else if (type == 'MultiPolygon') {
                              List<Polygon> tempPoly = [];
                              for (var i = 0; i < coordinates.length; i++) {
                                poly = coordinates[i][0].map<LatLng>((coord) =>
                                    LatLng(coord[1].toDouble(),
                                        coord[0].toDouble())).toList();
                                Polygon polygon = Polygon(
                                  polygonId: PolygonId("$id-$i"),
                                  points: poly,
                                  fillColor: Colors.black38,
                                  strokeColor: Colors.blue,
                                  strokeWidth: 3,
                                  zIndex: 1,
                                );
                                tempPoly.add(polygon);
                              }
                              SIGUNGUPolygon.addAll(tempPoly);

                              List<Polygon>? temp = SIGUNGU[PolygonId(mainID)];
                              if (temp != null) {
                                temp.addAll(tempPoly);
                                SIGUNGU[PolygonId(mainID)] = temp;
                              } else {
                                SIGUNGU[PolygonId(mainID)] = tempPoly;
                              }
                            }
                          }
                        }
                      }
                      setState(() {
                        clearMap();
                        polygons = SIDOPolygon.toSet();
                      });
                      final GoogleMapController controller = await _controller.future;
                      controller.animateCamera(CameraUpdate.newCameraPosition(initPosition));
                    },
                  ),
                ],
              )),
        ],
      ),
    );
  }

  void showCurrentCenterPosition() {
    Fluttertoast.showToast(
      msg: "Current Center: ${_currentCameraPosition.target
          .latitude}, ${_currentCameraPosition.target.longitude}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  // Method to handle polygon tap
  Future<void> onPolygonTapped(PolygonId polygonId) async {
    String id = polygonId.toString();
    if(id.contains('-')){
      polygonId = PolygonId(id.split('-')[0]);
    }
    final GoogleMapController controller = await _controller.future;

    // Calculate bounds
    if(polyBounds[polygonId] == null) {
      polyBounds[polygonId] = calculatePolygonBounds(SIDO[polygonId]!);
    }
    clearMap();
    List<Polygon>? data = SIGUNGU[polygonId];
    setState(() {
      polygons = data!.toSet();
    });
    // Animate camera
    controller.animateCamera(CameraUpdate.newLatLngBounds(polyBounds[polygonId]!, 20.0));
  }

  // Calculate the bounds from polygon points
  LatLngBounds calculatePolygonBounds(List<LatLng> polygonPoints) {
    double? north, south, east, west;
    for (final point in polygonPoints) {
      if (north == null || point.latitude > north) north = point.latitude;
      if (south == null || point.latitude < south) south = point.latitude;
      if (east == null || point.longitude > east) east = point.longitude;
      if (west == null || point.longitude < west) west = point.longitude;
    }
    return LatLngBounds(northeast: LatLng(north!, east!), southwest: LatLng(south!, west!));
  }

  clearMap() {
    polylines.clear();
    circles.clear();
    polygons.clear();
  }
}