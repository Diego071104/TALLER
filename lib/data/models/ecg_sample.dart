/// One ECG sample at a moment in time.
class EcgSample {
  final double timestamp;
  final double mv;
  final int? rawAdc;

  const EcgSample({
    required this.timestamp,
    required this.mv,
    this.rawAdc,
  });

  factory EcgSample.fromJson(Map<String, dynamic> json) => EcgSample(
        timestamp: (json['ts'] as num).toDouble(),
        mv: (json['mv'] as num).toDouble(),
        rawAdc: (json['adc'] as num?)?.toInt(),
      );
}
