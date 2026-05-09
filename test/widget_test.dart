import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_fisiologico/app.dart';
import 'package:proyecto_fisiologico/data/services/ecg_signal_service.dart';
import 'package:proyecto_fisiologico/state/connection_provider.dart';
import 'package:proyecto_fisiologico/state/ecg_stream_provider.dart';
import 'package:proyecto_fisiologico/state/user_profile_provider.dart';

void main() {
  testWidgets('App boots into ConnectionScreen with ESP32 connection UI visible', (
    WidgetTester tester,
  ) async {
    final signal = EcgSignalService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ConnectionProvider(signal)),
          ChangeNotifierProvider(create: (_) => EcgStreamProvider(signal)),
          ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ],
        child: const VitalApp(),
      ),
    );
    expect(find.text('VitalSync'), findsOneWidget);
    expect(find.text('ESP32 ECG por Bluetooth'), findsOneWidget);
    await signal.dispose();
  });
}
