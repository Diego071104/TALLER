/// One detected heartbeat (R peak). Carries the R-R interval since the
/// previous beat and the resulting instantaneous BPM.
class Beat {
  final double timestamp;
  final double rrMs;
  final double instantBpm;

  const Beat({
    required this.timestamp,
    required this.rrMs,
    required this.instantBpm,
  });

  factory Beat.fromJson(Map<String, dynamic> json) => Beat(
        timestamp: (json['ts'] as num).toDouble(),
        rrMs: (json['rr_ms'] as num).toDouble(),
        instantBpm: (json['instant_bpm'] as num).toDouble(),
      );
}
