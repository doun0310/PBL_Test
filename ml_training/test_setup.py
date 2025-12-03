"""
ML Training Setup Validation Script

This script validates that all training scripts are properly configured
and ready for data collection and AI training.

Run this after installing dependencies:
    pip install -r requirements.txt
    python test_setup.py
"""

import subprocess
import sys
from pathlib import Path


def check_file_exists(filepath: str) -> bool:
    """Check if a file exists."""
    path = Path(filepath)
    if path.exists():
        print(f"  ✓ {filepath}")
        return True
    else:
        print(f"  ✗ {filepath} NOT FOUND")
        return False


def check_python_syntax(filepath: str) -> bool:
    """Check if a Python file has valid syntax."""
    try:
        result = subprocess.run(
            [sys.executable, "-m", "py_compile", filepath],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            print(f"  ✓ {filepath} - Valid syntax")
            return True
        else:
            print(f"  ✗ {filepath} - Syntax error")
            print(f"    {result.stderr}")
            return False
    except Exception as e:
        print(f"  ✗ {filepath} - Error: {e}")
        return False


def check_import(module_name: str) -> bool:
    """Check if a module can be imported."""
    try:
        __import__(module_name)
        print(f"  ✓ {module_name}")
        return True
    except ImportError:
        print(f"  ✗ {module_name} - Not installed")
        return False


def main():
    print("="*60)
    print("ML Training Setup Validation")
    print("="*60)
    
    all_ok = True
    
    # Check required files
    print("\n📁 Checking required files...")
    required_files = [
        "requirements.txt",
        "data.yaml",
        "yolo_training.py",
        "easyocr_trainer.py",
        "collaborative_filtering.py",
        "download_datasets.py",
        "convert_aihub_to_yolo.py",
        "README.md",
        "TRAINING_GUIDE.md",
    ]
    
    for f in required_files:
        if not check_file_exists(f):
            all_ok = False
    
    # Check Python syntax
    print("\n🐍 Checking Python script syntax...")
    python_files = [
        "yolo_training.py",
        "easyocr_trainer.py",
        "collaborative_filtering.py",
        "download_datasets.py",
        "convert_aihub_to_yolo.py",
    ]
    
    for f in python_files:
        if not check_python_syntax(f):
            all_ok = False
    
    # Check YAML syntax
    print("\n📋 Checking YAML configuration...")
    try:
        import yaml
        with open("data.yaml", "r", encoding="utf-8") as f:
            data = yaml.safe_load(f)
        print(f"  ✓ data.yaml - Valid YAML")
        print(f"    Classes: {data.get('nc')}")
        print(f"    Dataset path: {data.get('path')}")
    except Exception as e:
        print(f"  ✗ data.yaml - Error: {e}")
        all_ok = False
    
    # Check core dependencies
    print("\n📦 Checking core dependencies (optional - install with pip)...")
    # Note: These are import names, not package names
    core_deps = [
        "numpy",
        "pandas",
        "torch",
        "PIL",       # Package: Pillow
        "cv2",       # Package: opencv-python
        "yaml",      # Package: PyYAML
        "sklearn",   # Package: scikit-learn
        "tqdm",
        "matplotlib",
    ]
    
    deps_installed = True
    for dep in core_deps:
        if not check_import(dep):
            deps_installed = False
    
    # Check ML framework dependencies
    print("\n🤖 Checking ML framework dependencies (optional)...")
    ml_deps = [
        "ultralytics",  # YOLO v8
        "easyocr",      # EasyOCR
        "surprise",     # scikit-surprise
        "trdg",         # TextRecognitionDataGenerator
    ]
    
    ml_installed = True
    for dep in ml_deps:
        if not check_import(dep):
            ml_installed = False
    
    # Summary
    print("\n" + "="*60)
    print("Validation Summary")
    print("="*60)
    
    if all_ok:
        print("✓ All files and syntax checks passed!")
    else:
        print("✗ Some file or syntax checks failed!")
    
    if not deps_installed:
        print("\n⚠  Core dependencies not installed.")
        print("   Install with: pip install -r requirements.txt")
    
    if not ml_installed:
        print("\n⚠  ML framework dependencies not fully installed.")
        print("   This is normal if you haven't run: pip install -r requirements.txt")
        print("   Install all dependencies with: pip install -r requirements.txt")
    
    if all_ok and deps_installed and ml_installed:
        print("\n🎉 All checks passed! System is ready for training.")
    elif all_ok:
        print("\n✓ Files are valid. Install dependencies to begin training:")
        print("   pip install -r requirements.txt")
    else:
        print("\n✗ Please fix the errors above before proceeding.")
    
    print("="*60)
    
    return all_ok


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
