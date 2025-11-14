class NutritionGoals {
  final int calorieGoal;
  final int proteinGoal;
  final int carbsGoal;
  final int fatGoal;

  NutritionGoals({
    required this.calorieGoal,
    required this.proteinGoal,
    required this.carbsGoal,
    required this.fatGoal,
  });

  factory NutritionGoals.fromJson(Map<String, dynamic> json) {
    return NutritionGoals(
      calorieGoal: json['calorieGoal'] as int,
      proteinGoal: json['proteinGoal'] as int,
      carbsGoal: json['carbsGoal'] as int,
      fatGoal: json['fatGoal'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calorieGoal': calorieGoal,
      'proteinGoal': proteinGoal,
      'carbsGoal': carbsGoal,
      'fatGoal': fatGoal,
    };
  }

  // Default goals for an average adult
  factory NutritionGoals.defaultGoals() {
    return NutritionGoals(
      calorieGoal: 2000,
      proteinGoal: 50,
      carbsGoal: 275,
      fatGoal: 65,
    );
  }

  NutritionGoals copyWith({
    int? calorieGoal,
    int? proteinGoal,
    int? carbsGoal,
    int? fatGoal,
  }) {
    return NutritionGoals(
      calorieGoal: calorieGoal ?? this.calorieGoal,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      carbsGoal: carbsGoal ?? this.carbsGoal,
      fatGoal: fatGoal ?? this.fatGoal,
    );
  }
}

class DailyNutritionSummary {
  final int totalCalories;
  final int totalProtein;
  final int totalCarbs;
  final int totalFat;
  final NutritionGoals goals;

  DailyNutritionSummary({
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.goals,
  });

  double get calorieProgress => totalCalories / goals.calorieGoal;
  double get proteinProgress => totalProtein / goals.proteinGoal;
  double get carbsProgress => totalCarbs / goals.carbsGoal;
  double get fatProgress => totalFat / goals.fatGoal;

  int get remainingCalories => goals.calorieGoal - totalCalories;
  int get remainingProtein => goals.proteinGoal - totalProtein;
  int get remainingCarbs => goals.carbsGoal - totalCarbs;
  int get remainingFat => goals.fatGoal - totalFat;
}
