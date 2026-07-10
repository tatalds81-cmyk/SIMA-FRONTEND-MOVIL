class FacialSimaUnavailableException implements Exception {
  const FacialSimaUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FacialEmbeddingCapture {
  const FacialEmbeddingCapture({
    required this.embedding,
    required this.quality,
    required this.livenessResult,
    this.livenessScore,
    this.provider = 'sima_mobile_tflite_mlkit',
    this.modelVersion = 'mobilefacenet_tflite_v1',
  });

  final List<double> embedding;
  final int quality;
  final String livenessResult;
  final double? livenessScore;
  final String provider;
  final String modelVersion;
}

class FacialDetectionQuality {
  const FacialDetectionQuality({
    required this.score,
    required this.livenessResult,
  });

  final int score;
  final String livenessResult;
}
