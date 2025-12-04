#!/usr/bin/env python3
"""
Collaborative Filtering Recommendation REST API Server
Nutrition-based food recommendation service

Usage:
    python recommendation_server.py --port 5001 --host 0.0.0.0
"""

import os
import sys
import argparse
import logging
from typing import Dict, List, Optional
from pathlib import Path

from flask import Flask, request, jsonify
from flask_cors import CORS
import pandas as pd
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter app

# Global model storage
food_database = None
user_ratings = None
nutrition_matrix = None
similarity_matrix = None


def load_sample_data():
    """
    Load sample food database and user ratings
    Replace this with actual database connections in production
    """
    global food_database, user_ratings, nutrition_matrix, similarity_matrix
    
    # Sample food database with Korean foods
    food_database = pd.DataFrame({
        'food_id': range(1, 21),
        'name': [
            '삼겹살', '된장찌개', '김치찌개', '비빔밥', '불고기',
            '갈비찜', '냉면', '순두부찌개', '떡볶이', '김밥',
            '치킨', '피자', '햄버거', '파스타', '샐러드',
            '과일', '요거트', '우유', '두부', '닭가슴살'
        ],
        'calories': [
            500, 200, 250, 450, 400,
            600, 350, 180, 380, 300,
            700, 800, 650, 550, 150,
            100, 120, 130, 80, 165
        ],
        'carbohydrates': [
            0, 10, 12, 80, 10,
            15, 70, 8, 78, 45,
            20, 90, 50, 75, 15,
            25, 18, 12, 2, 0
        ],
        'protein': [
            40, 15, 18, 12, 35,
            45, 10, 12, 6, 8,
            60, 30, 25, 20, 8,
            1, 6, 8, 10, 31
        ],
        'fat': [
            45, 8, 12, 8, 25,
            35, 5, 6, 10, 12,
            40, 50, 40, 20, 5,
            0, 2, 7, 5, 3.5
        ]
    })
    
    # Sample user ratings (user_id, food_id, rating)
    user_ratings = pd.DataFrame({
        'user_id': ['user_001'] * 10 + ['user_002'] * 8,
        'food_id': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 1, 3, 5, 7, 9, 11, 13, 15],
        'rating': [5, 4, 5, 3, 4, 5, 3, 4, 2, 3, 3, 5, 4, 5, 3, 5, 4, 4]
    })
    
    # Create nutrition matrix for similarity calculation
    nutrition_matrix = food_database[['calories', 'carbohydrates', 'protein', 'fat']].values
    
    # Normalize nutrition matrix
    from sklearn.preprocessing import StandardScaler
    scaler = StandardScaler()
    nutrition_matrix_normalized = scaler.fit_transform(nutrition_matrix)
    
    # Calculate cosine similarity
    similarity_matrix = cosine_similarity(nutrition_matrix_normalized)
    
    logger.info(f"Loaded {len(food_database)} foods and {len(user_ratings)} ratings")


def get_user_preferences(user_id: str) -> pd.DataFrame:
    """Get user's previous ratings"""
    return user_ratings[user_ratings['user_id'] == user_id]


def get_nutrition_based_recommendations(
    target_calories: float,
    target_carbs: float,
    target_protein: float,
    target_fat: float,
    n_recommendations: int = 10,
    tolerance: float = 0.2
) -> List[Dict]:
    """
    Get food recommendations based on nutrition targets
    
    Args:
        target_calories: Target calorie intake
        target_carbs: Target carbohydrates (g)
        target_protein: Target protein (g)
        target_fat: Target fat (g)
        n_recommendations: Number of recommendations to return
        tolerance: Tolerance for nutrition matching (0.2 = 20%)
    
    Returns:
        List of recommended foods with scores
    """
    recommendations = []
    
    for idx, food in food_database.iterrows():
        # Calculate nutrition matching score
        cal_diff = abs(food['calories'] - target_calories) / max(target_calories, 1)
        carb_diff = abs(food['carbohydrates'] - target_carbs) / max(target_carbs, 1)
        protein_diff = abs(food['protein'] - target_protein) / max(target_protein, 1)
        fat_diff = abs(food['fat'] - target_fat) / max(target_fat, 1)
        
        # Average difference (lower is better)
        avg_diff = (cal_diff + carb_diff + protein_diff + fat_diff) / 4
        
        # Convert to score (higher is better)
        score = 1.0 / (1.0 + avg_diff)
        
        # Filter by tolerance
        if avg_diff <= tolerance:
            recommendations.append({
                'food_id': int(food['food_id']),
                'name': food['name'],
                'score': float(score),
                'nutrition': {
                    'calories': float(food['calories']),
                    'carbohydrates': float(food['carbohydrates']),
                    'protein': float(food['protein']),
                    'fat': float(food['fat'])
                }
            })
    
    # Sort by score
    recommendations.sort(key=lambda x: x['score'], reverse=True)
    
    return recommendations[:n_recommendations]


def get_collaborative_recommendations(
    user_id: str,
    n_recommendations: int = 10
) -> List[Dict]:
    """
    Get collaborative filtering recommendations based on user history
    
    Args:
        user_id: User ID
        n_recommendations: Number of recommendations to return
    
    Returns:
        List of recommended foods with predicted ratings
    """
    # Get user's ratings
    user_prefs = get_user_preferences(user_id)
    
    if len(user_prefs) == 0:
        logger.warning(f"No ratings found for user {user_id}")
        # Return popular items
        return get_popular_recommendations(n_recommendations)
    
    # Get foods user hasn't rated
    rated_food_ids = set(user_prefs['food_id'].values)
    unrated_foods = food_database[~food_database['food_id'].isin(rated_food_ids)]
    
    recommendations = []
    
    for idx, food in unrated_foods.iterrows():
        # Calculate predicted rating based on similar foods
        food_idx = food['food_id'] - 1
        similarities = similarity_matrix[food_idx]
        
        # Weighted average of ratings for similar foods
        total_sim = 0
        total_weighted_rating = 0
        
        for _, rating_row in user_prefs.iterrows():
            rated_food_idx = rating_row['food_id'] - 1
            sim = similarities[rated_food_idx]
            total_sim += sim
            total_weighted_rating += sim * rating_row['rating']
        
        predicted_rating = total_weighted_rating / total_sim if total_sim > 0 else 2.5
        
        recommendations.append({
            'food_id': int(food['food_id']),
            'name': food['name'],
            'predicted_rating': float(predicted_rating),
            'nutrition': {
                'calories': float(food['calories']),
                'carbohydrates': float(food['carbohydrates']),
                'protein': float(food['protein']),
                'fat': float(food['fat'])
            }
        })
    
    # Sort by predicted rating
    recommendations.sort(key=lambda x: x['predicted_rating'], reverse=True)
    
    return recommendations[:n_recommendations]


def get_popular_recommendations(n_recommendations: int = 10) -> List[Dict]:
    """Get most popular foods based on average ratings"""
    # Calculate average ratings
    avg_ratings = user_ratings.groupby('food_id')['rating'].mean().reset_index()
    avg_ratings.columns = ['food_id', 'avg_rating']
    
    # Merge with food database
    popular_foods = food_database.merge(avg_ratings, on='food_id', how='left')
    popular_foods['avg_rating'] = popular_foods['avg_rating'].fillna(0)
    
    # Sort by rating
    popular_foods = popular_foods.sort_values('avg_rating', ascending=False)
    
    recommendations = []
    for idx, food in popular_foods.head(n_recommendations).iterrows():
        recommendations.append({
            'food_id': int(food['food_id']),
            'name': food['name'],
            'avg_rating': float(food['avg_rating']),
            'nutrition': {
                'calories': float(food['calories']),
                'carbohydrates': float(food['carbohydrates']),
                'protein': float(food['protein']),
                'fat': float(food['fat'])
            }
        })
    
    return recommendations


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'Collaborative Filtering Recommendation API',
        'data_loaded': food_database is not None
    })


@app.route('/recommend/nutrition', methods=['POST'])
def nutrition_based_recommendations():
    """
    Get recommendations based on nutrition targets
    
    Request body (JSON):
        {
            "target_calories": 500,
            "target_carbs": 50,
            "target_protein": 30,
            "target_fat": 15,
            "n_recommendations": 10,
            "tolerance": 0.2
        }
    
    Response:
        {
            "success": true,
            "recommendations": [...]
        }
    """
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({
                'success': False,
                'error': 'No JSON data provided'
            }), 400
        
        # Get parameters
        target_calories = data.get('target_calories', 500)
        target_carbs = data.get('target_carbs', 50)
        target_protein = data.get('target_protein', 30)
        target_fat = data.get('target_fat', 15)
        n_recommendations = data.get('n_recommendations', 10)
        tolerance = data.get('tolerance', 0.2)
        
        # Get recommendations
        recommendations = get_nutrition_based_recommendations(
            target_calories, target_carbs, target_protein, target_fat,
            n_recommendations, tolerance
        )
        
        return jsonify({
            'success': True,
            'recommendations': recommendations,
            'targets': {
                'calories': target_calories,
                'carbohydrates': target_carbs,
                'protein': target_protein,
                'fat': target_fat
            }
        })
        
    except Exception as e:
        logger.error(f"Error in nutrition recommendations: {e}", exc_info=True)
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/recommend/collaborative', methods=['POST'])
def collaborative_recommendations():
    """
    Get collaborative filtering recommendations
    
    Request body (JSON):
        {
            "user_id": "user_001",
            "n_recommendations": 10
        }
    
    Response:
        {
            "success": true,
            "recommendations": [...]
        }
    """
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({
                'success': False,
                'error': 'No JSON data provided'
            }), 400
        
        user_id = data.get('user_id')
        if not user_id:
            return jsonify({
                'success': False,
                'error': 'user_id is required'
            }), 400
        
        n_recommendations = data.get('n_recommendations', 10)
        
        # Get recommendations
        recommendations = get_collaborative_recommendations(user_id, n_recommendations)
        
        return jsonify({
            'success': True,
            'user_id': user_id,
            'recommendations': recommendations
        })
        
    except Exception as e:
        logger.error(f"Error in collaborative recommendations: {e}", exc_info=True)
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/recommend/popular', methods=['GET'])
def popular_recommendations():
    """
    Get popular food recommendations
    
    Query parameters:
        n_recommendations: Number of recommendations (default: 10)
    
    Response:
        {
            "success": true,
            "recommendations": [...]
        }
    """
    try:
        n_recommendations = request.args.get('n_recommendations', 10, type=int)
        
        recommendations = get_popular_recommendations(n_recommendations)
        
        return jsonify({
            'success': True,
            'recommendations': recommendations
        })
        
    except Exception as e:
        logger.error(f"Error in popular recommendations: {e}", exc_info=True)
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/food/<int:food_id>', methods=['GET'])
def get_food_details(food_id: int):
    """Get details for a specific food"""
    try:
        food = food_database[food_database['food_id'] == food_id]
        
        if len(food) == 0:
            return jsonify({
                'success': False,
                'error': f'Food with ID {food_id} not found'
            }), 404
        
        food = food.iloc[0]
        
        return jsonify({
            'success': True,
            'food': {
                'food_id': int(food['food_id']),
                'name': food['name'],
                'nutrition': {
                    'calories': float(food['calories']),
                    'carbohydrates': float(food['carbohydrates']),
                    'protein': float(food['protein']),
                    'fat': float(food['fat'])
                }
            }
        })
        
    except Exception as e:
        logger.error(f"Error getting food details: {e}", exc_info=True)
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/rating', methods=['POST'])
def add_rating():
    """
    Add a user rating
    
    Request body (JSON):
        {
            "user_id": "user_001",
            "food_id": 1,
            "rating": 5
        }
    """
    global user_ratings
    
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({
                'success': False,
                'error': 'No JSON data provided'
            }), 400
        
        user_id = data.get('user_id')
        food_id = data.get('food_id')
        rating = data.get('rating')
        
        if not all([user_id, food_id is not None, rating is not None]):
            return jsonify({
                'success': False,
                'error': 'user_id, food_id, and rating are required'
            }), 400
        
        # Add rating
        new_rating = pd.DataFrame({
            'user_id': [user_id],
            'food_id': [food_id],
            'rating': [rating]
        })
        
        user_ratings = pd.concat([user_ratings, new_rating], ignore_index=True)
        
        logger.info(f"Added rating: user={user_id}, food={food_id}, rating={rating}")
        
        return jsonify({
            'success': True,
            'message': 'Rating added successfully'
        })
        
    except Exception as e:
        logger.error(f"Error adding rating: {e}", exc_info=True)
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='Collaborative Filtering Recommendation API Server')
    parser.add_argument('--host', type=str, default='0.0.0.0',
                        help='Host to bind to (default: 0.0.0.0)')
    parser.add_argument('--port', type=int, default=5001,
                        help='Port to bind to (default: 5001)')
    parser.add_argument('--debug', action='store_true',
                        help='Run in debug mode')
    
    args = parser.parse_args()
    
    # Load sample data at startup
    logger.info("Loading sample food database...")
    load_sample_data()
    
    # Run server
    logger.info(f"Starting Recommendation server on {args.host}:{args.port}")
    app.run(host=args.host, port=args.port, debug=args.debug)


if __name__ == '__main__':
    main()
