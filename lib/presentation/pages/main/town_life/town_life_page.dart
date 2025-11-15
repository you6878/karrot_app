import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class TownLifePage extends StatefulWidget {
  const TownLifePage({super.key});

  @override
  State<TownLifePage> createState() => _TownLifePageState();
}

class _TownLifePageState extends State<TownLifePage> {
  NaverMapController? _mapController;

  // 서울시청 좌표 (기본값)
  static const _defaultLocation = NLatLng(37.5666, 126.9779);

  @override
  Widget build(BuildContext context) {
    final safeAreaPadding = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '동네생활',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: 검색 기능
            },
            icon: const Icon(
              Icons.search,
              color: Color(0xFF333333),
              size: 24,
            ),
          ),
          IconButton(
            onPressed: _moveToCurrentLocation,
            icon: const Icon(
              Icons.my_location,
              color: Color(0xFF333333),
              size: 24,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 네이버 지도
          NaverMap(
            options: NaverMapViewOptions(
              contentPadding: safeAreaPadding,
              initialCameraPosition: NCameraPosition(
                target: _defaultLocation,
                zoom: 14,
                bearing: 0,
                tilt: 0,
              ),
              mapType: NMapType.basic,
              activeLayerGroups: [
                NLayerGroup.building,
                NLayerGroup.transit,
              ],
              locale: const Locale('kr'),
              indoorEnable: true,
              locationButtonEnable: false, // 커스텀 버튼 사용
              consumeSymbolTapEvents: false,
            ),
            onMapReady: (controller) {
              _mapController = controller;
              _addDefaultMarker();
              debugPrint('네이버 지도 준비 완료!');
            },
            onMapTapped: (point, latLng) {
              debugPrint('지도 탭: $latLng');
            },
            onSymbolTapped: (symbol) {
              debugPrint('심볼 탭: ${symbol.caption}');
            },
            onCameraChange: (position, reason) {
              // 카메라 변경 시 처리
            },
            onCameraIdle: () {
              // 카메라 이동 완료 시 처리
            },
          ),

          // 하단 정보 카드 (예시)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + safeAreaPadding.bottom,
            child: _buildInfoCard(),
          ),
        ],
      ),
    );
  }

  /// 기본 마커 추가
  void _addDefaultMarker() {
    if (_mapController == null) return;

    final marker = NMarker(
      id: 'default_marker',
      position: _defaultLocation,
      caption: const NOverlayCaption(
        text: '서울시청',
        textSize: 14,
      ),
      // 기본 마커 아이콘 사용
    );

    // 마커 탭 이벤트
    marker.setOnTapListener((overlay) {
      debugPrint('마커 탭: ${overlay.info.id}');
      _showMarkerInfo('서울시청');
    });

    _mapController!.addOverlay(marker);
  }

  /// 현재 위치로 이동
  void _moveToCurrentLocation() async {
    if (_mapController == null) return;

    // TODO: 실제 사용자 위치 가져오기 (Geolocator 사용)
    // 현재는 서울시청으로 이동
    final cameraUpdate = NCameraUpdate.scrollAndZoomTo(
      target: _defaultLocation,
      zoom: 15,
    );

    await _mapController!.updateCamera(cameraUpdate);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('현재 위치로 이동했습니다'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  /// 마커 정보 표시
  void _showMarkerInfo(String title) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(title),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 하단 정보 카드
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6F0F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '우리 동네',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '동네 소식과 정보를 확인하세요',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF808080),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
