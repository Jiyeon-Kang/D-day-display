import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'particle_forest.dart';

class ParticleTreePage extends StatefulWidget {
  const ParticleTreePage({super.key});

  @override
  State<ParticleTreePage> createState() => _ParticleTreePageState();
}

class _ParticleTreePageState extends State<ParticleTreePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _time = ValueNotifier<double>(0);
  late final Ticker _ticker;
  late final ParticleForestPainter _painter;
  Duration? _lastElapsed;
  bool _paused = false;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    final binding = WidgetsBinding.instance;
    binding.addObserver(this);
    _foreground = binding.lifecycleState == null ||
        binding.lifecycleState == AppLifecycleState.resumed;
    _painter = ParticleForestPainter(time: _time);
    _ticker = createTicker(_onTick);
    _updatePlayback();
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
    if (_paused) {
      setState(() => _paused = false);
    }
    _updatePlayback();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _updatePlayback();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
            Semantics(
              image: true,
              label: '눈 내리는 숲에서 입자가 세 그루의 트리로 모입니다',
              child: RepaintBoundary(
                child: CustomPaint(painter: _painter),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: math.max(52.0, MediaQuery.paddingOf(context).bottom + 16),
              child: Wrap(
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
            ),
          ],
        ),
      ),
    );
  }
}
