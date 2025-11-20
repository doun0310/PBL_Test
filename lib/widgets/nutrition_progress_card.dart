import 'package:flutter/material.dart';
import '../models/user_goals.dart';
import '../themes/color_theme.dart';
import '../themes/text_theme.dart';

class NutritionProgressCard extends StatelessWidget {
  final DailyNutrition nutrition;
  final UserGoals goals;

  const NutritionProgressCard({
    super.key,
    required this.nutrition,
    required this.goals,
  });

  @override
  Widget build(BuildContext context) {
    final calorieProgress = nutrition.calories / goals.dailyCalorieGoal;
    final proteinProgress = nutrition.protein / goals.proteinGoal;
    final carbsProgress = nutrition.carbs / goals.carbsGoal;
    final fatProgress = nutrition.fat / goals.fatGoal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [dalgeurakBlueOne, blueFour],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: dalgeurakBlueOne.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // 칼로리 섹션
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '오늘의 칼로리',
                style: homeMenuWidgetTitle.copyWith(fontSize: 18),
              ),
              Text(
                '${nutrition.calories.toInt()} / ${goals.dailyCalorieGoal.toInt()} kcal',
                style: homeMenuWidgetTitle.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 칼로리 진행바
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: calorieProgress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          // 영양소 진행 정보
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNutrientProgress(
                '탄수화물',
                nutrition.carbs,
                goals.carbsGoal,
                carbsProgress,
                yellowThree,
              ),
              _buildNutrientProgress(
                '단백질',
                nutrition.protein,
                goals.proteinGoal,
                proteinProgress,
                blueTwo,
              ),
              _buildNutrientProgress(
                '지방',
                nutrition.fat,
                goals.fatGoal,
                fatProgress,
                pinkOne,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientProgress(
    String label,
    double current,
    double goal,
    double progress,
    Color color,
  ) {
    return Column(
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                strokeWidth: 6,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${current.toInt()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'g',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '${goal.toInt()}g',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
