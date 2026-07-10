import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:sima_movil_froned/models/facial_biometrics_models.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class FacialEmbeddingEngine {
  FacialEmbeddingEngine._();

  static const List<_FacialModelConfig> _modelCandidates = [
    _FacialModelConfig(
      assetPath: 'assets/models/mobilefacenet.tflite',
      fallbackAssetPath: 'models/mobilefacenet.tflite',
      preprocessing: _FacialModelPreprocessing.symmetric,
      modelVersion: 'mobilefacenet_tflite_v1',
    ),
    _FacialModelConfig(
      assetPath: 'assets/models/facenet.tflite',
      fallbackAssetPath: 'models/facenet.tflite',
      preprocessing: _FacialModelPreprocessing.prewhiten,
      modelVersion: 'facenet_160_prewhiten_tflite_v1',
    ),
  ];
  static const int _minimumFacePixels = 90;
  static const int _minimumQuality = 40;

  static Interpreter? _interpreter;
  static _LoadedFacialModel? _loadedModel;
  static FaceDetector? _detector;

  static Future<FacialEmbeddingCapture> captureForEnrollment() {
    return _captureEmbedding(requireStrictLiveness: true);
  }

  static Future<FacialEmbeddingCapture> captureForEnrollmentWithPreview(
    CameraController controller,
  ) {
    return _captureEmbedding(
      requireStrictLiveness: true,
      previewController: controller,
    );
  }

  static Future<FacialEmbeddingCapture> captureForValidationWithPreview(
    CameraController controller,
  ) {
    return _captureEmbedding(
      requireStrictLiveness: false,
      previewController: controller,
    );
  }

  static Future<CameraController> createPreviewController() async {
    final camera = await _frontCamera();
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await controller.initialize();
    return controller;
  }

  static Future<FacialEmbeddingCapture> captureForValidation() {
    return _captureEmbedding(requireStrictLiveness: false);
  }

  static Future<FacialEmbeddingCapture> _captureEmbedding({
    required bool requireStrictLiveness,
    CameraController? previewController,
  }) async {
    final controller = previewController ?? await createPreviewController();
    final shouldDisposeController = previewController == null;

    XFile? capturedFile;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      capturedFile = await controller.takePicture();

      final inputImage = InputImage.fromFilePath(capturedFile.path);
      final faces = await _faceDetector().processImage(inputImage);
      if (faces.isEmpty) {
        throw const FacialSimaUnavailableException('No se detecto rostro.');
      }
      if (faces.length > 1) {
        throw const FacialSimaUnavailableException(
          'Se detectaron multiples rostros. Intenta de nuevo con una sola persona frente a la camara.',
        );
      }

      final bytes = await capturedFile.readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) {
        throw const FacialSimaUnavailableException('No fue posible procesar la imagen capturada.');
      }

      final face = faces.single;
      final quality = _evaluateFaceQuality(
        face,
        imageWidth: decodedImage.width,
        imageHeight: decodedImage.height,
        requireStrictLiveness: requireStrictLiveness,
      );
      if (quality.score < _minimumQuality) {
        throw FacialSimaUnavailableException(
          'Calidad facial baja (${quality.score}). Ajusta iluminacion, distancia y orientacion.',
        );
      }

      final faceCrop = _cropFace(decodedImage, face);
      final loadedModel = await _loadInterpreter();
      final resizedFace = img.copyResize(
        faceCrop,
        width: loadedModel.inputSize,
        height: loadedModel.inputSize,
        interpolation: img.Interpolation.linear,
      );
      final inputTensor = _imageToTensor(resizedFace, loadedModel);
      final embedding = await _runModel(inputTensor, loadedModel);

      return FacialEmbeddingCapture(
        embedding: embedding,
        quality: quality.score,
        livenessResult: quality.livenessResult,
        livenessScore: quality.score / 100,
        modelVersion: loadedModel.config.modelVersion,
      );
    } on CameraException catch (error) {
      throw FacialSimaUnavailableException(
        error.code == 'CameraAccessDenied'
            ? 'Permiso de camara denegado.'
            : 'Camara no disponible: ${error.description ?? error.code}',
      );
    } on PlatformException catch (error) {
      throw FacialSimaUnavailableException(
        'No fue posible usar el motor facial: ${error.message ?? error.code}',
      );
    } on FacialSimaUnavailableException {
      rethrow;
    } catch (error) {
      throw FacialSimaUnavailableException(
        'No fue posible generar el embedding facial. Detalle tecnico: $error',
      );
    } finally {
      if (shouldDisposeController) {
        await controller.dispose();
      }
      if (capturedFile != null) {
        await _deleteTemporaryCapture(capturedFile.path);
      }
    }
  }

  static Future<CameraDescription> _frontCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw const FacialSimaUnavailableException('No hay camaras disponibles en este dispositivo.');
    }

    return cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
  }

  static FaceDetector _faceDetector() {
    return _detector ??= FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: false,
        enableContours: false,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
  }

  static Future<_LoadedFacialModel> _loadInterpreter() async {
    if (_interpreter != null && _loadedModel != null) return _loadedModel!;

    for (final candidate in _modelCandidates) {
      final interpreter = await _tryLoadInterpreter(candidate.assetPath) ??
          await _tryLoadInterpreter(candidate.fallbackAssetPath);
      if (interpreter == null) continue;

      final inputShape = interpreter.getInputTensor(0).shape;
      final inputSize = _readSquareInputSize(inputShape);
      if (inputSize == null) {
        interpreter.close();
        throw FacialSimaUnavailableException(
          'El modelo facial ${candidate.fileName} no tiene entrada compatible [1, alto, ancho, 3].',
        );
      }

      _interpreter = interpreter;
      _loadedModel = _LoadedFacialModel(
        interpreter: interpreter,
        config: candidate,
        inputSize: inputSize,
      );
      return _loadedModel!;
    }

    throw const FacialSimaUnavailableException(
      'Modelo facial no encontrado. Coloca mobilefacenet.tflite o facenet.tflite en assets/models/ y ejecuta flutter pub get.',
    );
  }

  static Future<Interpreter?> _tryLoadInterpreter(String assetPath) async {
    try {
      return await Interpreter.fromAsset(assetPath);
    } catch (_) {
      return null;
    }
  }

  static int? _readSquareInputSize(List<int> shape) {
    if (shape.length != 4 || shape.last != 3) return null;
    final height = shape[1];
    final width = shape[2];
    if (height <= 0 || height != width) return null;
    return height;
  }

  static FacialDetectionQuality _evaluateFaceQuality(
    Face face, {
    required int imageWidth,
    required int imageHeight,
    required bool requireStrictLiveness,
  }) {
    final box = face.boundingBox;
    if (box.width < _minimumFacePixels || box.height < _minimumFacePixels) {
      throw const FacialSimaUnavailableException(
        'Rostro demasiado pequeno. Acerca el rostro a la camara.',
      );
    }

    final centerX = box.left + box.width / 2;
    final centerY = box.top + box.height / 2;
    final normalizedOffsetX = ((centerX - imageWidth / 2) / imageWidth).abs();
    final normalizedOffsetY = ((centerY - imageHeight / 2) / imageHeight).abs();
    if (normalizedOffsetX > 0.28 || normalizedOffsetY > 0.32) {
      throw const FacialSimaUnavailableException(
        'Rostro fuera de cuadro. Centra el rostro e intenta nuevamente.',
      );
    }

    final yaw = (face.headEulerAngleY ?? 0).abs();
    final roll = (face.headEulerAngleZ ?? 0).abs();
    final pitch = (face.headEulerAngleX ?? 0).abs();
    if (yaw > 25 || roll > 20 || pitch > 25) {
      throw const FacialSimaUnavailableException(
        'Orientacion facial no valida. Mira de frente a la camara.',
      );
    }

    final leftEye = face.leftEyeOpenProbability;
    final rightEye = face.rightEyeOpenProbability;
    if (requireStrictLiveness &&
        leftEye != null &&
        rightEye != null &&
        (leftEye < 0.45 || rightEye < 0.45)) {
      throw const FacialSimaUnavailableException(
        'Ojos cerrados o no visibles. Mira a la camara con los ojos abiertos.',
      );
    }

    final faceArea = box.width * box.height;
    final imageArea = imageWidth * imageHeight;
    final areaScore = ((faceArea / imageArea) * 420).clamp(0, 35).round();
    final centerScore =
        ((1 - (normalizedOffsetX + normalizedOffsetY)).clamp(0, 1) * 25).round();
    final orientationPenalty = ((yaw + roll + pitch) / 70 * 25).clamp(0, 25).round();
    final eyeScore = leftEye == null || rightEye == null
        ? 15
        : (((leftEye + rightEye) / 2).clamp(0, 1) * 15).round();

    final score = (35 + areaScore + centerScore + eyeScore - orientationPenalty)
        .clamp(0, 100)
        .round();

    return FacialDetectionQuality(
      score: score,
      livenessResult: score >= 70 ? 'PASSED' : 'BASIC_PASSED',
    );
  }

  static img.Image _cropFace(img.Image source, Face face) {
    final box = face.boundingBox;
    final paddingX = (box.width * 0.22).round();
    final paddingY = (box.height * 0.28).round();
    final x = math.max(0, box.left.round() - paddingX);
    final y = math.max(0, box.top.round() - paddingY);
    final right = math.min(source.width, box.right.round() + paddingX);
    final bottom = math.min(source.height, box.bottom.round() + paddingY);

    if (right <= x || bottom <= y) {
      throw const FacialSimaUnavailableException('No fue posible recortar el rostro detectado.');
    }

    final cropped = img.copyCrop(
      source,
      x: x,
      y: y,
      width: right - x,
      height: bottom - y,
    );

    return cropped;
  }

  static List<List<List<List<double>>>> _imageToTensor(
    img.Image faceImage,
    _LoadedFacialModel loadedModel,
  ) {
    if (loadedModel.config.preprocessing == _FacialModelPreprocessing.prewhiten) {
      return _imageToPrewhitenTensor(faceImage, loadedModel.inputSize);
    }

    return [
      List.generate(loadedModel.inputSize, (y) {
        return List.generate(loadedModel.inputSize, (x) {
          final pixel = faceImage.getPixel(x, y);
          return [
            (pixel.r.toDouble() - 127.5) / 127.5,
            (pixel.g.toDouble() - 127.5) / 127.5,
            (pixel.b.toDouble() - 127.5) / 127.5,
          ];
        });
      }),
    ];
  }

  static List<List<List<List<double>>>> _imageToPrewhitenTensor(
    img.Image faceImage,
    int inputSize,
  ) {
    final values = List<double>.filled(inputSize * inputSize * 3, 0);

    var cursor = 0;
    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        final pixel = faceImage.getPixel(x, y);
        values[cursor++] = pixel.r.toDouble();
        values[cursor++] = pixel.g.toDouble();
        values[cursor++] = pixel.b.toDouble();
      }
    }

    final mean = values.reduce((a, b) => a + b) / values.length;
    var variance = 0.0;
    for (var i = 0; i < values.length; i++) {
      values[i] -= mean;
      variance += values[i] * values[i];
    }
    final std = math.sqrt(variance / values.length);
    final stdAdjusted = math.max(std, 1.0 / math.sqrt(values.length));

    cursor = 0;
    return [
      List.generate(inputSize, (_) {
        return List.generate(inputSize, (_) {
          return [
            values[cursor++] / stdAdjusted,
            values[cursor++] / stdAdjusted,
            values[cursor++] / stdAdjusted,
          ];
        });
      }),
    ];
  }

  static Future<List<double>> _runModel(
    List<List<List<List<double>>>> inputTensor,
    _LoadedFacialModel loadedModel,
  ) async {
    final interpreter = loadedModel.interpreter;
    final outputShape = interpreter.getOutputTensor(0).shape;
    final outputLength = outputShape.isNotEmpty ? outputShape.last : 192;
    final output = [List<double>.filled(outputLength, 0)];

    try {
      interpreter.run(inputTensor, output);
    } catch (_) {
      throw const FacialSimaUnavailableException(
        'Error ejecutando inferencia facial TFLite. Verifica dimensiones del modelo.',
      );
    }

    return _normalizeEmbedding(output.first);
  }

  static List<double> _normalizeEmbedding(List<double> values) {
    var norm = 0.0;
    for (final value in values) {
      norm += value * value;
    }
    norm = math.sqrt(norm);
    if (norm == 0) {
      throw const FacialSimaUnavailableException('El modelo genero un embedding facial vacio.');
    }
    return values.map((value) => value / norm).toList(growable: false);
  }

  static Future<void> _deleteTemporaryCapture(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // No se registra la ruta ni contenido biometrico. El archivo temporal
      // queda bajo control del sistema si la eliminacion falla.
    }
  }
}

enum _FacialModelPreprocessing {
  symmetric,
  prewhiten,
}

class _FacialModelConfig {
  const _FacialModelConfig({
    required this.assetPath,
    required this.fallbackAssetPath,
    required this.preprocessing,
    required this.modelVersion,
  });

  final String assetPath;
  final String fallbackAssetPath;
  final _FacialModelPreprocessing preprocessing;
  final String modelVersion;

  String get fileName => assetPath.split('/').last;
}

class _LoadedFacialModel {
  const _LoadedFacialModel({
    required this.interpreter,
    required this.config,
    required this.inputSize,
  });

  final Interpreter interpreter;
  final _FacialModelConfig config;
  final int inputSize;
}
