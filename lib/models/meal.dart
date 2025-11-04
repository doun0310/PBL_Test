class Meal {
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final List<String> allergens;

  Meal({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.allergens,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      name: json['name'] as String,
      calories: json['calories'] as int,
      protein: json['protein'] as int,
      carbs: json['carbs'] as int,
      fat: json['fat'] as int,
      allergens: List<String>.from(json['allergens'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'allergens': allergens,
    };
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
