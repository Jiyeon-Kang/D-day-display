import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'particle_tree.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ParticleTreeApp());
}

class ParticleTreeApp extends StatelessWidget {
  const ParticleTreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    const preview = String.fromEnvironment('CHRISTMAS_PREVIEW_DATE');
    final previewDate = kDebugMode ? DateTime.tryParse(preview) : null;

    return MaterialApp(
      title: 'D-day-display',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xff050b12),
        useMaterial3: true,
      ),
      home: ParticleTreePage(previewDate: previewDate),
    );
  }
}
