import 'dart:async';

import 'package:dream_bridge/naviScreens/mapScreen/polygonData.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'getCoordinatesFromAddress.dart';
import 'organization.dart';

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

  // 센터 계산을 위해서
  // Map 2개의 PolygonId는 같음
  Map<PolygonId, List<LatLng>> SIDO_Individual = {};
  Map<PolygonId, List<LatLng>> SIGUNGU_Individual = {};
  Map<PolygonId, LatLngBounds> polyBounds = {}; //계산 후 결과 저장

  //한번에 표시하기 위해
  List<Polygon> SIDO_Polygons = [];
  Map<PolygonId, List<Polygon>> SIGUNGU_Polygons = {};

  //시도군구 이름 저장
  Map<PolygonId, String> SIDOGUNGU_Name = {};

  //인구데이터
  Map<String, double> regionDetails = {};
  Map<String, double> oneParentRate = {};

  late String mainID;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

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
                      loadSIDO();
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

  Color getColor(double value) {
    double hue = (240.0 - value).clamp(0, 240).toDouble();
    // print(hue);
    // HSV 색상으로 변환하여 Flutter의 Color 객체 생성
    return HSVColor.fromAHSV(0.3, hue, 1.0, 1).toColor();
  }

  //!시군구 정보
  Future<void> getRegionDetails(String state) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref('지역/$state');

    // Realtime Database에서 시도에 해당하는 데이터 조회
    DataSnapshot snapshot = await ref.get();
    if (snapshot.exists) {
      Map<dynamic, dynamic> counties = snapshot.value as Map<dynamic, dynamic>;
      counties.forEach((countyName, countyData) {
        // 각 시군구의 '전체가구'와 '저소득한부모가구' 값 추출 및 저장
        var totalHouseholds = countyData['전체가구'] ?? 0;
        var lowIncomeSingleParentHouseholds = countyData['저소득한부모가구'] ?? 0;
        double rate = lowIncomeSingleParentHouseholds / totalHouseholds;
        // 반환할 맵에 시군구 정보 추가
        regionDetails[countyName as String] = rate;
      });
    } else {
      print('No data available.');
    }
  }

  //!시도 정보
  Future<Map<String, num>> getTotalHouseholds(String state) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref('지역/$state');

    // Realtime Database에서 시도에 해당하는 데이터 조회
    DataSnapshot snapshot = await ref.get();
    var totalHouseholdsSum = 0;
    var lowIncomeSingleParentHouseholdsSum = 0;

    if (snapshot.exists) {
      Map<dynamic, dynamic> counties = snapshot.value as Map<dynamic, dynamic>;

      counties.forEach((countyName, countyData) {
        // 각 시군구의 '전체가구'와 '저소득한부모가구' 값 더하기
        // print(countyName.toString());
        // print((countyData['전체가구'] as int).toString());
        totalHouseholdsSum += countyData['전체가구'] as int;
        lowIncomeSingleParentHouseholdsSum += countyData['저소득한부모가구'] as int;
      });
    } else {
      print('No data available.');
    }
    return {'전체가구': totalHouseholdsSum, '저소득한부모가구': lowIncomeSingleParentHouseholdsSum};
  }

  Future<void> loadSIDO() async {
    if (SIDO_Polygons.isEmpty) {
      DatabaseReference starCountRef = FirebaseDatabase.instance.ref("polygonData/kr/SIDO/features");
      DataSnapshot snapshot = await starCountRef.get(); //비동기

      List<String> names = [];
      final data = snapshot.value;
      if (data != null && data is List<dynamic>) {
        List<GeoFeature> geoData = data.map<GeoFeature>((item) {
          final Map<String, dynamic> map = Map<String, dynamic>.from(item);
          return GeoFeature.fromJson(map);
        }).toList();

        for (var feature in geoData) {
          String id = feature.properties.sidoCd ?? "null";
          String name = feature.properties.sidoNm ?? "null";

          //! 시군구
          await getRegionDetails(name);

          //! 시도
          var sidodata = await getTotalHouseholds(name);
          double rate = sidodata["저소득한부모가구"]! / sidodata["전체가구"]!;

          oneParentRate[name] = rate;
        }
        var sortedEntries = oneParentRate.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
        Map<String, int> nameRank = {};
        for (var i = 0; i < sortedEntries.length; i++) {
          nameRank[sortedEntries[i].key] = i.toInt();
        }
        print(oneParentRate);
        print(nameRank);

        for (var feature in geoData) {
          var geometry = feature.geometry;
          var type = geometry.type;
          var coordinates = geometry.coordinates;
          String id = feature.properties.sidoCd ?? "null";
          String name = feature.properties.sidoNm ?? "null";
          SIDOGUNGU_Name[PolygonId(id)] = name;

          List<LatLng> allCoordinates = [];
          Polygon polygon;

          Color color = getColor((nameRank[name]! + 1) * 14);
          // print('$name $rate $regionColor');
          if (type == 'Polygon') {
            allCoordinates = _convertToLatLngList(coordinates[0][0]);
            polygon = createPolygon(PolygonId(id), allCoordinates, 1, () => onSIDOPolygonTapped(PolygonId(id)), color);
            SIDO_Polygons.add(polygon);
          } else if (type == 'MultiPolygon') {
            for (var i = 0; i < coordinates.length; i++) {
              List<LatLng> tempCoordinates = _convertToLatLngList(coordinates[i][0]);
              allCoordinates.addAll(tempCoordinates);
              polygon = createPolygon(PolygonId("$id-$i"), tempCoordinates, 0, () => onSIDOPolygonTapped(PolygonId(id)), color);
              SIDO_Polygons.add(polygon);
            }
          }
          SIDO_Individual[PolygonId(id)] = allCoordinates;
        }
      }
    }
    setState(() {
      clearMap();
      polygons = SIDO_Polygons.toSet();
    });
  }

  Future<void> loadSIGUNGU() async {
    if (SIGUNGU_Polygons.isEmpty) {
      DatabaseReference starCountRef = FirebaseDatabase.instance.ref("polygonData/kr/SIGUNGU/features");
      DataSnapshot snapshot = await starCountRef.get(); //비동기
      final data = snapshot.value;
      if (data != null && data is List<dynamic>) {
        List<GeoFeature> geoData = data.map<GeoFeature>((item) {
          final Map<String, dynamic> map = Map<String, dynamic>.from(item);
          return GeoFeature.fromJson(map);
        }).toList();

        var sortedEntries = regionDetails.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
        Map<String, int> nameRank = {};
        for (var i = 0; i < sortedEntries.length; i++) {
          nameRank[sortedEntries[i].key] = i.toInt();
        }

        print(nameRank.length);

        for (var feature in geoData) {
          var geometry = feature.geometry;
          var type = geometry.type;
          var coordinates = geometry.coordinates;
          String id = feature.properties.sigunguCd ?? "null";
          String name = feature.properties.sigunguNm?.split(" ")[0] ?? "null";
          SIDOGUNGU_Name[PolygonId(id)] = name;

          Color color = getColor((nameRank[name]! + 1) * 1.1);

          List<LatLng> allCoordinates = [];
          List<Polygon> polygons = [];

          if (type == 'Polygon') {
            allCoordinates = _convertToLatLngList(coordinates[0][0]);
            polygons.add(createPolygon(PolygonId(id), allCoordinates, 1, () => onSIGUNGUPolygonTapped(PolygonId(id)), color));
          } else if (type == 'MultiPolygon') {
            for (var i = 0; i < coordinates.length; i++) {
              List<LatLng> tempCoordinates = _convertToLatLngList(coordinates[i][0]);
              allCoordinates.addAll(tempCoordinates);
              polygons.add(createPolygon(PolygonId("$id-$i"), tempCoordinates, 1, () => onSIGUNGUPolygonTapped(PolygonId(id)), color));
            }
          }
          SIGUNGU_Individual[PolygonId(id)] = allCoordinates;

          //key-시도, value-시군구 리스트
          if (SIGUNGU_Polygons[PolygonId(id.substring(0, 2))] != null) {
            SIGUNGU_Polygons[PolygonId(id.substring(0, 2))]!.addAll(polygons);
          } else {
            SIGUNGU_Polygons[PolygonId(id.substring(0, 2))] = polygons;
          }
        }
      }
    }
    // setState(() { ... });
  }

  Future<void> onSIDOPolygonTapped(PolygonId polygonId) async {
    await loadSIGUNGU();
    print("시군구 로딩완료");
    String id = polygonId.toString();
    mainID = SIDOGUNGU_Name[polygonId] ?? "없음";

    if (id.contains('-')) {
      polygonId = PolygonId(id.split('-')[0]);
    }

    // Calculate bounds
    if (polyBounds[polygonId] == null) {
      polyBounds[polygonId] = calculatePolygonBounds(SIDO_Individual[polygonId]!);
    }
    clearMap();
    List<Polygon>? data = SIGUNGU_Polygons[polygonId];
    setState(() {
      List<Polygon> temp1 = List.from(SIDO_Polygons);
      List<Polygon> temp2 = [];
      for (Polygon po in temp1) {
        String tempID = po.polygonId.toString();
        String mainID = tempID.substring(tempID.indexOf('(') + 1, tempID.indexOf(')')).split("-")[0];
        if (mainID != id.substring(id.indexOf('(') + 1, id.indexOf(')')).split("-")[0]) {
          temp2.add(po);
        }
      }
      polygons = temp2.toSet();
      if (data != null) {
        polygons.addAll(data.toSet());
      }
    });
    // Animate camera
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngBounds(polyBounds[polygonId]!, 20.0));
  }

  Future<void> onSIGUNGUPolygonTapped(PolygonId polygonId) async {
    String name = SIDOGUNGU_Name[polygonId] ?? '정보 없음';
    // Calculate bounds
    if (polyBounds[polygonId] == null) {
      polyBounds[polygonId] = calculatePolygonBounds(SIGUNGU_Individual[polygonId]!);
    }
    // Animate camera
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngBounds(polyBounds[polygonId]!, 60.0));
    DatabaseReference starCountRef = FirebaseDatabase.instance.ref("자선단체/$mainID/$name");
    starCountRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;
      late List<SocialWelfareOrganization> organizations;
      print("자선단체/$mainID/$name");
      print(data);
      if (data == null) {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return Container(
              height: 300,
              margin: const EdgeInsets.only(left: 25, right: 25, bottom: 40),
              padding: const EdgeInsets.only(top: 25, left: 25, right: 25, bottom: 25),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      itemCount: 1,
                      itemBuilder: (context, index) {
                        return SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                "$mainID $name",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                "자선단체 데이터가 없습니다.",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
          backgroundColor: Colors.transparent, // 앱 <=> 모달의 여백 부분을 투명하게 처리
        );
      } else if (data is List<dynamic>) {
        organizations = data.map((item) {
          // item을 Map<String, dynamic>으로 안전하게 변환
          final Map<String, dynamic> map = Map<String, dynamic>.from(item as Map);
          // 변환된 맵을 사용하여 SocialWelfareOrganization 인스턴스 생성
          return SocialWelfareOrganization.fromJson(map);
        }).toList();

        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return Container(
              height: 300,
              margin: const EdgeInsets.only(left: 25, right: 25, bottom: 40),
              padding: const EdgeInsets.only(top: 25, left: 25, right: 25, bottom: 25),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      itemCount: organizations.length, // organizations는 SocialWelfareOrganization 객체의 리스트
                      itemBuilder: (context, index) {
                        // 현재 페이지의 SocialWelfareOrganization 객체
                        SocialWelfareOrganization organization = organizations[index];
                        return SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                organization.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () async {
                                  LatLng coordinates = await getCoordinatesFromAddress(organization.address);
                                  final GoogleMapController controller = await _controller.future;
                                  controller.animateCamera(CameraUpdate.newLatLngZoom(coordinates, 16.0));
                                  Navigator.pop(context);
                                  setState(() {
                                    markers.add(Marker(
                                      markerId: MarkerId(organization.name),
                                      position: coordinates,
                                      infoWindow: InfoWindow(title: organization.name),
                                    ));
                                  });
                                },
                                child: Text(
                                  organization.address,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  // 전화번호를 탭하면 전화 앱으로 이동
                                  // launch('tel:${organization.phone}');
                                },
                                child: Text(
                                  organization.phone,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Text("${index + 1}/${organizations.length}", style: const TextStyle(fontSize: 16)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
          backgroundColor: Colors.transparent, // 앱 <=> 모달의 여백 부분을 투명하게 처리
        );
      }
    });
  }

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

  List<LatLng> _convertToLatLngList(List<List<double>> coords) {
    return coords.map<LatLng>((coord) => LatLng(coord[1], coord[0])).toList();
  }

  createPolygon(PolygonId polygonId, List<LatLng> points, int zIndex, void Function()? onTapFunction, Color fillColor) {
    Polygon polygon = Polygon(
        polygonId: polygonId,
        points: points,
        fillColor: fillColor,
        strokeColor: Colors.blue,
        strokeWidth: 3,
        zIndex: zIndex,
        consumeTapEvents: true,
        onTap: onTapFunction);
    return polygon;
  }

  showCurrentCenterPosition() {
    Fluttertoast.showToast(
      msg: "Current Center: ${_currentCameraPosition.target.latitude}, ${_currentCameraPosition.target.longitude}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  clearMap() {
    polylines.clear();
    circles.clear();
    polygons.clear();
  }
}
