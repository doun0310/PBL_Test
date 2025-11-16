class UserGoals {
  final double dailyCalorieGoal;
  final double proteinGoal; // g
  final double carbsGoal; // g
  final double fatGoal; // g
  final int mealsPerDay;

  UserGoals({
    this.dailyCalorieGoal = 2000,
    this.proteinGoal = 50,
    this.carbsGoal = 250,
    this.fatGoal = 65,
    this.mealsPerDay = 3,
  });

  factory UserGoals.fromJson(Map<String, dynamic> json) {
    return UserGoals(
      dailyCalorieGoal: (json['dailyCalorieGoal'] as num?)?.toDouble() ?? 2000,
      proteinGoal: (json['proteinGoal'] as num?)?.toDouble() ?? 50,
      carbsGoal: (json['carbsGoal'] as num?)?.toDouble() ?? 250,
      fatGoal: (json['fatGoal'] as num?)?.toDouble() ?? 65,
      mealsPerDay: json['mealsPerDay'] as int? ?? 3,
    );
  }

  get carbohydrateGoal => null;

  Map<String, dynamic> toJson() {
    return {
      'dailyCalorieGoal': dailyCalorieGoal,
      'proteinGoal': proteinGoal,
      'carbsGoal': carbsGoal,
      'fatGoal': fatGoal,
      'mealsPerDay': mealsPerDay,
    };
  }

  UserGoals copyWith({
    double? dailyCalorieGoal,
    double? proteinGoal,
    double? carbsGoal,
    double? fatGoal,
    int? mealsPerDay,
  }) {
    return UserGoals(
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      carbsGoal: carbsGoal ?? this.carbsGoal,
      fatGoal: fatGoal ?? this.fatGoal,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
    );
  }
}

class DailyNutrition {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  DailyNutrition({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
  });

  DailyNutrition copyWith({
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
  }) {
    return DailyNutrition(
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
    );
  }
}
