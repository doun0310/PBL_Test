class Meal {
  final String? id;
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final List<String> allergens;
  final String? imageUrl;
  final String? mealType; // breakfast, lunch, dinner
  final DateTime? timestamp;

  Meal({
    this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.allergens,
    this.imageUrl,
    this.mealType,
    this.timestamp,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id']?.toString(),
      name: json['name'] as String,
      calories: json['calories'] is int ? json['calories'] : int.parse(json['calories'].toString()),
      protein: json['protein'] is int ? json['protein'] : int.parse(json['protein'].toString()),
      carbs: json['carbs'] is int ? json['carbs'] : int.parse(json['carbs'].toString()),
      fat: json['fat'] is int ? json['fat'] : int.parse(json['fat'].toString()),
      allergens: json['allergens'] != null ? List<String>.from(json['allergens'] as List) : [],
      imageUrl: json['imageUrl'] as String?,
      mealType: json['mealType'] as String?,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'allergens': allergens,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (mealType != null) 'mealType': mealType,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    };
  }

  Meal copyWith({
    String? id,
    String? name,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    List<String>? allergens,
    String? imageUrl,
    String? mealType,
    DateTime? timestamp,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      allergens: allergens ?? this.allergens,
      imageUrl: imageUrl ?? this.imageUrl,
      mealType: mealType ?? this.mealType,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class DailyMeal {
  final String date;
  final List<Meal> breakfast;
  final List<Meal> lunch;
  final List<Meal> dinner;

  DailyMeal({
    required this.date,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  factory DailyMeal.fromJson(Map<String, dynamic> json) {
    return DailyMeal(
      date: json['date'] as String,
      breakfast: (json['breakfast'] as List)
          .map((meal) => Meal.fromJson(meal))
          .toList(),
      lunch: (json['lunch'] as List)
          .map((meal) => Meal.fromJson(meal))
          .toList(),
      dinner: (json['dinner'] as List)
          .map((meal) => Meal.fromJson(meal))
          .toList(),
    );
  }
}
