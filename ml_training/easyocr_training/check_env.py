# check_env.py
import sys

try:
    import torch
    print(f"PyTorch version: {torch.__version__}")

    if torch.cuda.is_available():
        print(f"CUDA is available. GPU: {torch.cuda.get_device_name(0)}")
        print("Training will use GPU.")
    else:
        print("CUDA is not available. Training will use CPU.")

except ImportError:
    print("PyTorch is not installed.")
    print("Please install it by following the instructions at https://pytorch.org/")
    print("Example command: pip install torch torchvision torchaudio")
    sys.exit(1)

print("\nEnvironment check passed.")
