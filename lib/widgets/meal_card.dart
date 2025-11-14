import 'package:flutter/material.dart';
import '../models/meal_entry.dart';
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('HH:mm').format(meal.timestamp),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
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
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          '${foodEntry.totalCalories.toInt()} kcal',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )),
              const Divider(height: 24),
              // 영양 정보 요약
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
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
        color = Colors.orange;
        break;
      case MealType.lunch:
        icon = Icons.wb_sunny_outlined;
        color = Colors.amber;
        break;
      case MealType.dinner:
        icon = Icons.nights_stay;
        color = Colors.indigo;
        break;
      case MealType.snack:
        icon = Icons.cookie_outlined;
        color = Colors.pink;
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
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
