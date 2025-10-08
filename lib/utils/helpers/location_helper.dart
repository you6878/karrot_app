import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationHelper {
  /// 위치 권한을 확인하고 요청합니다
  static Future<bool> requestLocationPermission() async {
    // 현재 권한 상태 확인
    PermissionStatus status = await Permission.location.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      // 권한 요청
      status = await Permission.location.request();
      return status.isGranted;
    }

    if (status.isPermanentlyDenied) {
      // 설정으로 이동하도록 안내
      await openAppSettings();
      return false;
    }

    return false;
  }

  /// 위치 서비스가 활성화되어 있는지 확인합니다
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// 현재 위치를 가져옵니다
  static Future<Position?> getCurrentPosition() async {
    try {
      // 위치 서비스 활성화 확인
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('위치 서비스가 비활성화되어 있습니다. 설정에서 활성화해주세요.');
      }

      // 권한 확인 및 요청
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        throw Exception('위치 권한이 필요합니다.');
      }

      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      return position;
    } catch (e) {
      throw Exception('위치를 가져올 수 없습니다: $e');
    }
  }

  /// 좌표를 주소로 변환합니다
  static Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        return '주소를 찾을 수 없습니다';
      }

      Placemark place = placemarks[0];

      // 한국 주소 형식으로 조합
      String address = '';

      if (place.locality != null && place.locality!.isNotEmpty) {
        address += place.locality!; // 시/도
      }

      if (place.subLocality != null && place.subLocality!.isNotEmpty) {
        if (address.isNotEmpty) address += ' ';
        address += place.subLocality!; // 구
      }

      if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
        if (address.isNotEmpty) address += ' ';
        address += place.thoroughfare!; // 동
      }

      return address.isNotEmpty ? address : '주소를 찾을 수 없습니다';
    } catch (e) {
      throw Exception('주소를 가져올 수 없습니다: $e');
    }
  }

  /// 현재 위치의 주소를 가져옵니다
  static Future<String> getCurrentAddress() async {
    try {
      Position? position = await getCurrentPosition();
      if (position == null) {
        throw Exception('위치를 가져올 수 없습니다');
      }

      String address = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      return address;
    } catch (e) {
      rethrow;
    }
  }

  /// 두 좌표 사이의 거리를 계산합니다 (미터 단위)
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// 거리를 읽기 쉬운 형식으로 변환합니다
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      double km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }
}
