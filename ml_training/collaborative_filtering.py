#!/usr/bin/env python3
"""
Train a collaborative filtering model from ratings data.
This version uses Korean food names from 'food_id' column as item identifiers.

Usage:
    python collaborative_filtering.py --method <svd|knn_basic|knn_means> --data <ratings.csv> [--save-model <model.pkl>]
"""

import argparse
import os
import pickle
import logging

import pandas as pd
from surprise import Dataset, Reader, SVD, KNNBasic, KNNWithMeans
from surprise.model_selection import train_test_split
from surprise import accuracy

# --- 로깅 설정 ---
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class SurpriseRecommender:
    """
    A wrapper for Surprise library recommendation algorithms.
    """
    SUPPORTED_ALGORITHMS = {
        "svd": SVD,
        "knn_basic": KNNBasic,
        "knn_means": KNNWithMeans,
    }

    def __init__(self, algorithm: str = "svd", **kwargs):
        if algorithm not in self.SUPPORTED_ALGORITHMS:
            raise ValueError(f"Unsupported algorithm: {algorithm}. Supported are: {list(self.SUPPORTED_ALGORITHMS.keys())}")

        self.algorithm_name = algorithm
        self.model_class = self.SUPPORTED_ALGORITHMS[algorithm]
        self.model_params = kwargs
        self.model = self.model_class(**self.model_params)
        self.metrics = {}
        logger.info(f"Initialized {self.algorithm_name} recommender.")

    def fit(self, ratings_df: pd.DataFrame, test_size: float = 0.2) -> dict:
        """
        Trains the model on the given ratings data.
        :param ratings_df: DataFrame with 'user_id', 'food_id', 'rating' columns.
        :return: A dictionary containing evaluation metrics (RMSE, MAE).
        """
        logger.info(f"Loading data for training. Total ratings: {len(ratings_df)}")
        reader = Reader(rating_scale=(1, 5))
        data = Dataset.load_from_df(ratings_df[['user_id', 'food_id', 'rating']], reader)

        trainset, testset = train_test_split(data, test_size=test_size, random_state=42)

        logger.info(f"Training {self.algorithm_name} model...")
        self.model.fit(trainset)

        logger.info("Evaluating model...")
        predictions = self.model.test(testset)

        rmse = accuracy.rmse(predictions, verbose=False)
        mae = accuracy.mae(predictions, verbose=False)

        self.metrics = {"RMSE": rmse, "MAE": mae}
        logger.info(f"Evaluation complete. RMSE: {rmse:.4f}, MAE: {mae:.4f}")

        return self.metrics

    def save(self, path: str):
        """Saves the trained model object itself to a file."""
        if self.model is None:
            raise RuntimeError("Model has not been trained yet. Call fit() before saving.")

        dir_name = os.path.dirname(path)
        if dir_name:
            os.makedirs(dir_name, exist_ok=True)

        logger.info(f"Saving the trained model object to {path}...")
        with open(path, 'wb') as f:
            pickle.dump(self.model, f)
        logger.info(f"Model object successfully saved to {path}")


# --- Main execution block ---
def main():
    """Main function to train and save the model."""
    parser = argparse.ArgumentParser(description="Train a collaborative filtering model.")
    parser.add_argument("--method", type=str, required=True, choices=SurpriseRecommender.SUPPORTED_ALGORITHMS.keys(),
                        help="The recommendation algorithm to use.")
    parser.add_argument("--data", type=str, required=True, help="Path to the ratings CSV file (e.g., ratings.csv).")
    parser.add_argument("--save-model", type=str, help="Path to save the trained model (e.g., models/recommender_svd.pkl).")
    args = parser.parse_args()

    try:
        # user_id와 food_id(한글 이름)를 모두 문자열로 읽어오도록 명시
        ratings_df = pd.read_csv(args.data, dtype={'user_id': str, 'food_id': str})

        # 데이터의 앞뒤 공백 제거 (서버와 동일한 전처리)
        ratings_df['food_id'] = ratings_df['food_id'].str.strip()

        logger.info(f"Loaded {len(ratings_df)} ratings from {args.data}")
    except FileNotFoundError:
        logger.error(f"Data file not found at {args.data}")
        return

    recommender = SurpriseRecommender(algorithm=args.method)
    metrics = recommender.fit(ratings_df)

    print("\n--- Training & Evaluation Metrics ---")
    print(f"RMSE: {metrics.get('RMSE', 'N/A'):.4f}")
    print(f"MAE:  {metrics.get('MAE', 'N/A'):.4f}")
    print("-------------------------------------\n")

    if args.save_model:
        recommender.save(args.save_model)

    print("Done!")


if __name__ == "__main__":
    main()