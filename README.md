# D-day-display

Flutter로 만든 입자 트리 애니메이션입니다. Android, iOS, 웹을 지원합니다.

- 입자 2,200개가 가운데 큰 민트색 트리(`#99EEDD`)와 양쪽 작은 분홍색 트리(`#FFAACC`)로 모였다가 흩어집니다.
- 12초 주기로 반복하며 원근감 있는 회전과 눈송이 160개를 그립니다.
- **다시 보기**: 애니메이션을 처음으로 되돌립니다. 일시정지 상태는 유지합니다.
- **일시정지 / 재생**: 눈과 트리의 움직임을 함께 멈추거나 이어 재생합니다.
- 앱이 백그라운드로 이동하면 멈추고, 돌아오면 같은 지점에서 이어집니다.

## 실행

Flutter 3.22.2 / Dart 3.4.3 이상이 필요합니다.

```bash
flutter pub get
flutter run
```

연결된 기기나 실행 중인 시뮬레이터를 선택하면 됩니다. 웹으로 실행하려면:

```bash
flutter run -d chrome
```

iOS 실행에는 Xcode, Android 실행에는 Android SDK가 필요합니다.

## 확인 및 빌드

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator --debug
flutter build web
```

웹 빌드 결과는 `build/web/`에 생성됩니다.

## 코드

- `lib/main.dart`: 앱 시작, 테마, 세로 화면 설정
- `lib/particle_tree.dart`: 화면, 재생 버튼, 앱 생명주기 처리
- `lib/particle_forest.dart`: 입자 생성과 Canvas 렌더링

애니메이션은 Flutter SDK만으로 그립니다. 별도의 이미지, 폰트, 그래픽 패키지나
서버 연결이 필요하지 않습니다. 프레임마다 화면 전체를 빌드하지 않도록
[CustomPainter의 repaint](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html)를
사용합니다.
