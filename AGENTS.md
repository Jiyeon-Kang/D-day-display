This is a Flutter application for Android, iOS, and web. Keep mobile performance
and cross-platform behavior in mind.

## Project

- `lib/main.dart`: application entry point, theme, and portrait orientation.
- `lib/particle_tree.dart`: screen, playback controls, and lifecycle handling.
- `lib/particle_forest.dart`: deterministic particles and CustomPainter rendering.
- `test/`: playback, lifecycle, layout, and rendering checks.
- `android/`, `ios/`, `web/`: Flutter platform projects, tracked in Git.

## Commands

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run
flutter run -d chrome
flutter build web
```

Run formatting, analysis, and tests before finishing changes. The supported
baseline is Flutter 3.22.2 / Dart 3.4.3; avoid APIs requiring a newer SDK unless
the minimum SDK is deliberately updated.

## Rendering

- Use Flutter's Canvas and CustomPainter; there are no runtime dependencies
  outside the Flutter SDK and no external assets for the animation.
- Preserve the seeded 2,200 particles, three trees, six colors, 160 snowflakes,
  and 12-second cycle unless the user asks to change the effect.
- Repaint from the animation's Listenable instead of rebuilding the widget tree
  every frame. Batch particle geometry into one path per color.
- Stop ticking while paused or outside the foreground. Resuming must preserve
  elapsed animation time, including a pause that spans a lifecycle change.
- Keep controls reachable above system insets and usable with larger text.
