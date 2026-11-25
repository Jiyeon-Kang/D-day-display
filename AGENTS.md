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

When a device is already running this project, apply UI/animation edits to that
session with hot reload or hot restart and verify the actual screen. Source tests
do not refresh an installed app. Rebuild and reinstall when checking fresh launches.

## Rendering

- Use Flutter's Canvas and CustomPainter; there are no runtime dependencies
  outside the Flutter SDK and no external assets for the animation.
- Preserve the seeded 2,200 particles, three trees, mint center (`#99EEDD`),
  pink sides (`#FFAACC`), and 160 snowflakes unless the user asks to change them.
- Form the trees once on startup, then retain their shape while rotation and
  snow continue. Do not automatically disperse or repeat the formation.
- Use an eye-level front view, keeping tree centers fixed while each tree rotates
  around its own trunk. Keep the enlarged scene inside iPhone 15 (393x852) bounds
  with room above the playback controls.
- Replay must restart the startup animation and resume playback, even if paused.
- Repaint from the animation's Listenable instead of rebuilding the widget tree
  every frame. Batch particle geometry into one path per color.
- Stop ticking while paused or outside the foreground. Resuming must preserve
  elapsed animation time, including a pause that spans a lifecycle change.
- Keep controls reachable above system insets and usable with larger text.
