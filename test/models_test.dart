import 'package:flutter_test/flutter_test.dart';
import 'package:meal_management_app/models/meal.dart';
import 'package:meal_management_app/models/nutrition_goals.dart';

void main() {
  group('Meal Model Tests', () {
    test('Meal should be created from JSON correctly', () {
      final json = {
        'id': '1',
        'name': 'Test Food',
        'calories': 300,
        'protein': 20,
        'carbs': 40,
        'fat': 10,
        'allergens': ['milk', 'eggs'],
        'imageUrl': 'http://example.com/image.jpg',
        'mealType': 'breakfast',
        'timestamp': '2024-11-14T10:00:00.000Z',
      };

      final meal = Meal.fromJson(json);

      expect(meal.id, '1');
      expect(meal.name, 'Test Food');
      expect(meal.calories, 300);
      expect(meal.protein, 20);
      expect(meal.carbs, 40);
      expect(meal.fat, 10);
      expect(meal.allergens, ['milk', 'eggs']);
      expect(meal.imageUrl, 'http://example.com/image.jpg');
      expect(meal.mealType, 'breakfast');
      expect(meal.timestamp, isNotNull);
    });

    test('Meal should convert to JSON correctly', () {
      final meal = Meal(
        id: '1',
        name: 'Test Food',
        calories: 300,
        protein: 20,
        carbs: 40,
        fat: 10,
        allergens: ['milk'],
        imageUrl: 'http://example.com/image.jpg',
        mealType: 'lunch',
        timestamp: DateTime.parse('2024-11-14T10:00:00.000Z'),
      );

      final json = meal.toJson();

      expect(json['id'], '1');
      expect(json['name'], 'Test Food');
      expect(json['calories'], 300);
      expect(json['protein'], 20);
      expect(json['carbs'], 40);
      expect(json['fat'], 10);
      expect(json['allergens'], ['milk']);
      expect(json['imageUrl'], 'http://example.com/image.jpg');
      expect(json['mealType'], 'lunch');
      expect(json['timestamp'], isNotNull);
    });

    test('Meal copyWith should work correctly', () {
      final original = Meal(
        name: 'Original',
        calories: 300,
        protein: 20,
        carbs: 40,
        fat: 10,
        allergens: [],
      );

      final updated = original.copyWith(
        name: 'Updated',
        calories: 400,
      );

      expect(updated.name, 'Updated');
      expect(updated.calories, 400);
      expect(updated.protein, 20); // unchanged
      expect(updated.carbs, 40); // unchanged
      expect(updated.fat, 10); // unchanged
    });
  });

  group('NutritionGoals Tests', () {
    test('NutritionGoals should be created correctly', () {
      final goals = NutritionGoals(
        calorieGoal: 2000,
        proteinGoal: 50,
        carbsGoal: 250,
        fatGoal: 70,
      );

      expect(goals.calorieGoal, 2000);
      expect(goals.proteinGoal, 50);
      expect(goals.carbsGoal, 250);
      expect(goals.fatGoal, 70);
    });

    test('Default nutrition goals should be created', () {
      final goals = NutritionGoals.defaultGoals();

      expect(goals.calorieGoal, 2000);
      expect(goals.proteinGoal, 50);
      expect(goals.carbsGoal, 275);
      expect(goals.fatGoal, 65);
    });

    test('NutritionGoals should convert to/from JSON', () {
      final goals = NutritionGoals(
        calorieGoal: 2000,
        proteinGoal: 50,
        carbsGoal: 250,
        fatGoal: 70,
      );

      final json = goals.toJson();
      final restored = NutritionGoals.fromJson(json);

      expect(restored.calorieGoal, goals.calorieGoal);
      expect(restored.proteinGoal, goals.proteinGoal);
      expect(restored.carbsGoal, goals.carbsGoal);
      expect(restored.fatGoal, goals.fatGoal);
    });
  });

  group('DailyNutritionSummary Tests', () {
    test('Progress calculations should be correct', () {
      final goals = NutritionGoals(
        calorieGoal: 2000,
        proteinGoal: 100,
        carbsGoal: 200,
        fatGoal: 50,
      );

      final summary = DailyNutritionSummary(
        totalCalories: 1000,
        totalProtein: 50,
        totalCarbs: 100,
        totalFat: 25,
        goals: goals,
      );

      expect(summary.calorieProgress, 0.5);
      expect(summary.proteinProgress, 0.5);
      expect(summary.carbsProgress, 0.5);
      expect(summary.fatProgress, 0.5);
    });

    test('Remaining calculations should be correct', () {
      final goals = NutritionGoals(
        calorieGoal: 2000,
        proteinGoal: 100,
        carbsGoal: 200,
        fatGoal: 50,
      );

      final summary = DailyNutritionSummary(
        totalCalories: 1500,
        totalProtein: 75,
        totalCarbs: 150,
        totalFat: 40,
        goals: goals,
      );

      expect(summary.remainingCalories, 500);
      expect(summary.remainingProtein, 25);
      expect(summary.remainingCarbs, 50);
      expect(summary.remainingFat, 10);
    });

    test('Negative remaining when exceeded', () {
      final goals = NutritionGoals(
        calorieGoal: 2000,
        proteinGoal: 100,
        carbsGoal: 200,
        fatGoal: 50,
      );

      final summary = DailyNutritionSummary(
        totalCalories: 2500,
        totalProtein: 120,
        totalCarbs: 250,
        totalFat: 60,
        goals: goals,
      );

      expect(summary.remainingCalories, -500);
      expect(summary.remainingProtein, -20);
      expect(summary.remainingCarbs, -50);
      expect(summary.remainingFat, -10);
    });
  });
}
