"""
Collaborative Filtering for Food Recommendations based on Nutrition

This script implements a content-based collaborative filtering system for
recommending foods based on remaining daily nutrition goals (calories, 
carbohydrates, protein, fat).

Algorithm:
==========
1. Cosine Similarity Calculation:
   - Uses sklearn's cosine_similarity to calculate similarity between foods
   - Based on nutritional content (calories, carbs, protein, fat)
   
2. Predicted Preference Score:
   - Combines user's historical preferences with food similarity
   - Sorts by combined score to recommend suitable foods

3. Nutrition-based Filtering:
   - Filters foods that fit within remaining daily nutrition goals
   - Recommends foods that help meet but not exceed targets

Usage:
    # Recommend foods based on remaining nutrition goals
    python collaborative_filtering.py --remaining-cal 500 --remaining-carb 50 \\
        --remaining-protein 30 --remaining-fat 20
    
    # Train on user preference data
    python collaborative_filtering.py --method cosine --data food_preferences.csv

Requirements:
    - scikit-learn >= 1.3.0
    - pandas >= 2.0.0
    - numpy >= 1.24.0
    - See requirements.txt for full list
"""

import argparse
import json
import os
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

import numpy as np
import pandas as pd

# Import sklearn's cosine_similarity (primary recommendation method)
try:
    from sklearn.metrics.pairwise import cosine_similarity
    from sklearn.preprocessing import MinMaxScaler
    SKLEARN_AVAILABLE = True
except ImportError:
    SKLEARN_AVAILABLE = False
    print("Warning: scikit-learn not installed. Install with: pip install scikit-learn")

# Try importing optional dependencies
try:
    from surprise import Dataset, Reader, SVD, KNNBasic, KNNWithMeans
    from surprise.model_selection import cross_validate, train_test_split
    from surprise import accuracy
    SURPRISE_AVAILABLE = True
except ImportError:
    SURPRISE_AVAILABLE = False

try:
    import torch
    import torch.nn as nn
    import torch.optim as optim
    from torch.utils.data import DataLoader, TensorDataset
    TORCH_AVAILABLE = True
except ImportError:
    TORCH_AVAILABLE = False


@dataclass
class FoodItem:
    """Data class for food items with nutrition information."""
    name: str
    calories: float
    carbohydrates: float
    protein: float
    fat: float
    food_id: str = ""
    category: str = ""


@dataclass
class RecommendationResult:
    """Data class for recommendation results."""
    user_id: str
    recommendations: list = field(default_factory=list)  # List of (food_name, score, nutrition)
    model_type: str = ""
    remaining_calories: float = 0.0


class NutritionBasedRecommender:
    """
    Food Recommendation System using Cosine Similarity and Predicted Preference.
    
    This recommender uses sklearn's cosine_similarity to calculate similarity
    between foods based on their nutritional content. It then combines this
    with user preference history to recommend suitable foods.
    
    Algorithm:
    1. Calculate cosine similarity matrix for all foods based on nutrition
    2. Track user's food consumption history and preferences
    3. For a given remaining nutrition budget, recommend foods that:
       - Fit within the remaining calorie/macro budget
       - Are similar to foods the user has liked before
       - Have high predicted preference scores
    """
    
    def __init__(self):
        """Initialize the nutrition-based recommender."""
        if not SKLEARN_AVAILABLE:
            raise ImportError("scikit-learn not installed. Run: pip install scikit-learn")
        
        self.food_database: pd.DataFrame = None
        self.similarity_matrix: np.ndarray = None
        self.user_preferences: dict = {}  # user_id -> {food_id: rating}
        self.scaler = MinMaxScaler()
        self.food_names: list = []
        self.food_ids: list = []
    
    def load_food_database(self, food_data: pd.DataFrame):
        """
        Load food database with nutrition information.
        
        Args:
            food_data: DataFrame with columns:
                       - food_id: Unique identifier
                       - name: Food name
                       - calories: kcal
                       - carbohydrates: grams
                       - protein: grams
                       - fat: grams
        """
        required_cols = ['food_id', 'name', 'calories', 'carbohydrates', 'protein', 'fat']
        for col in required_cols:
            if col not in food_data.columns:
                raise ValueError(f"Missing required column: {col}")
        
        self.food_database = food_data.copy()
        self.food_names = food_data['name'].tolist()
        self.food_ids = food_data['food_id'].tolist()
        
        # Calculate similarity matrix
        self._compute_similarity_matrix()
        
        print(f"Loaded {len(self.food_database)} foods")
    
    def _compute_similarity_matrix(self):
        """Compute cosine similarity matrix based on nutritional content."""
        # Extract nutrition features
        nutrition_features = self.food_database[
            ['calories', 'carbohydrates', 'protein', 'fat']
        ].values
        
        # Normalize features
        normalized_features = self.scaler.fit_transform(nutrition_features)
        
        # Calculate cosine similarity
        self.similarity_matrix = cosine_similarity(normalized_features)
        
        print("Computed food similarity matrix")
    
    def add_user_preference(self, user_id: str, food_id: str, rating: float):
        """
        Record a user's preference for a food item.
        
        Args:
            user_id: User identifier
            food_id: Food item identifier
            rating: Rating (1-5 scale)
        """
        if user_id not in self.user_preferences:
            self.user_preferences[user_id] = {}
        
        self.user_preferences[user_id][food_id] = rating
    
    def predict_preference(self, user_id: str, food_id: str) -> float:
        """
        Predict user's preference for a food using collaborative filtering.
        
        Uses weighted average of similar foods that user has rated.
        
        Args:
            user_id: User identifier
            food_id: Food to predict preference for
            
        Returns:
            Predicted preference score (0-5)
        """
        if user_id not in self.user_preferences:
            return 2.5  # Default neutral preference
        
        user_prefs = self.user_preferences[user_id]
        
        if food_id not in self.food_ids:
            return 2.5
        
        food_idx = self.food_ids.index(food_id)
        
        # Calculate weighted preference based on similar foods user has rated
        weighted_sum = 0.0
        similarity_sum = 0.0
        
        for rated_food_id, rating in user_prefs.items():
            if rated_food_id in self.food_ids:
                rated_idx = self.food_ids.index(rated_food_id)
                similarity = self.similarity_matrix[food_idx, rated_idx]
                
                weighted_sum += similarity * rating
                similarity_sum += abs(similarity)
        
        if similarity_sum == 0:
            return 2.5
        
        return weighted_sum / similarity_sum
    
    def recommend_foods(
        self,
        user_id: str,
        remaining_calories: float,
        remaining_carbs: float = None,
        remaining_protein: float = None,
        remaining_fat: float = None,
        n: int = 10
    ) -> list:
        """
        Recommend foods based on remaining nutrition goals.
        
        Args:
            user_id: User identifier
            remaining_calories: Remaining daily calories
            remaining_carbs: Remaining carbohydrates (grams)
            remaining_protein: Remaining protein (grams)
            remaining_fat: Remaining fat (grams)
            n: Number of recommendations to return
            
        Returns:
            List of (food_name, combined_score, nutrition_dict) tuples
        """
        if self.food_database is None:
            raise ValueError("Food database not loaded. Call load_food_database() first.")
        
        recommendations = []
        
        for idx, row in self.food_database.iterrows():
            food_id = row['food_id']
            
            # Filter by remaining nutrition budget
            if row['calories'] > remaining_calories:
                continue
            if remaining_carbs is not None and row['carbohydrates'] > remaining_carbs:
                continue
            if remaining_protein is not None and row['protein'] > remaining_protein:
                continue
            if remaining_fat is not None and row['fat'] > remaining_fat:
                continue
            
            # Calculate predicted preference
            preference_score = self.predict_preference(user_id, food_id)
            
            # Calculate how well the food fits the remaining budget (efficiency score)
            calorie_efficiency = row['calories'] / remaining_calories if remaining_calories > 0 else 0
            
            # Combined score: preference + efficiency
            combined_score = 0.6 * preference_score + 0.4 * (calorie_efficiency * 5)
            
            recommendations.append((
                row['name'],
                combined_score,
                {
                    'food_id': food_id,
                    'calories': row['calories'],
                    'carbohydrates': row['carbohydrates'],
                    'protein': row['protein'],
                    'fat': row['fat']
                }
            ))
        
        # Sort by combined score (descending)
        recommendations.sort(key=lambda x: x[1], reverse=True)
        
        return recommendations[:n]
    
    def get_similar_foods(self, food_id: str, n: int = 5) -> list:
        """
        Get foods similar to a given food based on nutrition profile.
        
        Args:
            food_id: Food to find similar items for
            n: Number of similar foods to return
            
        Returns:
            List of (food_name, similarity_score) tuples
        """
        if food_id not in self.food_ids:
            return []
        
        food_idx = self.food_ids.index(food_id)
        similarities = self.similarity_matrix[food_idx]
        
        # Get indices of most similar foods (excluding self)
        similar_indices = np.argsort(similarities)[::-1][1:n+1]
        
        return [
            (self.food_names[idx], similarities[idx])
            for idx in similar_indices
        ]
    
    def save(self, path: str):
        """Save the recommender state."""
        import pickle
        with open(path, 'wb') as f:
            pickle.dump({
                'food_database': self.food_database,
                'similarity_matrix': self.similarity_matrix,
                'user_preferences': self.user_preferences,
                'food_names': self.food_names,
                'food_ids': self.food_ids
            }, f)
        print(f"Model saved to: {path}")
    
    def load(self, path: str):
        """Load saved recommender state."""
        import pickle
        with open(path, 'rb') as f:
            data = pickle.load(f)
        
        self.food_database = data['food_database']
        self.similarity_matrix = data['similarity_matrix']
        self.user_preferences = data['user_preferences']
        self.food_names = data['food_names']
        self.food_ids = data['food_ids']


class BaseRecommender(ABC):
    """Abstract base class for recommender systems."""
    
    @abstractmethod
    def fit(self, ratings_data: pd.DataFrame):
        """Train the model on ratings data."""
        pass
    
    @abstractmethod
    def predict(self, user_id: str, item_id: str) -> float:
        """Predict rating for a user-item pair."""
        pass
    
    @abstractmethod
    def recommend(self, user_id: str, n: int = 10) -> list:
        """Get top-n recommendations for a user."""
        pass


class SurpriseRecommender(BaseRecommender):
    """
    Collaborative Filtering using Surprise library.
    
    Supports multiple algorithms:
    - SVD: Singular Value Decomposition (Matrix Factorization)
    - KNNBasic: Basic K-Nearest Neighbors
    - KNNWithMeans: K-NN with mean centering
    """
    
    def __init__(
        self,
        algorithm: str = "svd",
        n_factors: int = 100,
        n_epochs: int = 20,
        lr: float = 0.005,
        reg: float = 0.02,
        k: int = 40,
        sim_options: dict = None
    ):
        """
        Initialize the Surprise recommender.
        
        Args:
            algorithm: 'svd', 'knn_basic', or 'knn_means'
            n_factors: Number of latent factors (for SVD)
            n_epochs: Number of training epochs (for SVD)
            lr: Learning rate (for SVD)
            reg: Regularization term (for SVD)
            k: Number of neighbors (for KNN)
            sim_options: Similarity options for KNN
        """
        if not SURPRISE_AVAILABLE:
            raise ImportError("scikit-surprise not installed")
        
        self.algorithm_name = algorithm
        self.n_factors = n_factors
        self.n_epochs = n_epochs
        self.lr = lr
        self.reg = reg
        self.k = k
        self.sim_options = sim_options or {
            'name': 'pearson',
            'user_based': True
        }
        
        self.model = None
        self.trainset = None
        self.all_items = set()
        self.all_users = set()
        
        # Initialize algorithm
        if algorithm == "svd":
            self.model = SVD(
                n_factors=n_factors,
                n_epochs=n_epochs,
                lr_all=lr,
                reg_all=reg
            )
        elif algorithm == "knn_basic":
            self.model = KNNBasic(k=k, sim_options=self.sim_options)
        elif algorithm == "knn_means":
            self.model = KNNWithMeans(k=k, sim_options=self.sim_options)
        else:
            raise ValueError(f"Unknown algorithm: {algorithm}")
    
    def fit(self, ratings_data: pd.DataFrame, test_size: float = 0.2):
        """
        Train the model on ratings data.
        
        Args:
            ratings_data: DataFrame with columns ['user_id', 'item_id', 'rating']
            test_size: Proportion of data to use for testing
            
        Returns:
            Dictionary with training metrics
        """
        # Validate input
        required_cols = ['user_id', 'item_id', 'rating']
        for col in required_cols:
            if col not in ratings_data.columns:
                raise ValueError(f"Missing required column: {col}")
        
        # Store all items and users
        self.all_items = set(ratings_data['item_id'].unique())
        self.all_users = set(ratings_data['user_id'].unique())
        
        # Create Surprise dataset
        reader = Reader(rating_scale=(1, 5))
        data = Dataset.load_from_df(
            ratings_data[['user_id', 'item_id', 'rating']],
            reader
        )
        
        # Split data
        trainset, testset = train_test_split(data, test_size=test_size)
        self.trainset = trainset
        
        # Train model
        print(f"\nTraining {self.algorithm_name.upper()} model...")
        self.model.fit(trainset)
        
        # Evaluate on test set
        predictions = self.model.test(testset)
        rmse = accuracy.rmse(predictions)
        mae = accuracy.mae(predictions)
        
        print(f"RMSE: {rmse:.4f}")
        print(f"MAE: {mae:.4f}")
        
        return {'rmse': rmse, 'mae': mae}
    
    def predict(self, user_id: str, item_id: str) -> float:
        """Predict rating for a user-item pair."""
        if self.model is None:
            raise ValueError("Model not trained. Call fit() first.")
        
        prediction = self.model.predict(user_id, item_id)
        return prediction.est
    
    def recommend(self, user_id: str, n: int = 10) -> list:
        """
        Get top-n recommendations for a user.
        
        Args:
            user_id: The user to generate recommendations for
            n: Number of recommendations to return
            
        Returns:
            List of (item_id, predicted_rating) tuples
        """
        if self.model is None:
            raise ValueError("Model not trained. Call fit() first.")
        
        # Get items the user hasn't rated
        user_rated = set()
        if self.trainset is not None:
            try:
                user_inner_id = self.trainset.to_inner_uid(user_id)
                user_rated = {
                    self.trainset.to_raw_iid(item)
                    for item, _ in self.trainset.ur[user_inner_id]
                }
            except ValueError:
                pass  # User not in training set
        
        candidates = self.all_items - user_rated
        
        # Predict ratings for all candidates
        predictions = []
        for item_id in candidates:
            pred = self.predict(user_id, item_id)
            predictions.append((item_id, pred))
        
        # Sort by predicted rating and return top-n
        predictions.sort(key=lambda x: x[1], reverse=True)
        return predictions[:n]
    
    def cross_validate(self, ratings_data: pd.DataFrame, cv: int = 5):
        """
        Perform cross-validation on the model.
        
        Args:
            ratings_data: DataFrame with ratings
            cv: Number of folds
            
        Returns:
            Dictionary with cross-validation results
        """
        reader = Reader(rating_scale=(1, 5))
        data = Dataset.load_from_df(
            ratings_data[['user_id', 'item_id', 'rating']],
            reader
        )
        
        # Create fresh model for CV
        if self.algorithm_name == "svd":
            model = SVD(
                n_factors=self.n_factors,
                n_epochs=self.n_epochs,
                lr_all=self.lr,
                reg_all=self.reg
            )
        elif self.algorithm_name == "knn_basic":
            model = KNNBasic(k=self.k, sim_options=self.sim_options)
        else:
            model = KNNWithMeans(k=self.k, sim_options=self.sim_options)
        
        results = cross_validate(model, data, measures=['RMSE', 'MAE'], cv=cv, verbose=True)
        
        return {
            'rmse_mean': results['test_rmse'].mean(),
            'rmse_std': results['test_rmse'].std(),
            'mae_mean': results['test_mae'].mean(),
            'mae_std': results['test_mae'].std()
        }
    
    def save(self, path: str):
        """Save the trained model."""
        import pickle
        with open(path, 'wb') as f:
            pickle.dump({
                'model': self.model,
                'trainset': self.trainset,
                'all_items': self.all_items,
                'all_users': self.all_users,
                'algorithm': self.algorithm_name
            }, f)
        print(f"Model saved to: {path}")
    
    @classmethod
    def load(cls, path: str):
        """Load a trained model."""
        import pickle
        with open(path, 'rb') as f:
            data = pickle.load(f)
        
        recommender = cls(algorithm=data['algorithm'])
        recommender.model = data['model']
        recommender.trainset = data['trainset']
        recommender.all_items = data['all_items']
        recommender.all_users = data['all_users']
        return recommender


class PyTorchMFRecommender(BaseRecommender):
    """
    Matrix Factorization Recommender using PyTorch.
    
    This implementation uses embedding layers to learn latent factors
    for users and items, optimizing with gradient descent.
    """
    
    def __init__(
        self,
        n_factors: int = 50,
        lr: float = 0.01,
        weight_decay: float = 1e-5,
        n_epochs: int = 100,
        batch_size: int = 256,
        device: str = None
    ):
        """
        Initialize the PyTorch MF recommender.
        
        Args:
            n_factors: Number of latent factors
            lr: Learning rate
            weight_decay: L2 regularization weight
            n_epochs: Number of training epochs
            batch_size: Batch size for training
            device: 'cuda', 'cpu', or None (auto-detect)
        """
        if not TORCH_AVAILABLE:
            raise ImportError("PyTorch not installed")
        
        self.n_factors = n_factors
        self.lr = lr
        self.weight_decay = weight_decay
        self.n_epochs = n_epochs
        self.batch_size = batch_size
        
        if device is None:
            self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        else:
            self.device = torch.device(device)
        
        self.model = None
        self.user_to_idx = {}
        self.item_to_idx = {}
        self.idx_to_item = {}
        self.all_items = set()
        self.user_rated = {}
    
    def _create_model(self, n_users: int, n_items: int):
        """Create the MF model."""
        
        class MatrixFactorization(nn.Module):
            def __init__(self, n_users, n_items, n_factors):
                super().__init__()
                self.user_embedding = nn.Embedding(n_users, n_factors)
                self.item_embedding = nn.Embedding(n_items, n_factors)
                self.user_bias = nn.Embedding(n_users, 1)
                self.item_bias = nn.Embedding(n_items, 1)
                self.global_bias = nn.Parameter(torch.zeros(1))
                
                # Initialize embeddings
                nn.init.normal_(self.user_embedding.weight, std=0.01)
                nn.init.normal_(self.item_embedding.weight, std=0.01)
                nn.init.zeros_(self.user_bias.weight)
                nn.init.zeros_(self.item_bias.weight)
            
            def forward(self, user_ids, item_ids):
                user_emb = self.user_embedding(user_ids)
                item_emb = self.item_embedding(item_ids)
                user_b = self.user_bias(user_ids).squeeze()
                item_b = self.item_bias(item_ids).squeeze()
                
                dot = (user_emb * item_emb).sum(dim=1)
                pred = dot + user_b + item_b + self.global_bias
                return pred
        
        return MatrixFactorization(n_users, n_items, self.n_factors)
    
    def fit(self, ratings_data: pd.DataFrame, test_size: float = 0.2):
        """
        Train the model on ratings data.
        
        Args:
            ratings_data: DataFrame with columns ['user_id', 'item_id', 'rating']
            test_size: Proportion of data to use for testing
            
        Returns:
            Dictionary with training metrics
        """
        # Create mappings
        users = ratings_data['user_id'].unique()
        items = ratings_data['item_id'].unique()
        
        self.user_to_idx = {u: i for i, u in enumerate(users)}
        self.item_to_idx = {item: i for i, item in enumerate(items)}
        self.idx_to_item = {i: item for item, i in self.item_to_idx.items()}
        self.all_items = set(items)
        
        # Store user-item interactions
        for _, row in ratings_data.iterrows():
            user = row['user_id']
            item = row['item_id']
            if user not in self.user_rated:
                self.user_rated[user] = set()
            self.user_rated[user].add(item)
        
        # Prepare data
        user_ids = torch.LongTensor([self.user_to_idx[u] for u in ratings_data['user_id']])
        item_ids = torch.LongTensor([self.item_to_idx[i] for i in ratings_data['item_id']])
        ratings = torch.FloatTensor(ratings_data['rating'].values)
        
        # Split data
        n_samples = len(ratings)
        indices = torch.randperm(n_samples)
        n_test = int(n_samples * test_size)
        
        train_idx = indices[n_test:]
        test_idx = indices[:n_test]
        
        train_dataset = TensorDataset(
            user_ids[train_idx],
            item_ids[train_idx],
            ratings[train_idx]
        )
        test_dataset = TensorDataset(
            user_ids[test_idx],
            item_ids[test_idx],
            ratings[test_idx]
        )
        
        train_loader = DataLoader(train_dataset, batch_size=self.batch_size, shuffle=True)
        test_loader = DataLoader(test_dataset, batch_size=self.batch_size)
        
        # Create and train model
        n_users = len(users)
        n_items = len(items)
        self.model = self._create_model(n_users, n_items).to(self.device)
        
        criterion = nn.MSELoss()
        optimizer = optim.Adam(
            self.model.parameters(),
            lr=self.lr,
            weight_decay=self.weight_decay
        )
        
        print(f"\nTraining PyTorch MF model on {self.device}...")
        print(f"Users: {n_users}, Items: {n_items}, Factors: {self.n_factors}")
        
        best_rmse = float('inf')
        for epoch in range(self.n_epochs):
            # Training
            self.model.train()
            train_loss = 0
            for batch_users, batch_items, batch_ratings in train_loader:
                batch_users = batch_users.to(self.device)
                batch_items = batch_items.to(self.device)
                batch_ratings = batch_ratings.to(self.device)
                
                optimizer.zero_grad()
                predictions = self.model(batch_users, batch_items)
                loss = criterion(predictions, batch_ratings)
                loss.backward()
                optimizer.step()
                
                train_loss += loss.item() * len(batch_ratings)
            
            train_loss /= len(train_dataset)
            
            # Validation
            self.model.eval()
            test_loss = 0
            with torch.no_grad():
                for batch_users, batch_items, batch_ratings in test_loader:
                    batch_users = batch_users.to(self.device)
                    batch_items = batch_items.to(self.device)
                    batch_ratings = batch_ratings.to(self.device)
                    
                    predictions = self.model(batch_users, batch_items)
                    loss = criterion(predictions, batch_ratings)
                    test_loss += loss.item() * len(batch_ratings)
            
            test_loss /= len(test_dataset)
            test_rmse = np.sqrt(test_loss)
            
            if test_rmse < best_rmse:
                best_rmse = test_rmse
            
            if (epoch + 1) % 10 == 0 or epoch == 0:
                print(f"Epoch {epoch+1}/{self.n_epochs} - "
                      f"Train Loss: {train_loss:.4f}, "
                      f"Test RMSE: {test_rmse:.4f}")
        
        print(f"\nBest Test RMSE: {best_rmse:.4f}")
        return {'rmse': best_rmse}
    
    def predict(self, user_id: str, item_id: str) -> float:
        """Predict rating for a user-item pair."""
        if self.model is None:
            raise ValueError("Model not trained. Call fit() first.")
        
        if user_id not in self.user_to_idx or item_id not in self.item_to_idx:
            return 3.0  # Return average rating for unknown users/items
        
        user_idx = torch.LongTensor([self.user_to_idx[user_id]]).to(self.device)
        item_idx = torch.LongTensor([self.item_to_idx[item_id]]).to(self.device)
        
        self.model.eval()
        with torch.no_grad():
            pred = self.model(user_idx, item_idx).item()
        
        # Clip to valid rating range
        return max(1.0, min(5.0, pred))
    
    def recommend(self, user_id: str, n: int = 10) -> list:
        """Get top-n recommendations for a user."""
        if self.model is None:
            raise ValueError("Model not trained. Call fit() first.")
        
        if user_id not in self.user_to_idx:
            # Return popular items for unknown users
            return []
        
        # Get items the user hasn't rated
        rated = self.user_rated.get(user_id, set())
        candidates = self.all_items - rated
        
        if not candidates:
            return []
        
        # Predict ratings for all candidates
        predictions = []
        for item_id in candidates:
            pred = self.predict(user_id, item_id)
            predictions.append((item_id, pred))
        
        # Sort by predicted rating
        predictions.sort(key=lambda x: x[1], reverse=True)
        return predictions[:n]
    
    def save(self, path: str):
        """Save the trained model."""
        torch.save({
            'model_state': self.model.state_dict(),
            'user_to_idx': self.user_to_idx,
            'item_to_idx': self.item_to_idx,
            'idx_to_item': self.idx_to_item,
            'all_items': self.all_items,
            'user_rated': self.user_rated,
            'n_factors': self.n_factors
        }, path)
        print(f"Model saved to: {path}")
    
    def load(self, path: str):
        """Load a trained model."""
        data = torch.load(path, map_location=self.device)
        
        self.user_to_idx = data['user_to_idx']
        self.item_to_idx = data['item_to_idx']
        self.idx_to_item = data['idx_to_item']
        self.all_items = data['all_items']
        self.user_rated = data['user_rated']
        self.n_factors = data['n_factors']
        
        n_users = len(self.user_to_idx)
        n_items = len(self.item_to_idx)
        self.model = self._create_model(n_users, n_items).to(self.device)
        self.model.load_state_dict(data['model_state'])
        self.model.eval()


def create_sample_food_database(output_path: str = "./sample_food_database.csv"):
    """
    Create sample food database with nutrition information.
    
    This creates a dataset for testing the nutrition-based recommender.
    """
    np.random.seed(42)
    
    # Korean food items with typical nutrition values
    foods = [
        ("흰쌀밥", 300, 65, 5, 1),
        ("김치찌개", 150, 8, 12, 8),
        ("된장찌개", 120, 10, 8, 5),
        ("비빔밥", 550, 70, 18, 15),
        ("불고기", 280, 12, 25, 15),
        ("삼겹살", 450, 2, 20, 40),
        ("치킨", 350, 15, 25, 20),
        ("잡채", 280, 35, 8, 12),
        ("떡볶이", 380, 65, 8, 10),
        ("김밥", 320, 45, 10, 12),
        ("라면", 500, 70, 12, 18),
        ("냉면", 450, 85, 10, 5),
        ("자장면", 650, 95, 15, 20),
        ("탕수육", 400, 40, 18, 18),
        ("삼계탕", 450, 15, 35, 25),
        ("갈비찜", 380, 20, 30, 20),
        ("제육볶음", 320, 15, 22, 18),
        ("닭갈비", 280, 20, 25, 12),
        ("순두부찌개", 180, 8, 15, 10),
        ("부대찌개", 420, 35, 20, 22),
        ("샐러드", 80, 10, 3, 5),
        ("고등어구이", 220, 0, 22, 14),
        ("계란찜", 120, 2, 10, 8),
        ("콩나물무침", 35, 5, 3, 1),
        ("시금치나물", 25, 3, 2, 1),
    ]
    
    data = []
    for i, (name, cal, carb, prot, fat) in enumerate(foods):
        data.append({
            'food_id': f"food_{i:03d}",
            'name': name,
            'calories': cal + np.random.randint(-20, 20),
            'carbohydrates': max(0, carb + np.random.randint(-5, 5)),
            'protein': max(0, prot + np.random.randint(-2, 2)),
            'fat': max(0, fat + np.random.randint(-3, 3))
        })
    
    df = pd.DataFrame(data)
    df.to_csv(output_path, index=False, encoding='utf-8')
    
    print(f"Sample food database created: {output_path}")
    print(f"  - Foods: {len(data)}")
    
    return df


def create_sample_data(output_path: str = "./sample_ratings.csv", n_users: int = 100, n_items: int = 50):
    """
    Create sample ratings data for testing.
    
    Args:
        output_path: Path to save the sample data
        n_users: Number of users to generate
        n_items: Number of items (recipes) to generate
    """
    np.random.seed(42)
    
    # Generate sample recipe names (Korean food items)
    recipes = [
        "김치찌개", "된장찌개", "순두부찌개", "비빔밥", "불고기",
        "삼겹살", "치킨", "잡채", "떡볶이", "김밥",
        "라면", "냉면", "자장면", "탕수육", "짬뽕",
        "삼계탕", "갈비찜", "제육볶음", "닭갈비", "부대찌개",
        "순대국", "설렁탕", "곰탕", "육개장", "감자탕",
        "해물찜", "낙지볶음", "오징어볶음", "쭈꾸미", "조개탕",
        "샐러드", "스테이크", "파스타", "피자", "버거",
        "초밥", "우동", "돈카츠", "라멘", "규동",
        "카레", "볶음밥", "오므라이스", "돈부리", "냉모밀",
        "베트남쌀국수", "분짜", "팟타이", "똠얌꿍", "카오팟"
    ][:n_items]
    
    # Generate ratings
    ratings = []
    for user_id in range(1, n_users + 1):
        # Each user rates 10-30 random items
        n_ratings = np.random.randint(10, min(30, n_items))
        rated_items = np.random.choice(n_items, n_ratings, replace=False)
        
        for item_idx in rated_items:
            # Generate rating with some user preference patterns
            base_rating = np.random.choice([3, 4, 5], p=[0.3, 0.4, 0.3])
            noise = np.random.normal(0, 0.5)
            rating = np.clip(base_rating + noise, 1, 5)
            
            ratings.append({
                'user_id': f"user_{user_id:03d}",
                'item_id': recipes[item_idx],
                'rating': round(rating, 1)
            })
    
    # Create DataFrame and save
    df = pd.DataFrame(ratings)
    df.to_csv(output_path, index=False, encoding='utf-8')
    
    print(f"Sample data created: {output_path}")
    print(f"  - Users: {n_users}")
    print(f"  - Items: {n_items}")
    print(f"  - Ratings: {len(ratings)}")
    
    return df


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Collaborative Filtering for Food Recommendations"
    )
    
    # Data arguments
    parser.add_argument(
        "--data",
        type=str,
        default="ratings.csv",
        help="Path to data CSV file"
    )
    parser.add_argument(
        "--food-database",
        type=str,
        help="Path to food database CSV (for nutrition-based recommendations)"
    )
    parser.add_argument(
        "--create-sample",
        action="store_true",
        help="Create sample ratings and food database"
    )
    
    # Model arguments
    parser.add_argument(
        "--method",
        type=str,
        choices=["cosine", "svd", "knn_basic", "knn_means", "pytorch_mf"],
        default="cosine",
        help="Recommendation algorithm (cosine=nutrition-based, default)"
    )
    parser.add_argument(
        "--n-factors",
        type=int,
        default=50,
        help="Number of latent factors (default: 50)"
    )
    parser.add_argument(
        "--epochs",
        type=int,
        default=100,
        help="Number of training epochs (default: 100)"
    )
    parser.add_argument(
        "--lr",
        type=float,
        default=0.01,
        help="Learning rate (default: 0.01)"
    )
    parser.add_argument(
        "--k",
        type=int,
        default=40,
        help="Number of neighbors for KNN (default: 40)"
    )
    
    # Nutrition-based recommendation arguments
    parser.add_argument(
        "--remaining-cal",
        type=float,
        help="Remaining daily calories for recommendations"
    )
    parser.add_argument(
        "--remaining-carb",
        type=float,
        help="Remaining daily carbohydrates (grams)"
    )
    parser.add_argument(
        "--remaining-protein",
        type=float,
        help="Remaining daily protein (grams)"
    )
    parser.add_argument(
        "--remaining-fat",
        type=float,
        help="Remaining daily fat (grams)"
    )
    
    # Action arguments
    parser.add_argument(
        "--cross-validate",
        action="store_true",
        help="Run cross-validation"
    )
    parser.add_argument(
        "--recommend-for",
        type=str,
        help="Get recommendations for a specific user"
    )
    parser.add_argument(
        "--n-recommendations",
        type=int,
        default=10,
        help="Number of recommendations to return"
    )
    parser.add_argument(
        "--save-model",
        type=str,
        help="Path to save the trained model"
    )
    
    args = parser.parse_args()
    
    # Create sample data if requested
    if args.create_sample:
        create_sample_food_database("sample_food_database.csv")
        create_sample_data("sample_ratings.csv")
        return
    
    # Nutrition-based recommendations (cosine similarity method)
    if args.method == "cosine":
        if not SKLEARN_AVAILABLE:
            print("Error: scikit-learn not installed")
            return
        
        food_db_path = args.food_database or "sample_food_database.csv"
        
        if not os.path.exists(food_db_path):
            print(f"Error: Food database not found: {food_db_path}")
            print("Create sample data with: python collaborative_filtering.py --create-sample")
            return
        
        recommender = NutritionBasedRecommender()
        food_df = pd.read_csv(food_db_path)
        recommender.load_food_database(food_df)
        
        # Get recommendations based on remaining nutrition
        if args.remaining_cal:
            print(f"\nRecommending foods for remaining {args.remaining_cal} kcal...")
            recommendations = recommender.recommend_foods(
                user_id=args.recommend_for or "default_user",
                remaining_calories=args.remaining_cal,
                remaining_carbs=args.remaining_carb,
                remaining_protein=args.remaining_protein,
                remaining_fat=args.remaining_fat,
                n=args.n_recommendations
            )
            
            print(f"\nTop {len(recommendations)} Food Recommendations:")
            print("-" * 60)
            for i, (name, score, nutrition) in enumerate(recommendations, 1):
                print(f"{i}. {name} (score: {score:.2f})")
                print(f"   Cal: {nutrition['calories']:.0f} | "
                      f"Carb: {nutrition['carbohydrates']:.0f}g | "
                      f"Prot: {nutrition['protein']:.0f}g | "
                      f"Fat: {nutrition['fat']:.0f}g")
            
            if args.save_model:
                recommender.save(args.save_model)
            
            return
        else:
            print("For cosine method, provide --remaining-cal")
            print("Example: --remaining-cal 500 --remaining-carb 50 --remaining-protein 30")
            return
    
    # Load data for other methods
    if not os.path.exists(args.data):
        print(f"Error: Data file not found: {args.data}")
        print("Create sample data with: python collaborative_filtering.py --create-sample")
        return
    
    print(f"Loading data from: {args.data}")
    ratings_df = pd.read_csv(args.data)
    print(f"Loaded {len(ratings_df)} ratings")
    
    # Create recommender based on method
    if args.method == "pytorch_mf":
        if not TORCH_AVAILABLE:
            print("Error: PyTorch not installed")
            return
        recommender = PyTorchMFRecommender(
            n_factors=args.n_factors,
            n_epochs=args.epochs,
            lr=args.lr
        )
    else:
        if not SURPRISE_AVAILABLE:
            print("Error: scikit-surprise not installed")
            return
        recommender = SurpriseRecommender(
            algorithm=args.method,
            n_factors=args.n_factors,
            n_epochs=args.epochs,
            lr=args.lr,
            k=args.k
        )
    
    # Cross-validation or training
    if args.cross_validate and isinstance(recommender, SurpriseRecommender):
        print("\nRunning 5-fold cross-validation...")
        cv_results = recommender.cross_validate(ratings_df, cv=5)
        print(f"\nCross-Validation Results:")
        print(f"  RMSE: {cv_results['rmse_mean']:.4f} (+/- {cv_results['rmse_std']:.4f})")
        print(f"  MAE:  {cv_results['mae_mean']:.4f} (+/- {cv_results['mae_std']:.4f})")
    else:
        # Train model
        metrics = recommender.fit(ratings_df)
    
    # Get recommendations if requested
    if args.recommend_for:
        print(f"\nTop {args.n_recommendations} recommendations for {args.recommend_for}:")
        recommendations = recommender.recommend(args.recommend_for, n=args.n_recommendations)
        
        if not recommendations:
            print("  No recommendations found (user may not exist in training data)")
        else:
            for i, (item_id, pred_rating) in enumerate(recommendations, 1):
                print(f"  {i}. {item_id} (predicted rating: {pred_rating:.2f})")
    
    # Save model if requested
    if args.save_model:
        recommender.save(args.save_model)
    
    print("\nDone!")


if __name__ == "__main__":
    main()
