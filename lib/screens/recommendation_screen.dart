import 'package:flutter/material.dart';
import '../models/food_recommendation.dart';
import '../models/user_goals.dart';
import '../services/recommendation_service.dart';
import '../services/auth_service.dart';
import '../services/meal_tracking_service.dart';

/// Food Recommendation Screen
/// Shows personalized food recommendations using collaborative filtering
class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({Key? key}) : super(key: key);

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late RecommendationService _recommendationService;
  final AuthService _authService = AuthService();
  final MealTrackingService _mealService = MealTrackingService();

  List<FoodRecommendation> _nutritionRecommendations = [];
  List<FoodRecommendation> _collaborativeRecommendations = [];
  List<FoodRecommendation> _popularRecommendations = [];

  bool _isLoading = false;
  bool _serverHealthy = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _recommendationService = RecommendationService();
    _checkServerAndLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _recommendationService.dispose();
    super.dispose();
  }

  Future<void> _checkServerAndLoad() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check server health
      final healthy = await _recommendationService.checkHealth();
      setState(() {
        _serverHealthy = healthy;
      });

      if (!healthy) {
        setState(() {
          _errorMessage = '추천 서버에 연결할 수 없습니다.\n서버가 실행 중인지 확인해주세요.';
          _isLoading = false;
        });
        return;
      }

      // Load recommendations
      await _loadRecommendations();
    } catch (e) {
      setState(() {
        _errorMessage = '추천을 불러오는 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get user goals for nutrition-based recommendations
      final goals = await _mealService.getUserGoals();

      // Get nutrition recommendations
      final nutritionRecs = await _recommendationService.getNutritionRecommendations(
        targetCalories: goals?.targetCalories ?? 500,
        targetCarbs: goals?.targetCarbs ?? 50,
        targetProtein: goals?.targetProtein ?? 30,
        targetFat: goals?.targetFat ?? 15,
      );

      // Get collaborative recommendations
      final user = await _authService.getCurrentUser();
      final collaborativeRecs = user != null
          ? await _recommendationService.getCollaborativeRecommendations(
              userId: user.id)
          : <FoodRecommendation>[];

      // Get popular recommendations
      final popularRecs = await _recommendationService.getPopularRecommendations();

      setState(() {
        _nutritionRecommendations = nutritionRecs;
        _collaborativeRecommendations = collaborativeRecs;
        _popularRecommendations = popularRecs;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '추천을 불러오는 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('음식 추천'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant_menu), text: '영양 기반'),
            Tab(icon: Icon(Icons.person), text: '맞춤 추천'),
            Tab(icon: Icon(Icons.star), text: '인기 음식'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkServerAndLoad,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('추천을 불러오는 중...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _checkServerAndLoad,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
              const SizedBox(height: 16),
              Text(
                '추천 서버 시작 방법:\npython ml_training/api_servers/recommendation_server.py',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    if (!_serverHealthy) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            const Text('추천 서버가 실행 중이 아닙니다'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _checkServerAndLoad,
              child: const Text('다시 확인'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildNutritionTab(),
        _buildCollaborativeTab(),
        _buildPopularTab(),
      ],
    );
  }

  Widget _buildNutritionTab() {
    if (_nutritionRecommendations.isEmpty) {
      return const Center(
        child: Text('영양 기반 추천을 찾을 수 없습니다'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _nutritionRecommendations.length,
        itemBuilder: (context, index) {
          final rec = _nutritionRecommendations[index];
          return _buildRecommendationCard(rec, showScore: true);
        },
      ),
    );
  }

  Widget _buildCollaborativeTab() {
    if (_collaborativeRecommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            const Text('아직 맞춤 추천이 없습니다'),
            const SizedBox(height: 8),
            const Text(
              '음식에 평점을 매기면\n맞춤 추천이 제공됩니다',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _collaborativeRecommendations.length,
        itemBuilder: (context, index) {
          final rec = _collaborativeRecommendations[index];
          return _buildRecommendationCard(rec, showPredictedRating: true);
        },
      ),
    );
  }

  Widget _buildPopularTab() {
    if (_popularRecommendations.isEmpty) {
      return const Center(
        child: Text('인기 음식 추천을 찾을 수 없습니다'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _popularRecommendations.length,
        itemBuilder: (context, index) {
          final rec = _popularRecommendations[index];
          return _buildRecommendationCard(rec, showAvgRating: true);
        },
      ),
    );
  }

  Widget _buildRecommendationCard(
    FoodRecommendation rec, {
    bool showScore = false,
    bool showPredictedRating = false,
    bool showAvgRating = false,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    rec.name,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                if (showScore && rec.score != null)
                  Chip(
                    label: Text('점수: ${(rec.score! * 100).toStringAsFixed(0)}%'),
                    backgroundColor: theme.colorScheme.primaryContainer,
                  ),
                if (showPredictedRating && rec.predictedRating != null)
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(rec.predictedRating!.toStringAsFixed(1)),
                    ],
                  ),
                if (showAvgRating && rec.avgRating != null)
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(rec.avgRating!.toStringAsFixed(1)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildNutritionInfo(rec.nutrition, theme),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showRatingDialog(rec),
                  icon: const Icon(Icons.star_border),
                  label: const Text('평점 매기기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionInfo(FoodNutrition nutrition, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildNutritionChip('열량', '${nutrition.calories.toInt()} kcal', theme),
        _buildNutritionChip('탄수화물', '${nutrition.carbohydrates.toInt()}g', theme),
        _buildNutritionChip('단백질', '${nutrition.protein.toInt()}g', theme),
        _buildNutritionChip('지방', '${nutrition.fat.toInt()}g', theme),
      ],
    );
  }

  Widget _buildNutritionChip(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _showRatingDialog(FoodRecommendation rec) async {
    double rating = 3.0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('${rec.name} 평점 매기기'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('이 음식을 어떻게 평가하시겠습니까?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() {
                        rating = (index + 1).toDouble();
                      });
                    },
                  );
                }),
              ),
              Text(
                '${rating.toInt()}/5',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        final user = await _authService.getCurrentUser();
        if (user != null) {
          await _recommendationService.addRating(
            userId: user.id,
            foodId: rec.foodId,
            rating: rating,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('평점이 저장되었습니다')),
            );
            // Reload recommendations
            await _loadRecommendations();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('평점 저장 실패: $e')),
          );
        }
      }
    }
  }
}
