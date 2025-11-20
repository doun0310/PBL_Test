import 'package:flutter/material.dart';
import '../models/meal_entry.dart';
import '../themes/color_theme.dart';
import '../themes/text_theme.dart';
import 'package:intl/intl.dart';

class MealCard extends StatelessWidget {
  final MealEntry meal;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const MealCard({
    super.key,
    required this.meal,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildMealTypeIcon(),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meal.mealType.displayName,
                            style: mealTitle,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('HH:mm').format(meal.timestamp),
                            style: mealSubTitle,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: redTwo),
                      onPressed: onDelete,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // 음식 목록
              ...meal.foodItems.map((foodEntry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${foodEntry.foodItem.name} (${foodEntry.servingSize.toInt()}${foodEntry.foodItem.unit})',
                            style: cardContent,
                          ),
                        ),
                        Text(
                          '${foodEntry.totalCalories.toInt()} kcal',
                          style: cardContent.copyWith(color: dalgeurakGrayFour),
                        ),
                      ],
                    ),
                  )),
              const Divider(height: 24),
              // 영양 정보 요약
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: dalgeurakBlueOne.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNutrientInfo(
                      '칼로리',
                      '${meal.totalCalories.toInt()}',
                      'kcal',
                    ),
                    _buildNutrientInfo(
                      '탄수화물',
                      '${meal.totalCarbs.toInt()}',
                      'g',
                    ),
                    _buildNutrientInfo(
                      '단백질',
                      '${meal.totalProtein.toInt()}',
                      'g',
                    ),
                    _buildNutrientInfo(
                      '지방',
                      '${meal.totalFat.toInt()}',
                      'g',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealTypeIcon() {
    IconData icon;
    Color color;

    switch (meal.mealType) {
      case MealType.breakfast:
        icon = Icons.wb_sunny;
        color = yellowThree;
        break;
      case MealType.lunch:
        icon = Icons.wb_sunny_outlined;
        color = yellowOne;
        break;
      case MealType.dinner:
        icon = Icons.nights_stay;
        color = blueFive;
        break;
      case MealType.snack:
        icon = Icons.cookie_outlined;
        color = pinkOne;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildNutrientInfo(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: cardSubTitle.copyWith(fontSize: 11),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: cardTitle.copyWith(fontSize: 16),
              ),
              TextSpan(
                text: ' $unit',
                style: cardSubTitle.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
