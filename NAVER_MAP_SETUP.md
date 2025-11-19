# 네이버 지도 설정 가이드

당근마켓 클론 앱에 네이버 지도를 통합하는 방법을 안내합니다.

## 📦 패키지 정보
- **패키지**: `flutter_naver_map`
- **버전**: `1.4.1+1`
- **공식 문서**: https://pub.dev/packages/flutter_naver_map

## 🔑 1. 네이버 클라우드 플랫폼 설정

### 1-1. 콘솔 접속
1. [네이버 클라우드 플랫폼 콘솔](https://console.ncloud.com/)에 접속합니다.
2. Services > Application Services > Maps로 이동합니다.

### 1-2. Application 등록
1. **Application 등록** 버튼 클릭
2. **Application 이름** 입력 (예: 당근마켓 클론)
3. **API 선택**에서 "**Dynamic Map**" 선택
4. **서비스 환경 등록**:
   - **Android**: 앱 패키지 이름 입력 (`com.example.karrot_clone`)
   - **iOS**: Bundle ID 입력 (예: `com.example.karrotClone`)
5. **등록** 버튼 클릭

### 1-3. Client ID 확인
등록한 Application의 **"인증정보"**에서 **"Client ID"**를 확인합니다.

---

## 🔧 2. 프로젝트 설정

### 2-1. Client ID 설정
`lib/main.dart` 파일에서 Client ID를 입력합니다:

```dart
Future<void> _initializeNaverMap() async {
  await FlutterNaverMap().init(
    clientId: 'YOUR_NAVER_CLIENT_ID', // 👈 여기에 발급받은 Client ID 입력!
    onAuthFailed: (ex) {
      // 인증 실패 처리
    },
  );
}
```

### 2-2. iOS 설정 (Mac 사용자만 해당)

iOS pod를 설치해야 합니다:

```bash
cd ios
pod install
cd ..
```

> **주의**: 네트워크 문제가 발생할 경우 나중에 다시 시도하세요.

---

## ✅ 3. 설치 확인

모든 설정이 완료되었습니다! 앱을 실행하여 확인하세요:

```bash
flutter run
```

### 동네생활 탭에서 확인 가능한 기능:
✅ 네이버 지도 표시 (기본: 서울시청 위치)  
✅ 마커 표시  
✅ 현재 위치 버튼 (우측 상단)  
✅ 검색 버튼 (좌측 상단)  
✅ 하단 정보 카드  

---

## 📱 4. 주요 기능

### 4-1. 지도 옵션
- **초기 위치**: 서울시청 (37.5666, 126.9779)
- **초기 줌 레벨**: 14
- **지도 타입**: 기본 지도
- **활성 레이어**: 건물, 대중교통

### 4-2. 인터랙션
- **지도 탭**: 좌표 출력 (디버그 모드)
- **마커 탭**: 정보 표시
- **현재 위치 버튼**: 초기 위치로 이동

### 4-3. 커스터마이징
- `TownLifePage` 위젯에서 지도 설정을 변경할 수 있습니다.
- `_defaultLocation` 상수를 변경하여 초기 위치를 조정할 수 있습니다.
- `NaverMapViewOptions`에서 지도 옵션을 커스터마이징할 수 있습니다.

---

## 🔍 5. 추가 기능 (TODO)

### 현재 위치 가져오기
이미 설치된 `geolocator` 패키지를 사용하여 실제 사용자 위치를 가져올 수 있습니다:

```dart
import 'package:geolocator/geolocator.dart';

Future<void> _getCurrentLocation() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return;

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return;
  }

  Position position = await Geolocator.getCurrentPosition();
  final currentLocation = NLatLng(position.latitude, position.longitude);
  
  // 지도를 현재 위치로 이동
  _mapController?.updateCamera(
    NCameraUpdate.scrollAndZoomTo(target: currentLocation, zoom: 15),
  );
}
```

### 주변 상품 마커 표시
Firebase에서 상품 데이터를 가져와 지도에 마커로 표시할 수 있습니다:

```dart
void _addProductMarkers(List<Product> products) {
  for (final product in products) {
    final marker = NMarker(
      id: product.id,
      position: NLatLng(product.latitude, product.longitude),
      caption: NOverlayCaption(text: product.title),
    );
    
    marker.setOnTapListener((overlay) {
      // 상품 상세 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailPage(product: product),
        ),
      );
    });
    
    _mapController?.addOverlay(marker);
  }
}
```

---

## 🛠️ 6. 문제 해결

### iOS pod install 오류
```bash
cd ios
pod deintegrate
pod install --repo-update
cd ..
```

### Android 빌드 오류
```bash
cd android
./gradlew clean
./gradlew --refresh-dependencies
cd ..
```

### 지도가 표시되지 않음
1. Client ID가 올바르게 입력되었는지 확인
2. 네이버 클라우드 플랫폼에서 Application이 활성화되어 있는지 확인
3. 패키지 이름과 Bundle ID가 일치하는지 확인

---

## 📚 7. 참고 자료

- [flutter_naver_map 공식 문서](https://pub.dev/packages/flutter_naver_map)
- [네이버 지도 API 가이드](https://navermaps.github.io/ios-map-sdk/guide-ko/)
- [네이버 클라우드 플랫폼](https://console.ncloud.com/)

---

## 🎉 완료!

네이버 지도 통합이 완료되었습니다. 동네생활 탭을 클릭하여 지도를 확인하세요! 🗺️





