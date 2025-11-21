import 'package:uuid/uuid.dart';

class ExerciseEntry {
  final String id;
  final DateTime timestamp;
  final String exerciseType;
  final int durationMinutes;
  final double caloriesBurned;
  final String? notes;

  ExerciseEntry({
    String? id,
    required this.timestamp,
    required this.exerciseType,
    required this.durationMinutes,
    required this.caloriesBurned,
    this.notes,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'exerciseType': exerciseType,
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'notes': notes,
    };
  }

  factory ExerciseEntry.fromJson(Map<String, dynamic> json) {
    return ExerciseEntry(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      exerciseType: json['exerciseType'],
      durationMinutes: json['durationMinutes'],
      caloriesBurned: json['caloriesBurned']?.toDouble() ?? 0.0,
      notes: json['notes'],
    );
  }

  ExerciseEntry copyWith({
    String? id,
    DateTime? timestamp,
    String? exerciseType,
    int? durationMinutes,
    double? caloriesBurned,
    String? notes,
  }) {
    return ExerciseEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      exerciseType: exerciseType ?? this.exerciseType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      notes: notes ?? this.notes,
    );
  }
}

class ExerciseType {
  final String name;
  final double caloriesPerMinute;
  final String icon;

  const ExerciseType({
    required this.name,
    required this.caloriesPerMinute,
    required this.icon,
  });

  static const List<ExerciseType> predefinedTypes = [
    ExerciseType(name: '걷기', caloriesPerMinute: 3.5, icon: '🚶'),
    ExerciseType(name: '조깅', caloriesPerMinute: 7.0, icon: '🏃'),
    ExerciseType(name: '자전거', caloriesPerMinute: 6.0, icon: '🚴'),
    ExerciseType(name: '수영', caloriesPerMinute: 8.0, icon: '🏊'),
    ExerciseType(name: '요가', caloriesPerMinute: 2.5, icon: '🧘'),
    ExerciseType(name: '근력 운동', caloriesPerMinute: 5.0, icon: '🏋️'),
    ExerciseType(name: '댄스', caloriesPerMinute: 6.5, icon: '💃'),
    ExerciseType(name: '등산', caloriesPerMinute: 7.5, icon: '⛰️'),
  ];
}
