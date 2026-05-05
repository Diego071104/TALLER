import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/services/ecg_socket_service.dart';
import 'state/connection_provider.dart';
import 'state/ecg_stream_provider.dart';
import 'state/user_profile_provider.dart';

void main() {
  final socket = EcgSocketService();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectionProvider(socket)),
        ChangeNotifierProvider(create: (_) => EcgStreamProvider(socket)),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
      ],
      child: const VitalApp(),
    ),
  );
}
