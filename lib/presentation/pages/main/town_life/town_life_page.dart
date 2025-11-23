import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:karrot_clone/data/models/product_model.dart';
import 'package:karrot_clone/presentation/pages/product/product_detail_page.dart';
import 'package:karrot_clone/utils/constants/firebase_collections.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class TownLifePage extends StatefulWidget {
  const TownLifePage({super.key});

  @override
  State<TownLifePage> createState() => _TownLifePageState();
}

/// 거리 옵션
enum DistanceOption {
  near(label: '0.3km', value: 0.3, geoHashPrecision: 6),
  medium(label: '2.4km', value: 2.4, geoHashPrecision: 5),
  far(label: '10km', value: 10.0, geoHashPrecision: 4);

  const DistanceOption({
    required this.label,
    required this.value,
    required this.geoHashPrecision,
  });

  final String label;
  final double value;
  final int geoHashPrecision;
}

class _TownLifePageState extends State<TownLifePage> {
  NaverMapController? _mapController;
  NCircleOverlay? _currentLocationCircle;
  final List<NMarker> _productMarkers = [];
  final List<ProductModel> _products = [];

  // 마지막으로 상품을 로드한 위치
  NLatLng? _lastLoadedLocation;

  // 선택된 거리 옵션
  DistanceOption _selectedDistance = DistanceOption.medium;

  // 상품 재로드를 위한 최소 이동 거리 (km)
  static const double _reloadDistanceThreshold = 2.0;

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
        title: Row(
          children: [
            const Text(
              '동네생활',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(width: 8),
            // 거리 선택 드롭다운
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6F0F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFF6F0F),
                  width: 1,
                ),
              ),
              child: DropdownButton<DistanceOption>(
                value: _selectedDistance,
                underline: const SizedBox(),
                isDense: true,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFFFF6F0F),
                  size: 20,
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF6F0F),
                ),
                items: DistanceOption.values.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(option.label),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null && newValue != _selectedDistance) {
                    setState(() {
                      _selectedDistance = newValue;
                    });
                    _onDistanceChanged();
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showSearchBottomSheet,
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
              _initializeLocation();
              _loadProductMarkers();
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
              // 카메라 이동 완료 시 해당 위치 기준으로 상품 재로드 확인
              _checkAndReloadProducts();
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

  /// 위치 초기화 및 현재 위치 표시
  Future<void> _initializeLocation() async {
    try {
      final position = await _getCurrentLocation();
      if (position != null) {
        await _showCurrentLocationCircle(position);

        // 현재 위치로 카메라 이동
        final cameraUpdate = NCameraUpdate.scrollAndZoomTo(
          target: NLatLng(position.latitude, position.longitude),
          zoom: 15,
        );
        await _mapController?.updateCamera(cameraUpdate);
      }
    } catch (e) {
      debugPrint('위치 초기화 실패: $e');
    }
  }

  /// 거리 선택이 변경되었을 때 호출
  Future<void> _onDistanceChanged() async {
    if (_mapController == null) return;

    try {
      // 현재 카메라 위치 가져오기
      final cameraPosition = await _mapController!.getCameraPosition();
      final currentLocation = cameraPosition.target;

      // 선택된 거리로 상품 재로드
      await _loadProductMarkersAtLocation(currentLocation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedDistance.label} 반경 내 상품을 표시합니다'),
            duration: const Duration(seconds: 1),
            backgroundColor: const Color(0xFFFF6F0F),
          ),
        );
      }
    } catch (e) {
      debugPrint('거리 변경 후 상품 재로드 실패: $e');
    }
  }

  /// 위치 권한 확인 및 현재 위치 가져오기
  Future<Position?> _getCurrentLocation() async {
    try {
      // 위치 권한 확인
      final permission = await Permission.location.status;

      if (permission.isDenied) {
        final result = await Permission.location.request();
        if (!result.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('위치 권한이 필요합니다'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return null;
        }
      }

      // 위치 서비스 활성화 확인
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('위치 서비스를 활성화해주세요'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return null;
      }

      // 현재 위치 가져오기
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      debugPrint('위치 가져오기 실패: $e');
      return null;
    }
  }

  /// 현재 위치에 파란색 원형 표시
  Future<void> _showCurrentLocationCircle(Position position) async {
    if (_mapController == null) return;

    // 기존 원형 제거
    if (_currentLocationCircle != null) {
      _mapController!.deleteOverlay(_currentLocationCircle!.info);
    }

    // 파란색 원형 생성
    final circle = NCircleOverlay(
      id: 'current_location',
      center: NLatLng(position.latitude, position.longitude),
      radius: 50, // 50미터 반경
      color: Colors.blue.withOpacity(0.3),
      outlineColor: Colors.blue,
      outlineWidth: 2,
    );

    _currentLocationCircle = circle;
    _mapController!.addOverlay(circle);
  }

  /// 현재 위치로 이동
  Future<void> _moveToCurrentLocation() async {
    if (_mapController == null) return;

    try {
      final position = await _getCurrentLocation();
      if (position != null) {
        await _showCurrentLocationCircle(position);

        final cameraUpdate = NCameraUpdate.scrollAndZoomTo(
          target: NLatLng(position.latitude, position.longitude),
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
    } catch (e) {
      debugPrint('위치 이동 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('위치를 가져올 수 없습니다'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  /// Firestore에서 제품 데이터를 가져와서 마커로 표시
  /// geo_hash 앞 4자리를 사용하여 현재 위치 기준 약 20km 반경 내 상품만 조회
  Future<void> _loadProductMarkers() async {
    if (_mapController == null) return;

    try {
      // 현재 위치 가져오기
      final position = await _getCurrentLocation();

      if (position != null) {
        await _loadProductMarkersAtLocation(
          NLatLng(position.latitude, position.longitude),
        );
      } else {
        // 위치를 가져올 수 없는 경우 기본 쿼리 (제한적으로)
        await _loadProductMarkersAtLocation(null);
      }
    } catch (e) {
      debugPrint('제품 마커 로드 실패: $e');

      // 에러 발생 시 사용자에게 알림
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('주변 상품을 불러오는데 실패했습니다: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 특정 위치 기준으로 상품 마커 로드
  Future<void> _loadProductMarkersAtLocation(NLatLng? location) async {
    if (_mapController == null) return;

    try {
      QuerySnapshot querySnapshot;

      if (location != null) {
        // 위치의 geo_hash 계산
        final geoHasher = GeoHasher();
        final currentGeoHash = geoHasher.encode(
          location.longitude,
          location.latitude,
          precision: 9,
        );

        // 선택된 거리 옵션에 따라 geo_hash 정밀도 사용
        final geoHashPrecision = _selectedDistance.geoHashPrecision;
        final geoHashPrefix = currentGeoHash.substring(0, geoHashPrecision);

        debugPrint(
          '위치 (${location.latitude}, ${location.longitude}) '
          'geo_hash: $currentGeoHash\n'
          '검색 반경: ${_selectedDistance.label} '
          '(정밀도: $geoHashPrecision자리, 접두사: $geoHashPrefix)',
        );

        // geo_hash 기반 범위 쿼리
        // geo_hash가 접두사로 시작하는 상품만 조회
        querySnapshot = await FirebaseFirestore.instance
            .collection(FirebaseCollections.products)
            .where('geo_hash', isGreaterThanOrEqualTo: geoHashPrefix)
            .where('geo_hash', isLessThan: '$geoHashPrefix\uf8ff')
            .limit(100) // geo_hash 필터링으로 이미 범위가 제한되므로 100개로 증가
            .get();

        debugPrint(
          'geo_hash 기반 쿼리 (${_selectedDistance.label} 반경): '
          '${querySnapshot.docs.length}개 상품 발견',
        );

        // 마지막 로드 위치 저장
        _lastLoadedLocation = location;
      } else {
        // 위치를 가져올 수 없는 경우 기본 쿼리 (제한적으로)
        debugPrint('위치를 가져올 수 없어 기본 쿼리 사용');
        querySnapshot = await FirebaseFirestore.instance
            .collection(FirebaseCollections.products)
            .where('latitude', isNotEqualTo: null)
            .where('longitude', isNotEqualTo: null)
            .limit(30) // 위치 정보 없을 때는 더 적게
            .get();
      }

      // 기존 마커 제거
      for (final marker in _productMarkers) {
        _mapController?.deleteOverlay(marker.info);
      }
      _productMarkers.clear();
      _products.clear();

      // 각 제품에 대해 마커 생성
      for (final doc in querySnapshot.docs) {
        final product = ProductModel.fromFirestore(doc);

        // 제품 리스트에 추가 (검색용)
        _products.add(product);

        if (product.latitude != null &&
            product.longitude != null &&
            product.imageUrls.isNotEmpty) {
          await _addProductMarker(product);
        }
      }

      debugPrint('제품 마커 ${_productMarkers.length}개 로드 완료');
    } catch (e) {
      debugPrint('위치 기반 제품 마커 로드 실패: $e');
      rethrow;
    }
  }

  /// 카메라 이동 후 상품 재로드 확인
  /// 마지막 로드 위치에서 일정 거리 이상 이동했을 때만 재로드
  Future<void> _checkAndReloadProducts() async {
    if (_mapController == null) return;

    try {
      // 현재 카메라 위치 가져오기
      final cameraPosition = await _mapController!.getCameraPosition();
      final currentLocation = cameraPosition.target;

      // 마지막 로드 위치가 없거나 일정 거리 이상 이동했는지 확인
      if (_lastLoadedLocation == null ||
          _calculateDistance(_lastLoadedLocation!, currentLocation) >=
              _reloadDistanceThreshold) {
        debugPrint(
          '카메라가 ${_reloadDistanceThreshold}km 이상 이동함. 상품 재로드 중...',
        );
        await _loadProductMarkersAtLocation(currentLocation);
      }
    } catch (e) {
      debugPrint('상품 재로드 확인 실패: $e');
    }
  }

  /// 두 위치 사이의 거리 계산 (km)
  double _calculateDistance(NLatLng start, NLatLng end) {
    return Geolocator.distanceBetween(
          start.latitude,
          start.longitude,
          end.latitude,
          end.longitude,
        ) /
        1000; // 미터를 킬로미터로 변환
  }

  /// 제품 마커 추가
  Future<void> _addProductMarker(ProductModel product) async {
    if (_mapController == null) return;

    try {
      // 제품 이미지를 마커 아이콘으로 변환
      NOverlayImage? markerIcon;
      try {
        markerIcon = await _createMarkerIconFromImage(
          product.imageUrls.first,
        );
      } catch (e) {
        debugPrint('커스텀 마커 아이콘 생성 실패, 기본 마커 사용: $e');
      }

      final marker = NMarker(
        id: 'product_${product.id}',
        position: NLatLng(product.latitude!, product.longitude!),
        size: const Size(60, 60),
        caption: NOverlayCaption(
          text: product.title,
          textSize: 12,
          color: Colors.white,
          haloColor: const Color(0xFFFF6F0F),
        ),
      );

      // 커스텀 아이콘이 있으면 설정
      if (markerIcon != null) {
        marker.setIcon(markerIcon);
      }

      // 마커 탭 이벤트
      marker.setOnTapListener((overlay) {
        _showProductInfo(product);
        return true;
      });

      _mapController!.addOverlay(marker);
      _productMarkers.add(marker);
    } catch (e) {
      debugPrint('제품 마커 추가 실패: $e');
    }
  }

  /// 이미지 URL로부터 마커 아이콘 생성
  Future<NOverlayImage> _createMarkerIconFromImage(String imageUrl) async {
    try {
      // 네트워크 이미지를 위젯으로 로드
      final imageProvider = CachedNetworkImageProvider(imageUrl);
      final imageStream = imageProvider.resolve(ImageConfiguration.empty);

      final completer = Completer<ui.Image>();
      imageStream.addListener(
        ImageStreamListener((ImageInfo info, bool _) {
          completer.complete(info.image);
        }),
      );

      final image = await completer.future;

      // 이미지를 원형으로 자르고 테두리 추가
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = 60.0;

      // 흰색 테두리가 있는 원형 배경
      final paint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        size / 2,
        paint,
      );

      // 이미지를 원형으로 클립
      final clipPath = Path()
        ..addOval(Rect.fromCircle(
          center: const Offset(size / 2, size / 2),
          radius: size / 2 - 3,
        ));
      canvas.clipPath(clipPath);

      // 이미지 그리기
      paintImage(
        canvas: canvas,
        rect: const Rect.fromLTWH(3, 3, size - 6, size - 6),
        image: image,
        fit: BoxFit.cover,
      );

      // 테두리 그리기
      final borderPaint = Paint()
        ..color = const Color(0xFFFF6F0F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        size / 2 - 1.5,
        borderPaint,
      );

      final picture = pictureRecorder.endRecording();
      final finalImage = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await finalImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      final bytes = byteData!.buffer.asUint8List();

      // 임시 파일로 저장
      final tempDir = await getTemporaryDirectory();
      final fileName = 'marker_${imageUrl.hashCode}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      // 파일로부터 NOverlayImage 생성
      return NOverlayImage.fromFile(file);
    } catch (e) {
      debugPrint('마커 아이콘 생성 실패: $e');
      // 실패 시 기본 마커 사용 (기본 마커는 NMarker의 기본 아이콘 사용)
      rethrow;
    }
  }

  /// 제품 정보 표시
  void _showProductInfo(ProductModel product) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 핸들 바
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // 제품 정보
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrls.first,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.error),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${product.price.toString()}원',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF6F0F),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 제품 설명
                Text(
                  product.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // 상세보기 버튼
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // 제품 상세 페이지로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailPage(
                            product: product,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6F0F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '상세보기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 검색 바텀시트 표시
  void _showSearchBottomSheet() {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _SearchBottomSheet(products: _products),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '우리 동네',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${_selectedDistance.label} 반경',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF6F0F),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '· 상품 ${_products.length}개',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF808080),
                          ),
                        ),
                      ],
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

/// 제품 검색 바텀시트
class _SearchBottomSheet extends StatefulWidget {
  final List<ProductModel> products;

  const _SearchBottomSheet({required this.products});

  @override
  State<_SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<_SearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<ProductModel> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _filteredProducts = widget.products;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 검색어로 제품 필터링
  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = widget.products;
      } else {
        _filteredProducts = widget.products
            .where((product) =>
                product.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  /// 가격 포맷팅
  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 상단 핸들 바
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 검색 제목
              const Row(
                children: [
                  Text(
                    '상품 검색',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 검색 입력 필드
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '상품명으로 검색',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFFFF6F0F),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _filterProducts('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: _filterProducts,
              ),
              const SizedBox(height: 16),

              // 검색 결과 개수
              Row(
                children: [
                  Text(
                    '검색 결과 ${_filteredProducts.length}개',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 검색 결과 리스트
              Expanded(
                child: _filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '검색 결과가 없습니다',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredProducts.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          color: Color(0xFFE0E0E0),
                        ),
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailPage(
                                    product: product,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  // 제품 이미지
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: product.imageUrls.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: product.imageUrls.first,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Container(
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Container(
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.error),
                                            ),
                                          )
                                        : Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.image,
                                              color: Colors.grey,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),

                                  // 제품 정보
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF333333),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_formatPrice(product.price)}원',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFFF6F0F),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          product.location,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 화살표 아이콘
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey[400],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
