import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_recommendation.dart';

/// Collaborative Filtering Recommendation Service
/// Integrates with the Python recommendation_server.py
class RecommendationService {
  final String baseUrl;
  final http.Client _client;

  RecommendationService({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? 'http://localhost:5001',
        _client = client ?? http.Client();

  /// Check if recommendation server is healthy
  Future<bool> checkHealth() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'healthy';
      }
      return false;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  /// Get nutrition-based recommendations
  /// Recommends foods based on target nutrition values
  Future<List<FoodRecommendation>> getNutritionRecommendations({
    required double targetCalories,
    required double targetCarbs,
    required double targetProtein,
    required double targetFat,
    int nRecommendations = 10,
    double tolerance = 0.2,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/recommend/nutrition'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'target_calories': targetCalories,
          'target_carbs': targetCarbs,
          'target_protein': targetProtein,
          'target_fat': targetFat,
          'n_recommendations': nRecommendations,
          'tolerance': tolerance,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final recommendationsList = data['recommendations'] as List;
          return recommendationsList
              .map((item) => FoodRecommendation.fromJson(item))
              .toList();
        } else {
          throw Exception(data['error'] ?? 'Unknown error');
        }
      } else {
        throw Exception(
            'Failed to get nutrition recommendations: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting nutrition recommendations: $e');
      rethrow;
    }
  }

  /// Get collaborative filtering recommendations
  /// Recommends foods based on user's rating history
  Future<List<FoodRecommendation>> getCollaborativeRecommendations({
    required String userId,
    int nRecommendations = 10,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/recommend/collaborative'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'n_recommendations': nRecommendations,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final recommendationsList = data['recommendations'] as List;
          return recommendationsList
              .map((item) => FoodRecommendation.fromJson(item))
              .toList();
        } else {
          throw Exception(data['error'] ?? 'Unknown error');
        }
      } else {
        throw Exception(
            'Failed to get collaborative recommendations: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting collaborative recommendations: $e');
      rethrow;
    }
  }

  /// Get popular food recommendations
  /// Returns most popular foods based on average ratings
  Future<List<FoodRecommendation>> getPopularRecommendations({
    int nRecommendations = 10,
  }) async {
    try {
      final response = await _client
          .get(
            Uri.parse(
                '$baseUrl/recommend/popular?n_recommendations=$nRecommendations'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final recommendationsList = data['recommendations'] as List;
          return recommendationsList
              .map((item) => FoodRecommendation.fromJson(item))
              .toList();
        } else {
          throw Exception(data['error'] ?? 'Unknown error');
        }
      } else {
        throw Exception(
            'Failed to get popular recommendations: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting popular recommendations: $e');
      rethrow;
    }
  }

  /// Add a user rating for a food
  Future<void> addRating({
    required String userId,
    required int foodId,
    required double rating,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/rating'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'food_id': foodId,
          'rating': rating,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['error'] ?? 'Failed to add rating');
        }
      } else {
        throw Exception('Failed to add rating: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding rating: $e');
      rethrow;
    }
  }

  /// Get details for a specific food
  Future<Map<String, dynamic>?> getFoodDetails(int foodId) async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/food/$foodId'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['food'];
        } else {
          throw Exception(data['error'] ?? 'Unknown error');
        }
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to get food details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting food details: $e');
      rethrow;
    }
  }

  /// Clean up resources
  void dispose() {
    _client.close();
  }
}
