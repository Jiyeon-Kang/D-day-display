# D-day-display

Flutter로 만든 입자 트리 애니메이션입니다. Android, iOS, 웹을 지원합니다.

- 처음 실행하면 입자 2,200개가 가운데 큰 민트색 트리(`#99EEDD`)와 양쪽 작은 분홍색 트리(`#FFAACC`)로 모입니다.
- iPhone 15 화면에 맞춘 큰 정면 구도로 세 트리가 각자의 자리에서 회전하고, 눈송이 160개가 이어집니다.
- 완성된 트리는 다시 보기를 누르기 전까지 흩어지지 않고 계속 유지됩니다.
- **다시 보기**: 트리와 D-day 입자 글자가 함께 다시 모입니다. 일시정지 중에도 바로 재생합니다.
- **일시정지 / 재생**: 눈과 트리의 움직임을 함께 멈추거나 이어 재생합니다.
- 앱이 백그라운드로 이동하면 멈추고, 돌아오면 같은 지점에서 이어집니다.
- 매년 12월 1일부터 25일까지 단말의 현지 날짜 기준 크리스마스 D-day가 화면 위에 표시됩니다.
  12월 1일은 `D-24`, 24일은 `D-1`, 25일은 `merry christmas!`로 표시합니다.
- D-day와 인사말도 트리처럼 작은 민트색·분홍색 입자가 모여 글자를 만들고 반짝입니다.
  일반 텍스트 헤더나 카드는 표시하지 않습니다.
- 날짜는 자정과 앱 복귀 시 갱신되며, 수동 시각·시간대 변경도 30초 이내에 확인합니다.
  트리를 일시정지해도 날짜는 계속 갱신됩니다.

## 실행

Flutter 3.22.2 / Dart 3.4.3 이상이 필요합니다.

```bash
flutter pub get
flutter run
```

연결된 기기나 실행 중인 시뮬레이터를 선택하면 됩니다.

실행 중 코드를 수정했다면 `flutter run` 터미널에서 `r`로 반영하거나,
`R`로 앱 상태를 초기화해 다시 시작할 수 있습니다. 설치 파일로 실행 중이라면
최신 소스로 다시 빌드하고 설치해야 변경 내용이 반영됩니다.

웹으로 실행하려면:

```bash
flutter run -d chrome
```

iOS 실행에는 Xcode, Android 실행에는 Android SDK가 필요합니다.

### D-day 미리보기

12월 전에도 디버그 실행에서 임시 날짜로 화면을 확인할 수 있습니다.

```bash
flutter run --dart-define=CHRISTMAS_PREVIEW_DATE=2026-12-10
```

이 예시는 12월 10일 기준 입자 글자 `D-15`를 표시합니다. 옵션 없이 실행하면
단말 날짜를 따르며, 릴리스 빌드는 이 옵션을 무시하고 항상 실제 날짜를 사용합니다.

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
