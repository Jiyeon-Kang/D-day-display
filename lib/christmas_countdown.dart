import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'christmas_countdown_date.dart';
import 'particle_countdown_text.dart';

class ChristmasCountdown extends StatefulWidget {
  const ChristmasCountdown({
    super.key,
    this.now = DateTime.now,
    this.previewDate,
    this.animated = true,
    this.replayCount = 0,
  });

  final DateTime Function() now;
  final DateTime? previewDate;
  final bool animated;
  final int replayCount;

  @override
  State<ChristmasCountdown> createState() => _ChristmasCountdownState();
}

class _ChristmasCountdownState extends State<ChristmasCountdown>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _particleTime = ValueNotifier<double>(0);
  late ChristmasCountdownDate _date;
  late ParticleCountdownTextPainter _painter;
  late final Ticker _ticker;
  Duration? _lastElapsed;
  Timer? _refreshTimer;
  bool _foreground = true;
  bool _reduceMotion = false;

  DateTime get _now => (widget.previewDate ?? widget.now()).toLocal();

  @override
  void initState() {
    super.initState();
    final binding = WidgetsBinding.instance;
    binding.addObserver(this);
    _foreground = binding.lifecycleState == null ||
        binding.lifecycleState == AppLifecycleState.resumed;
    _date = ChristmasCountdownDate.fromLocalDate(_now);
    if (!widget.animated) _particleTime.value = 3;
    _painter = ParticleCountdownTextPainter(
      text: _date.displayLabel,
      time: _particleTime,
    );
    _ticker = createTicker(_onTick);
    _scheduleRefresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion && _particleTime.value < 3) _particleTime.value = 3;
    _updatePlayback();
  }

  @override
  void didUpdateWidget(covariant ChristmasCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshDate();
    if (oldWidget.replayCount != widget.replayCount) _restartParticles();
    _updatePlayback();
  }

  void _onTick(Duration elapsed) {
    final previous = _lastElapsed;
    _lastElapsed = elapsed;
    if (previous == null) return;
    final delta =
        (elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond;
    _particleTime.value += delta.clamp(0.0, 0.04);
  }

  void _restartParticles() {
    _particleTime.value = !widget.animated || _reduceMotion ? 3 : 0;
    _lastElapsed = null;
  }

  void _updatePlayback() {
    if (_foreground && _date.isVisible && widget.animated && !_reduceMotion) {
      if (!_ticker.isActive) {
        _lastElapsed = null;
        _ticker.start();
      }
    } else {
      _ticker.stop();
      _lastElapsed = null;
    }
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    if (!_foreground) return;
    final now = _now;
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final untilMidnight = midnight.difference(now);
    final delay = untilMidnight < const Duration(seconds: 30)
        ? untilMidnight + const Duration(milliseconds: 1)
        : const Duration(seconds: 30);
    _refreshTimer = Timer(delay, _refreshDate);
  }

  void _refreshDate() {
    if (!mounted) return;
    final next = ChristmasCountdownDate.fromLocalDate(_now);
    if (next.year != _date.year || next.daysRemaining != _date.daysRemaining) {
      final letteringChanged = next.displayLabel != _date.displayLabel;
      setState(() {
        _date = next;
        if (letteringChanged) {
          _painter = ParticleCountdownTextPainter(
            text: next.displayLabel,
            time: _particleTime,
          );
        }
      });
      if (letteringChanged) _restartParticles();
    }
    _updatePlayback();
    _scheduleRefresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _refreshDate();
    } else {
      _refreshTimer?.cancel();
      _updatePlayback();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _ticker.dispose();
    _particleTime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_date.isVisible) return const SizedBox.shrink();
    final preview = widget.previewDate?.toLocal();

    return Semantics(
      container: true,
      image: true,
      liveRegion: true,
      label: [
        if (preview != null) '미리보기, ${preview.month}월 ${preview.day}일 기준',
        _date.semanticsLabel,
      ].join(', '),
      child: RepaintBoundary(
        child: SizedBox(
          width: double.infinity,
          height: math.min(116, MediaQuery.sizeOf(context).height * 0.2),
          child: CustomPaint(painter: _painter),
        ),
      ),
    );
  }
}
