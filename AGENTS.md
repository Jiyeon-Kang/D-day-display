This is a Flutter application for Android, iOS, and web. Keep mobile performance
and cross-platform behavior in mind.

## Project

- `lib/main.dart`: application entry point, theme, and portrait orientation.
- `lib/particle_tree.dart`: screen, playback controls, and lifecycle handling.
- `lib/particle_forest.dart`: deterministic particles and CustomPainter rendering.
- `lib/tree_season.dart`: local-date ornament progression, tree palette, and Christmas star policy.
- `lib/christmas_season_day.dart`: shared display phase clamped to the fixed 2026 event window.
- `lib/christmas_ornament.dart`: code-native dot sprites and palette for five Christmas ornament designs.
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
- Preserve the seeded 2,200 tree particles, three trees, and 160 snowflakes.
  December 1–6 uses the mint center (`#99EEDD`) and pink sides (`#FFAACC`),
  with the existing birthday scenes on December 5–6. From December 7, use evergreen trees with red particle ribbons and varied Christmas ornaments.
- From December 1–25, show `floor(day * 1.5)` ornaments across the forest:
  1, 3, 4, 6, and so on, reaching 37 on Christmas Day. Add one or two per day
  using a fixed sequence of positions and designs; existing ornaments must not
  move or change design when the count changes. Render gingerbread cookies,
  candy canes, snowmen, Santa, and Rudolph as code-native dot sprites with
  small multicolor details, keeping their silhouettes readable on iPhone 15.
  Unlock designs by the date each ornament is added: cookies December 1, candy
  canes December 7, snowmen December 12, Santa December 17, Rudolph December 22.
  A stage starts with its new kind, then cycles through all unlocked designs.
  Assign kinds from the fixed slot birth date; never remap old slots at unlocks.
  On December 25, add a gold five-point particle star
  at the top of the center tree, clear of the particle lettering.
  Decorations follow the local or selected test date and the scene animation
  clock. Preserve the formed trees and elapsed time on ordinary calendar updates,
  including when paused. After December 25, retain the complete scene with 37
  ornaments, classic colors, star, and Christmas greeting indefinitely, including
  January 1 and later Decembers. Before December 1, 2026, retain the December 1
  screen (mint/pink trees, one cookie, no star, D-24). Only December 1–25, 2026
  progresses: compare full local dates against this fixed event window, not only
  month/day or a year derived from DateTime.now(). The event year is configured
  by `christmasSeasonYear`; restarting the app must not move the window.
  Keep actual device/test dates intact; only clamp
  the display phase via `christmas_season_day.dart`.
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
- Christmas D-day progresses December 1–25, 2026, using the device's local calendar.
  December 1 is D-24; December 25 displays lowercase `merry christmas!`,
  which stays visible for all later dates. Before the event, retain D-24. Do not announce
  today as Christmas in accessibility text for retained dates after the 25th.
  Render lettering as tiny mint/pink particles, with no normal text header,
  card, subtitle, or decorative widgets. Refresh at midnight and app resume.
  Animation pause must not pause calendar updates.
- On December 5 and 6, 2026, replace the trees with both birthday characters and
  the particle phrase `雫、誕生日おめでとう〜`. Preserve the main hair colors
  `#99EEDD` on the left and `#FFAACC` on the right, without the original
  HAPPY BIRTHDAY lettering. Distinguish details with rose lavender (`#E8D8EE`) faces and hands, pale
  lavender clothes, pistachio cake, muted blue plates, and pale gold ornaments.
  Place a few subdued dotted heart outlines behind the characters, clear of the
  title, faces, and controls. Hearts gather once, then hold with gentle twinkling;
  use the scene clock so pause and replay affect hearts and characters together.
  Switch scene types on calendar changes; do not reform held trees every day.
  The tree ornament progression and Christmas palette must not alter this
  birthday scene, its colors, hearts, or greeting.
- The optional CHRISTMAS_PREVIEW_DATE dart define is debug-only. Announce its
  preview date through semantics and identify it when sharing screenshots.
  Release builds always follow the real device clock.
- Debug controls `<` and `>` move one local calendar day, show the selected date
  and a test marker, and replay the scene and text. The calendar button restores
  the device date; never change the device clock. These controls are debug-only.
  Preview the birthday with `flutter run --dart-define=CHRISTMAS_PREVIEW_DATE=2026-12-05`.
