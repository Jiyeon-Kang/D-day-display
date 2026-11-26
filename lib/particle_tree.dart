import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'birthday_scene.dart';
import 'christmas_countdown.dart';
import 'particle_forest.dart';
import 'scene_date_controller.dart';
import 'tree_season.dart';

class ParticleTreePage extends StatefulWidget {
  const ParticleTreePage({
    super.key,
    this.previewDate,
    this.now = DateTime.now,
    this.showDateControls = kDebugMode,
  });

  final DateTime? previewDate;
  final DateTime Function() now;
  final bool showDateControls;

  @override
  State<ParticleTreePage> createState() => _ParticleTreePageState();
}

class _ParticleTreePageState extends State<ParticleTreePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _time = ValueNotifier<double>(0);
  late final Ticker _ticker;
  late ParticleForestPainter _painter;
  late final SceneDateController _dates;
  late bool _wasBirthday;
  Duration? _lastElapsed;
  bool _paused = false;
  bool _foreground = true;
  int _replayCount = 0;

  @override
  void initState() {
    super.initState();
    final binding = WidgetsBinding.instance;
    binding.addObserver(this);
    _foreground = binding.lifecycleState == null ||
        binding.lifecycleState == AppLifecycleState.resumed;
    _ticker = createTicker(_onTick);
    _dates = SceneDateController(
      now: () => widget.now(),
      initialPreviewDate: widget.previewDate,
      active: _foreground,
    );
    _painter = ParticleForestPainter(
      time: _time,
      season: TreeSeason.fromLocalDate(_dates.date),
    );
    _wasBirthday = _dates.isBirthday;
    _dates.addListener(_onSceneDateChanged);
    _updatePlayback();
  }

  @override
  void didUpdateWidget(covariant ParticleTreePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.previewDate != widget.previewDate) {
      final preview = widget.previewDate;
      if (preview == null) {
        _dates.useDeviceDate();
      } else {
        _dates.setPreviewDate(preview);
      }
    } else if (oldWidget.now != widget.now) {
      _dates.refresh();
    }
  }

  void _onSceneDateChanged() {
    if (!mounted) return;
    final season = TreeSeason.fromLocalDate(_dates.date);
    if (season != _painter.season) {
      _painter = ParticleForestPainter(time: _time, season: season);
    }
    final birthday = _dates.isBirthday;
    if (birthday != _wasBirthday) {
      _wasBirthday = birthday;
      _time.value = _paused ? 3 : 0;
      _lastElapsed = null;
    }
    setState(() {});
  }

  void _shiftDate(int offset) {
    _dates.shiftDay(offset);
    _replay();
  }

  void _useDeviceDate() {
    _dates.useDeviceDate();
    _replay();
  }

  void _onTick(Duration elapsed) {
    final previous = _lastElapsed;
    _lastElapsed = elapsed;
    if (previous == null) return;

    // Keep dropped frames from jumping the animation, as in the original.
    final delta =
        (elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond;
    _time.value += delta.clamp(0.0, 0.04);
  }

  void _updatePlayback() {
    if (_foreground && !_paused) {
      if (!_ticker.isActive) {
        _lastElapsed = null;
        _ticker.start();
      }
    } else {
      _ticker.stop();
      _lastElapsed = null;
    }
  }

  void _togglePaused() {
    setState(() => _paused = !_paused);
    _updatePlayback();
  }

  void _replay() {
    _time.value = 0;
    _lastElapsed = null;
    setState(() {
      _paused = false;
      _replayCount++;
    });
    _updatePlayback();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _dates.setActive(_foreground);
    _updatePlayback();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dates.removeListener(_onSceneDateChanged);
    _dates.dispose();
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = OutlinedButton.styleFrom(
      foregroundColor: const Color(0xffc8e5e4),
      backgroundColor: const Color(0xff142330),
      side: const BorderSide(color: Color(0xff294455)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      minimumSize: const Size(0, 48),
      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xff050b12),
      ),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_dates.isBirthday)
              BirthdayScene(time: _time)
            else
              Semantics(
                image: true,
                label: '눈 내리는 숲에서 입자가 세 그루의 트리로 모입니다',
                child: RepaintBoundary(
                  child: CustomPaint(painter: _painter),
                ),
              ),
            Positioned(
              left: 24,
              right: 24,
              top: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ChristmasCountdown(
                    now: widget.now,
                    previewDate: _dates.isTesting ? _dates.date : null,
                    animated: !_paused,
                    replayCount: _replayCount,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: widget.showDateControls
                  ? math.max(12.0, MediaQuery.paddingOf(context).bottom + 8)
                  : math.max(52.0, MediaQuery.paddingOf(context).bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton(
                        style: buttonStyle,
                        onPressed: _replay,
                        child: const Text('다시 보기'),
                      ),
                      OutlinedButton(
                        style: buttonStyle,
                        onPressed: _togglePaused,
                        child: Text(_paused ? '재생' : '일시정지'),
                      ),
                    ],
                  ),
                  if (widget.showDateControls) ...[
                    const SizedBox(height: 8),
                    _DateControls(
                      date: _dates.date,
                      isTesting: _dates.isTesting,
                      onPrevious: () => _shiftDate(-1),
                      onNext: () => _shiftDate(1),
                      onToday: _useDeviceDate,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateControls extends StatelessWidget {
  const _DateControls({
    required this.date,
    required this.isTesting,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final DateTime date;
  final bool isTesting;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final formatted = '${date.year.toString().padLeft(4, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.day.toString().padLeft(2, '0')}';
    const color = Color(0xffc8e5e4);

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('previous-date'),
            tooltip: '이전 날짜',
            color: color,
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Semantics(
              liveRegion: true,
              label: '${isTesting ? '테스트' : '단말'} 날짜, '
                  '${date.year}년 ${date.month}월 ${date.day}일',
              child: ExcludeSemantics(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$formatted · ${isTesting ? '테스트' : '단말 날짜'}',
                    key: const ValueKey('scene-date-label'),
                    style: const TextStyle(
                      color: Color(0xff9db8ba),
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('next-date'),
            tooltip: '다음 날짜',
            color: color,
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton(
            key: const ValueKey('device-date'),
            tooltip: '단말 날짜로 돌아가기',
            color: color,
            onPressed: onToday,
            icon: const Icon(Icons.today_outlined, size: 20),
          ),
        ],
      ),
    );
  }
}
