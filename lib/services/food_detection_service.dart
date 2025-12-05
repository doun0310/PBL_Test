import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// 탐지된 객체 정보를 담는 클래스
class Detection {
  final String className;
  final double confidence;
  final Rect boundingBox;

  Detection({
    required this.className,
    required this.confidence,
    required this.boundingBox,
  });
}

class FoodDetectionService {
  Interpreter? _interpreter;
  List<String>? _labels;

  // YOLOv8 모델 설정
  static const int inputSize = 640;
  static const double confidenceThreshold = 0.5; // 신뢰도 임계값
  static const double iouThreshold = 0.45; // IOU 임계값 (NMS용)

  /// 모델과 라벨을 로드하여 초기화합니다.
  Future<void> loadModel() async {
    try {
      // TFLite 모델 로드
      _interpreter = await Interpreter.fromAsset('assets/models/best_float32.tflite');

      // 라벨 파일 로드 (한글 라벨)
      final labelsData = await rootBundle.loadString('assets/labels/food_labels.txt');
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();

      print('✅ YOLO 모델 로드 완료: ${_labels?.length} 클래스');
    } catch (e) {
      print('❌ 모델 로드 실패: $e');
      rethrow;
    }
  }

  /// 이미지를 전처리하고 텐서로 변환합니다.
  Future<List<List<List<List<double>>>>> _preprocessImage(File imageFile) async {
    final imageData = await imageFile.readAsBytes();
    final image = img.decodeImage(imageData)!;

    // 이미지를 640x640으로 리사이즈
    final resizedImage = img.copyResize(image, width: inputSize, height: inputSize);

    // 이미지를 [1, 640, 640, 3] 형태의 텐서로 변환하고 정규화
    final imageMatrix = List.generate(
      inputSize,
          (y) => List.generate(
        inputSize,
            (x) {
          final pixel = resizedImage.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        },
      ),
    );

    return [imageMatrix];
  }

  /// 이미지 파일에서 객체를 탐지합니다.
  Future<List<Detection>> detectObjects(File imageFile) async {
    if (_interpreter == null || _labels == null) {
      print('모델이 로드되지 않았습니다.');
      return [];
    }

    final originalImage = img.decodeImage(await imageFile.readAsBytes())!;
    final originalWidth = originalImage.width;
    final originalHeight = originalImage.height;

    // 1. 이미지 전처리
    final input = await _preprocessImage(imageFile);

    // 2. 모델 추론
    // YOLOv8 출력 형태: [1, 4 + num_classes, 8400]
    // 4: cx, cy, w, h
    final output = List.filled(1 * (_labels!.length + 4) * 8400, 0.0)
        .reshape([1, _labels!.length + 4, 8400]);

    _interpreter!.run(input, output);

    // 3. 출력 후처리
    final List<Rect> boxes = [];
    final List<double> confidences = [];
    final List<int> classIndexes = [];

    final transposedOutput = _transpose(output[0]); // [8400, 4 + num_classes]

    for (var i = 0; i < transposedOutput.length; i++) {
      final row = transposedOutput[i];
      final score = row.sublist(4).reduce(max); // 가장 높은 클래스 점수

      if (score > confidenceThreshold) {
        final classId = row.sublist(4).indexOf(score);
        final confidence = row[4 + classId];

        final cx = row[0];
        final cy = row[1];
        final w = row[2];
        final h = row[3];

        // 원본 이미지 비율에 맞게 좌표 변환
        final scaleX = originalWidth / inputSize;
        final scaleY = originalHeight / inputSize;

        final left = (cx - w / 2) * scaleX;
        final top = (cy - h / 2) * scaleY;
        final width = w * scaleX;
        final height = h * scaleY;

        boxes.add(Rect.fromLTWH(left, top, width, height));
        confidences.add(confidence);
        classIndexes.add(classId);
      }
    }

    // 4. NMS (Non-Maximum Suppression) 적용
    final nmsIndexes = _nonMaximumSuppression(boxes, confidences, iouThreshold);

    final List<Detection> detections = [];
    for (final index in nmsIndexes) {
      detections.add(
        Detection(
          className: _labels![classIndexes[index]],
          confidence: confidences[index],
          boundingBox: boxes[index],
        ),
      );
    }

    return detections;
  }

  /// 2D 리스트를 전치(transpose)합니다.
  List<List<double>> _transpose(List<List<double>> matrix) {
    final rows = matrix.length;
    final cols = matrix[0].length;
    final transposed = List.generate(cols, (_) => List<double>.filled(rows, 0.0));
    for (var i = 0; i < rows; i++) {
      for (var j = 0; j < cols; j++) {
        transposed[j][i] = matrix[i][j];
      }
    }
    return transposed;
  }

  /// 두 경계 상자 간의 IOU(Intersection over Union)를 계산합니다.
  double _calculateIoU(Rect box1, Rect box2) {
    final intersectionLeft = max(box1.left, box2.left);
    final intersectionTop = max(box1.top, box2.top);
    final intersectionRight = min(box1.right, box2.right);
    final intersectionBottom = min(box1.bottom, box2.bottom);

    final intersectionArea = max(0, intersectionRight - intersectionLeft) *
        max(0, intersectionBottom - intersectionTop);

    final box1Area = box1.width * box1.height;
    final box2Area = box2.width * box2.height;

    final unionArea = box1Area + box2Area - intersectionArea;

    return intersectionArea / unionArea;
  }

  /// NMS(Non-Maximum Suppression)를 수행하여 중복된 경계 상자를 제거합니다.
  List<int> _nonMaximumSuppression(List<Rect> boxes, List<double> scores, double iouThreshold) {
    var indices = List<int>.generate(scores.length, (i) => i);
    indices.sort((a, b) => scores[b].compareTo(scores[a]));

    final List<int> keep = [];
    while (indices.isNotEmpty) {
      final i = indices.removeAt(0);
      keep.add(i);

      indices = indices.where((j) {
        final iou = _calculateIoU(boxes[i], boxes[j]);
        return iou <= iouThreshold;
      }).toList();
    }
    return keep;
  }

  /// 인터프리터를 해제합니다.
  void dispose() {
    _interpreter?.close();
  }
}
