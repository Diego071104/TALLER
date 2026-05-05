import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_fisiologico/app.dart';
import 'package:proyecto_fisiologico/data/services/ecg_socket_service.dart';
import 'package:proyecto_fisiologico/state/connection_provider.dart';
import 'package:proyecto_fisiologico/state/ecg_stream_provider.dart';
import 'package:proyecto_fisiologico/state/user_profile_provider.dart';

void main() {
  testWidgets('App boots into ConnectionScreen with header visible',
      (WidgetTester tester) async {
    final socket = EcgSocketService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ConnectionProvider(socket)),
          ChangeNotifierProvider(create: (_) => EcgStreamProvider(socket)),
          ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ],
        child: const VitalApp(),
      ),
    );
    expect(find.text('VitalSync'), findsOneWidget);
    expect(find.text('Conectar al sensor'), findsOneWidget);
    await socket.dispose();
  });
}
