import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/analytics_service.dart';
import '../models/meal_analytics.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MealAnalytics? _weeklyData;
  MealAnalytics? _monthlyData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final weekly = await AnalyticsService.getWeeklyAnalytics();
      final monthly = await AnalyticsService.getMonthlyAnalytics();

      setState(() {
        _weeklyData = weekly;
        _monthlyData = monthly;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('데이터 로딩 오류: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('식단 분석'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '주간 분석'),
            Tab(text: '월간 분석'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAnalyticsView(_weeklyData, isWeekly: true),
                _buildAnalyticsView(_monthlyData, isWeekly: false),
              ],
            ),
    );
  }

  Widget _buildAnalyticsView(MealAnalytics? data, {required bool isWeekly}) {
    if (data == null) {
      return const Center(
        child: Text('데이터가 없습니다'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 총 칼로리
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      isWeekly ? '주간 총 칼로리' : '월간 총 칼로리',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${data.totalCalories.toStringAsFixed(0)} kcal',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 영양소 비율 파이 차트
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '영양소 비율',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: _createPieChartSections(data),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLegend(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 일별 칼로리 막대 그래프
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isWeekly ? '요일별 칼로리' : '일별 칼로리',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: data.dailyCalories.values.isNotEmpty
                              ? data.dailyCalories.values.reduce((a, b) => a > b ? a : b) * 1.2
                              : 2000,
                          barGroups: _createBarChartGroups(data.dailyCalories),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  final keys = data.dailyCalories.keys.toList();
                                  if (index >= 0 && index < keys.length) {
                                    return Text(
                                      keys[index],
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 인기 음식 순위
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '자주 먹은 음식 TOP 5',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...data.topFoods.asMap().entries.map((entry) {
                      final index = entry.key;
                      final food = entry.value;
                      return _buildFoodRankItem(index + 1, food.name, food.count);
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _createPieChartSections(MealAnalytics data) {
    final total = data.totalProtein + data.totalCarbs + data.totalFat;
    if (total == 0) return [];

    return [
      PieChartSectionData(
        value: data.totalProtein,
        title: '${(data.totalProtein / total * 100).toStringAsFixed(1)}%',
        color: Colors.red,
        radius: 80,
      ),
      PieChartSectionData(
        value: data.totalCarbs,
        title: '${(data.totalCarbs / total * 100).toStringAsFixed(1)}%',
        color: Colors.yellow[700],
        radius: 80,
      ),
      PieChartSectionData(
        value: data.totalFat,
        title: '${(data.totalFat / total * 100).toStringAsFixed(1)}%',
        color: Colors.blue,
        radius: 80,
      ),
    ];
  }

  List<BarChartGroupData> _createBarChartGroups(Map<String, double> dailyCalories) {
    return dailyCalories.entries.map((entry) {
      final index = dailyCalories.keys.toList().indexOf(entry.key);
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: Colors.blue,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem(Colors.red, '단백질'),
        _buildLegendItem(Colors.yellow[700]!, '탄수화물'),
        _buildLegendItem(Colors.blue, '지방'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildFoodRankItem(int rank, String name, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank <= 3 ? Colors.amber : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            '$count회',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
