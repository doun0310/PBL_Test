"""
YOLO v8 Training Script for Food Detection (Fine-tuned for Korean Food)

This script provides a training pipeline for fine-tuning YOLO v8 models to detect
and classify Korean food items from photos. The model is used in the diet tracking
application to identify individual food items in user-captured meal photos.

Training Strategy:
==================
The fine-tuning process uses two datasets:
1. Kaggle 'Food-11 image dataset' (16,643 images)
   - Used to train YOLO to recognize food vs non-food objects
   - Helps the model focus only on food items

2. AI Hub '건강관리를 위한 음식 이미지' (Health Management Food Images)
   - Original: 3,000,000 images with 3,500 classes
   - Reduced to: 272,783 images with 154 classes (for hardware constraints)
   - Provides specific Korean food classification (삼겹살, 된장찌개, etc.)

Usage:
    # Train with default settings
    python yolo_training.py --data data.yaml --epochs 100 --batch 16
    
    # Train with custom model
    python yolo_training.py --model yolov8m.pt --data data.yaml --epochs 150

Requirements:
    - ultralytics >= 8.0.0
    - torch >= 2.0.0
    - See requirements.txt for full list
"""

import argparse
import os
from pathlib import Path
from typing import Optional

try:
    from ultralytics import YOLO
except ImportError:
    raise ImportError(
        "ultralytics package not found. Install with: pip install ultralytics"
    )


class YOLOTrainer:
    """
    A wrapper class for training YOLO v8 models on custom food detection datasets.
    
    This trainer is designed for fine-tuning on Korean food datasets:
    - Stage 1: Food-11 dataset for food vs non-food classification
    - Stage 2: AI Hub Korean food dataset for specific food classification
    
    Attributes:
        model: The YOLO model instance
        data_yaml: Path to the dataset configuration file
        project_dir: Directory to save training results
    """
    
    def __init__(
        self,
        model_name: str = "yolov8n.pt",
        data_yaml: str = "data.yaml",
        project_dir: str = "./runs/train"
    ):
        """
        Initialize the YOLO trainer.
        
        Args:
            model_name: Pre-trained model to use as base. Options:
                       - 'yolov8n.pt' (nano - fastest, smallest)
                       - 'yolov8s.pt' (small)
                       - 'yolov8m.pt' (medium) - recommended for food detection
                       - 'yolov8l.pt' (large)
                       - 'yolov8x.pt' (extra large - most accurate)
            data_yaml: Path to the data.yaml configuration file
            project_dir: Directory to save training artifacts
        """
        self.model_name = model_name
        self.data_yaml = data_yaml
        self.project_dir = project_dir
        self.model: Optional[YOLO] = None
        
    def load_model(self) -> YOLO:
        """
        Load the YOLO v8 model.
        
        Returns:
            YOLO model instance
        """
        print(f"Loading model: {self.model_name}")
        self.model = YOLO(self.model_name)
        return self.model
    
    def train(
        self,
        epochs: int = 100,
        batch_size: int = 16,
        imgsz: int = 640,
        device: Optional[str] = None,
        workers: int = 8,
        patience: int = 50,
        save_period: int = 10,
        resume: bool = False,
        augment: bool = True,
        **kwargs
    ) -> dict:
        """
        Train the YOLO model on the specified dataset.
        
        Args:
            epochs: Number of training epochs
            batch_size: Batch size for training
            imgsz: Input image size (images will be resized to imgsz x imgsz)
            device: Device to use ('cuda', 'cpu', '0', '0,1', etc.)
                   None = auto-detect
            workers: Number of dataloader workers
            patience: Early stopping patience (epochs without improvement)
            save_period: Save checkpoint every N epochs
            resume: Resume training from last checkpoint
            augment: Enable data augmentation
            **kwargs: Additional arguments passed to YOLO train()
            
        Returns:
            Training results dictionary
        """
        if self.model is None:
            self.load_model()
        
        # Validate data.yaml exists
        if not os.path.exists(self.data_yaml):
            raise FileNotFoundError(
                f"Dataset configuration not found: {self.data_yaml}\n"
                "Please create a data.yaml file with your dataset configuration."
            )
        
        print(f"\n{'='*60}")
        print("YOLO Training Configuration")
        print(f"{'='*60}")
        print(f"Model: {self.model_name}")
        print(f"Dataset: {self.data_yaml}")
        print(f"Epochs: {epochs}")
        print(f"Batch Size: {batch_size}")
        print(f"Image Size: {imgsz}x{imgsz}")
        print(f"Device: {device or 'auto'}")
        print(f"{'='*60}\n")
        
        # Start training
        results = self.model.train(
            data=self.data_yaml,
            epochs=epochs,
            batch=batch_size,
            imgsz=imgsz,
            device=device,
            workers=workers,
            patience=patience,
            save_period=save_period,
            resume=resume,
            augment=augment,
            project=self.project_dir,
            name="food_detection",
            exist_ok=True,
            **kwargs
        )
        
        return results
    
    def validate(self, split: str = "val") -> dict:
        """
        Validate the trained model on the validation set.
        
        Args:
            split: Dataset split to validate on ('val' or 'test')
            
        Returns:
            Validation metrics dictionary
        """
        if self.model is None:
            raise ValueError("Model not loaded. Call load_model() first.")
        
        results = self.model.val(data=self.data_yaml, split=split)
        return results
    
    def export(
        self,
        format: str = "tflite",
        imgsz: int = 640,
        half: bool = True
    ) -> str:
        """
        Export the trained model to different formats for deployment.
        
        Args:
            format: Export format. Options:
                   - 'tflite': TensorFlow Lite (for mobile - Android/iOS)
                   - 'onnx': ONNX format
                   - 'torchscript': TorchScript
                   - 'coreml': CoreML (for iOS)
                   - 'saved_model': TensorFlow SavedModel
            imgsz: Image size for export
            half: Use FP16 half precision (reduces model size)
            
        Returns:
            Path to exported model
        """
        if self.model is None:
            raise ValueError("Model not loaded. Call load_model() first.")
        
        print(f"\nExporting model to {format} format...")
        export_path = self.model.export(
            format=format,
            imgsz=imgsz,
            half=half
        )
        print(f"Model exported to: {export_path}")
        return export_path
    
    def predict(
        self,
        source: str,
        conf: float = 0.5,
        iou: float = 0.45,
        save: bool = True
    ) -> list:
        """
        Run inference on images.
        
        Args:
            source: Path to image, directory, or video
            conf: Confidence threshold for detections
            iou: IoU threshold for NMS
            save: Save annotated results
            
        Returns:
            List of detection results
        """
        if self.model is None:
            raise ValueError("Model not loaded. Call load_model() first.")
        
        results = self.model.predict(
            source=source,
            conf=conf,
            iou=iou,
            save=save
        )
        return results


def create_sample_dataset_structure(base_path: str = "./datasets/food_dataset"):
    """
    Create the directory structure for a YOLO dataset.
    
    Args:
        base_path: Base directory for the dataset
    """
    base = Path(base_path)
    
    # Create directories
    dirs = [
        base / "images" / "train",
        base / "images" / "val",
        base / "images" / "test",
        base / "labels" / "train",
        base / "labels" / "val",
        base / "labels" / "test",
    ]
    
    for d in dirs:
        d.mkdir(parents=True, exist_ok=True)
    
    # Create a sample label file for reference
    sample_label = base / "labels" / "train" / "sample.txt"
    sample_label.write_text(
        "# YOLO format: class_id x_center y_center width height\n"
        "# All values normalized 0-1\n"
        "# Example: Rice bowl detected in center of image\n"
        "0 0.5 0.5 0.3 0.3\n"
    )
    
    print(f"Created dataset structure at: {base}")
    print("Add your images to 'images/' directories")
    print("Add corresponding label files to 'labels/' directories")
    print("\nLabel format (each line):")
    print("  <class_id> <x_center> <y_center> <width> <height>")


def main():
    """Main entry point for the training script."""
    parser = argparse.ArgumentParser(
        description="Train YOLO v8 model for Korean food detection"
    )
    
    # Model arguments
    parser.add_argument(
        "--model",
        type=str,
        default="yolov8n.pt",
        help="Base model to use (default: yolov8n.pt)"
    )
    parser.add_argument(
        "--data",
        type=str,
        default="data.yaml",
        help="Path to data.yaml configuration file"
    )
    
    # Training arguments
    parser.add_argument(
        "--epochs",
        type=int,
        default=100,
        help="Number of training epochs (default: 100)"
    )
    parser.add_argument(
        "--batch",
        type=int,
        default=16,
        help="Batch size (default: 16)"
    )
    parser.add_argument(
        "--imgsz",
        type=int,
        default=640,
        help="Image size (default: 640)"
    )
    parser.add_argument(
        "--device",
        type=str,
        default=None,
        help="Device to use (cuda, cpu, 0, 0,1, etc.)"
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=8,
        help="Number of dataloader workers (default: 8)"
    )
    
    # Action arguments
    parser.add_argument(
        "--create-dataset",
        action="store_true",
        help="Create sample dataset directory structure"
    )
    parser.add_argument(
        "--export",
        type=str,
        choices=["tflite", "onnx", "torchscript", "coreml", "saved_model"],
        default=None,
        help="Export trained model to specified format"
    )
    parser.add_argument(
        "--validate",
        action="store_true",
        help="Run validation after training"
    )
    
    args = parser.parse_args()
    
    # Create dataset structure if requested
    if args.create_dataset:
        create_sample_dataset_structure()
        return
    
    # Initialize trainer
    trainer = YOLOTrainer(
        model_name=args.model,
        data_yaml=args.data
    )
    
    # Load model
    trainer.load_model()
    
    # Train model
    print("\nStarting training...")
    results = trainer.train(
        epochs=args.epochs,
        batch_size=args.batch,
        imgsz=args.imgsz,
        device=args.device,
        workers=args.workers
    )
    
    # Validate if requested
    if args.validate:
        print("\nRunning validation...")
        val_results = trainer.validate()
        print(f"Validation mAP50: {val_results.box.map50:.4f}")
        print(f"Validation mAP50-95: {val_results.box.map:.4f}")
    
    # Export if requested
    if args.export:
        print(f"\nExporting model to {args.export}...")
        export_path = trainer.export(format=args.export, imgsz=args.imgsz)
        print(f"Model exported to: {export_path}")
    
    print("\nTraining complete!")
    print(f"Results saved to: {trainer.project_dir}/food_detection/")


if __name__ == "__main__":
    main()
