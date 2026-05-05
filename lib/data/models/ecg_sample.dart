/// One ECG voltage sample at a moment in time. Streamed at sample_rate Hz
/// (typically 250) over the simulator WebSocket.
class EcgSample {
  final double timestamp;
  final double mv;

  const EcgSample({required this.timestamp, required this.mv});

  factory EcgSample.fromJson(Map<String, dynamic> json) => EcgSample(
        timestamp: (json['ts'] as num).toDouble(),
        mv: (json['mv'] as num).toDouble(),
      );
}
