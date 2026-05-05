import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'ui/screens/connection_screen.dart';

class VitalApp extends StatelessWidget {
  const VitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitalSync — Monitor ECG',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const ConnectionScreen(),
    );
  }
}
