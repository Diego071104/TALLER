import '../data/models/hr_zone.dart';
import '../data/models/user_profile.dart';

class ZoneRange {
  final HrZone zone;
  final int lowerBpm;
  final int upperBpm;

  const ZoneRange({required this.zone, required this.lowerBpm, required this.upperBpm});

  bool contains(double bpm) => bpm >= lowerBpm && bpm < upperBpm;
}

enum AlertSeverity { info, success, warning, danger }

class HealthAlert {
  final String title;
  final String message;
  final AlertSeverity severity;

  const HealthAlert({required this.title, required this.message, required this.severity});
}

class HealthAnalysis {
  final HrZone currentZone;
  final List<ZoneRange> zoneRanges;
  final List<HealthAlert> alerts;
  final double smoothedBpm;
  final double? rmssdMs;
  final double bmi;

  const HealthAnalysis({
    required this.currentZone,
    required this.zoneRanges,
    required this.alerts,
    required this.smoothedBpm,
    required this.rmssdMs,
    required this.bmi,
  });
}

/// Cardio analyzer using the Karvonen reserve method:
///   target_hr = ((max_hr - rest_hr) * intensity) + rest_hr
///
/// Zones used here (intensity bounds):
///   rest        : <30%  reserve
///   fat-burn    : 30-60% reserve
///   aerobic     : 60-75% reserve
///   anaerobic   : 75-90% reserve
///   max         : >=90% reserve
class HealthAnalyzer {
  const HealthAnalyzer();

  List<ZoneRange> zonesFor(UserProfile profile) {
    final maxHr = profile.maxHr;
    final restHr = profile.restingHr;
    final reserve = maxHr - restHr;

    int target(double intensity) => (restHr + intensity * reserve).round();

    return [
      ZoneRange(zone: HrZone.rest, lowerBpm: 0, upperBpm: target(0.30)),
      ZoneRange(zone: HrZone.fatBurn, lowerBpm: target(0.30), upperBpm: target(0.60)),
      ZoneRange(zone: HrZone.aerobic, lowerBpm: target(0.60), upperBpm: target(0.75)),
      ZoneRange(zone: HrZone.anaerobic, lowerBpm: target(0.75), upperBpm: target(0.90)),
      ZoneRange(zone: HrZone.max, lowerBpm: target(0.90), upperBpm: 9999),
    ];
  }

  HrZone classify(double bpm, List<ZoneRange> ranges) {
    for (final r in ranges) {
      if (r.contains(bpm)) return r.zone;
    }
    return ranges.last.zone;
  }

  HealthAnalysis analyze({
    required UserProfile profile,
    required double smoothedBpm,
    required double? rmssdMs,
  }) {
    final ranges = zonesFor(profile);
    final zone = classify(smoothedBpm, ranges);
    final alerts = <HealthAlert>[];

    if (smoothedBpm >= profile.maxHr) {
      alerts.add(HealthAlert(
        title: 'Frecuencia por encima de tu máxima teórica',
        message: 'BPM ($smoothedBpm) supera tu HR máx (${profile.maxHr}). '
            'Reduce intensidad de inmediato o detén el ejercicio.',
        severity: AlertSeverity.danger,
      ));
    }

    if (smoothedBpm < 40 && profile.activity != ActivityLevel.athlete) {
      alerts.add(const HealthAlert(
        title: 'Posible bradicardia',
        message: 'BPM por debajo de 40 sostenido. Si no eres atleta '
            'entrenado, consulta un médico para evaluación.',
        severity: AlertSeverity.danger,
      ));
    }

    if (zone == HrZone.max) {
      alerts.add(const HealthAlert(
        title: 'Zona máxima',
        message: 'Estás trabajando arriba del 90% de tu reserva. Solo '
            'mantenlo si estás en intervalos cortos planeados.',
        severity: AlertSeverity.warning,
      ));
    }

    if (rmssdMs != null && rmssdMs > 80) {
      alerts.add(HealthAlert(
        title: 'Variabilidad RR elevada',
        message: 'RMSSD ${rmssdMs.toStringAsFixed(1)} ms — variabilidad alta. '
            'Puede reflejar relajación profunda o, si va con palpitaciones, '
            'ritmo irregular. Mantén la observación.',
        severity: AlertSeverity.warning,
      ));
    }

    if (profile.bmi >= 30) {
      alerts.add(HealthAlert(
        title: 'IMC en rango de obesidad',
        message: 'IMC ${profile.bmi.toStringAsFixed(1)}. Combina entrenamiento '
            'aeróbico zona quema-grasa con plan nutricional supervisado.',
        severity: AlertSeverity.info,
      ));
    } else if (profile.bmi < 18.5) {
      alerts.add(HealthAlert(
        title: 'IMC bajo',
        message: 'IMC ${profile.bmi.toStringAsFixed(1)} — bajo peso. Revisa '
            'tu ingesta calórica y consulta nutriología.',
        severity: AlertSeverity.info,
      ));
    }

    if (zone == HrZone.fatBurn && alerts.isEmpty) {
      alerts.add(const HealthAlert(
        title: 'Zona quema-grasa',
        message: 'Excelente intensidad para sesiones largas — sostén este '
            'rango 30-45 min para optimizar oxidación de grasa.',
        severity: AlertSeverity.success,
      ));
    }

    if (zone == HrZone.aerobic && alerts.isEmpty) {
      alerts.add(const HealthAlert(
        title: 'Zona aeróbica',
        message: 'Buen estímulo cardiovascular. Mantén entre 20-40 min para '
            'mejorar capacidad aeróbica.',
        severity: AlertSeverity.success,
      ));
    }

    if (zone == HrZone.rest && alerts.isEmpty) {
      alerts.add(HealthAlert(
        title: 'Reposo',
        message: 'Tu HR está en zona de descanso. Si estás entrenando, '
            'sube intensidad para alcanzar al menos ${ranges[1].lowerBpm} BPM.',
        severity: AlertSeverity.info,
      ));
    }

    return HealthAnalysis(
      currentZone: zone,
      zoneRanges: ranges,
      alerts: alerts,
      smoothedBpm: smoothedBpm,
      rmssdMs: rmssdMs,
      bmi: profile.bmi,
    );
  }
}
