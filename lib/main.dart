import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/services/ecg_signal_service.dart';
import 'state/connection_provider.dart';
import 'state/ecg_stream_provider.dart';
import 'state/user_profile_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final signal = EcgSignalService();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectionProvider(signal)),
        ChangeNotifierProvider(create: (_) => EcgStreamProvider(signal)),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
      ],
      child: const VitalApp(),
    ),
  );
}
