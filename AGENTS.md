This is a Flutter application for Android, iOS, and web. Keep mobile performance
and cross-platform behavior in mind.

## Project

- `lib/main.dart`: application entry point, theme, and portrait orientation.
- `lib/particle_tree.dart`: screen, playback controls, and lifecycle handling.
- `lib/particle_forest.dart`: deterministic particles and CustomPainter rendering.
- `lib/birthday_scene.dart`, `lib/particle_character.dart`: birthday image sampling and particle rendering.
- `lib/birthday_hearts.dart`: dotted heart outlines behind birthday characters.
- `lib/birthday_glyphs.dart`: embedded Noto Sans JP-derived birthday lettering.
- `lib/scene_date_controller.dart`: local calendar refresh and debug date navigation.
- `lib/christmas_countdown_date.dart`: device-local December 1–25 countdown dates.
- `lib/christmas_countdown.dart`: seasonal particle text, local-clock refresh, and replay.
- `lib/particle_countdown_text.dart`: dot-letter geometry and particle gathering.
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
  outside the Flutter SDK, runtime fonts, or network requests.
- `assets/birthday_characters.png` is edited from the user's two stickers with
  built-in `image_gen`; its instructions are in `assets/birthday_characters.prompt.txt`.
  Sample its contours and nearby source colors into the birthday detail palette;
  keep the source asset unchanged when adjusting particle colors. Embedded Japanese glyph
  data derives from Noto Sans JP, licensed in `assets/licenses/NotoSansJP-OFL.txt`.
- Preserve the seeded 2,200 particles, three trees, mint center (`#99EEDD`),
  pink sides (`#FFAACC`), and 160 snowflakes unless the user asks to change them.
- Form the trees once on startup, then retain their shape while rotation and
  snow continue. Do not automatically disperse or repeat the formation.
- Use an eye-level front view, keeping tree centers fixed while each tree rotates
  around its own trunk. Keep the enlarged scene inside iPhone 15 (393x852) bounds
  with room above the playback controls.
- Replay must restart the current scene and particle lettering and resume playback,
  even if paused.
- Repaint from the animation's Listenable instead of rebuilding the widget tree
  every frame. Batch particle geometry into one path per color.
- Stop ticking while paused or outside the foreground. Resuming must preserve
  elapsed animation time, including a pause that spans a lifecycle change.
- Keep controls reachable above system insets and usable with larger text.
- Christmas D-day is visible December 1–25, using the device's local calendar.
  December 1 is D-24; December 25 displays lowercase `merry christmas!`.
  Render lettering as tiny mint/pink particles, with no normal text header,
  card, subtitle, or decorative widgets. Refresh at midnight and app resume.
  Animation pause must not pause calendar updates.
- Every December 5 and 6, replace the trees with both birthday characters and
  the particle phrase `雫、誕生日おめでとう〜`. Preserve the main hair colors
  `#99EEDD` on the left and `#FFAACC` on the right, without the original
  HAPPY BIRTHDAY lettering. Distinguish details with rose lavender (`#E8D8EE`) faces and hands, pale
  lavender clothes, pistachio cake, muted blue plates, and pale gold ornaments.
  Place a few subdued dotted heart outlines behind the characters, clear of the
  title, faces, and controls. Hearts gather once, then hold with gentle twinkling;
  use the scene clock so pause and replay affect hearts and characters together.
  Switch scene types on calendar changes; do not reform held trees every day.
- The optional CHRISTMAS_PREVIEW_DATE dart define is debug-only. Announce its
  preview date through semantics and identify it when sharing screenshots.
  Release builds always follow the real device clock.
- Debug controls `<` and `>` move one local calendar day, show the selected date
  and a test marker, and replay the scene and text. The calendar button restores
  the device date; never change the device clock. These controls are debug-only.
  Preview the birthday with `flutter run --dart-define=CHRISTMAS_PREVIEW_DATE=2026-12-05`.
