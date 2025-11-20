import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/meal_tracking_service.dart';
import '../models/user_goals.dart';
import '../themes/color_theme.dart';
import '../themes/text_theme.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isWeekly = true;
  List<DailyNutrition> _nutritionData = [];
  List<Map<String, dynamic>> _foodRanking = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final endDate = DateTime.now();
      final startDate = _isWeekly
          ? endDate.subtract(const Duration(days: 6))
          : endDate.subtract(const Duration(days: 29));

      final nutrition = _isWeekly
          ? await MealTrackingService.getWeeklyNutrition(endDate)
          : await MealTrackingService.getMonthlyNutrition(endDate);

      final ranking = await MealTrackingService.getFoodRanking(
        startDate,
        endDate,
      );

      setState(() {
        _nutritionData = nutrition;
        _foodRanking = ranking;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          '통계',
          style: TextStyle(color: Color(0xFF2C3E50)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodSelector(),
                  const SizedBox(height: 24),
                  _buildNutritionChart(),
                  const SizedBox(height: 24),
                  _buildFoodRanking(),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPeriodButton('주간', true),
          ),
          Expanded(
            child: _buildPeriodButton('월간', false),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, bool isWeekly) {
    final isSelected = _isWeekly == isWeekly;
    return GestureDetector(
      onTap: () {
        setState(() => _isWeekly = isWeekly);
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '영양소 섭취 현황',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: _nutritionData.isEmpty
                ? _buildEmptyChart()
                : _buildBarChart(),
          ),
          const SizedBox(height: 16),
          _buildChartLegend(),
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '데이터가 없습니다',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxY(),
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (_isWeekly) {
                  const days = ['월', '화', '수', '목', '금', '토', '일'];
                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                    return Text(
                      days[value.toInt()],
                      style: const TextStyle(fontSize: 12),
                    );
                  }
                } else {
                  // 월간은 날짜만 표시
                  if (value.toInt() % 5 == 0) {
                    return Text(
                      '${value.toInt() + 1}',
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: _buildBarGroups(),
      ),
    );
  }

  double _getMaxY() {
    double max = 0;
    for (var nutrition in _nutritionData) {
      if (nutrition.carbs > max) max = nutrition.carbs;
      if (nutrition.protein > max) max = nutrition.protein;
      if (nutrition.fat > max) max = nutrition.fat;
    }
    return max * 1.2;
  }

  List<BarChartGroupData> _buildBarGroups() {
    return _nutritionData.asMap().entries.map((entry) {
      final index = entry.key;
      final nutrition = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: nutrition.carbs,
            color: Colors.orange,
            width: _isWeekly ? 8 : 3,
          ),
          BarChartRodData(
            toY: nutrition.protein,
            color: Colors.blue,
            width: _isWeekly ? 8 : 3,
          ),
          BarChartRodData(
            toY: nutrition.fat,
            color: Colors.pink,
            width: _isWeekly ? 8 : 3,
          ),
        ],
      );
    }).toList();
  }

  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('탄수화물', Colors.orange),
        const SizedBox(width: 16),
        _buildLegendItem('단백질', Colors.blue),
        const SizedBox(width: 16),
        _buildLegendItem('지방', Colors.pink),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildFoodRanking() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '가장 많이 먹은 음식',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          if (_foodRanking.isEmpty)
            _buildEmptyRanking()
          else
            ..._foodRanking.asMap().entries.map((entry) {
              final index = entry.key;
              final food = entry.value;
              return _buildRankingItem(index + 1, food);
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyRanking() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          '데이터가 없습니다',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildRankingItem(int rank, Map<String, dynamic> food) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rank <= 3
            ? _getRankColor(rank).withOpacity(0.1)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: rank <= 3 ? _getRankColor(rank) : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          _buildRankBadge(rank),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food['name'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${food['count']}회 섭취',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(food['calories'] as num).toInt()} kcal',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    if (rank <= 3) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getRankGradient(rank),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            _getRankIcon(rank),
            style: const TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$rank',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  List<Color> _getRankGradient(int rank) {
    switch (rank) {
      case 1:
        return [const Color(0xFFFFD700), const Color(0xFFFFA500)];
      case 2:
        return [const Color(0xFFC0C0C0), const Color(0xFF808080)];
      case 3:
        return [const Color(0xFFCD7F32), const Color(0xFF8B4513)];
      default:
        return [Colors.grey, Colors.grey];
    }
  }

  String _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }
}
