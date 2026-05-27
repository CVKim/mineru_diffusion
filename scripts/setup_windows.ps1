# One-shot Windows setup for MinerU-Diffusion (hf engine).
# Usage (PowerShell, from repo root):
#   .\scripts\setup_windows.ps1
#
# Requires: Anaconda/Miniconda on PATH, an NVIDIA GPU with a CUDA 12.x-capable driver.

$ErrorActionPreference = "Stop"

$EnvName = if ($env:DMINERU_ENV) { $env:DMINERU_ENV } else { "dmineru" }
$PyVersion = "3.12"

Write-Host "[1/4] Creating conda env '$EnvName' (Python $PyVersion)..." -ForegroundColor Cyan
$existing = conda env list | Select-String -Pattern "^\s*$EnvName\s"
if ($existing) {
    Write-Host "  -> env already exists, skipping create" -ForegroundColor Yellow
} else {
    conda create -n $EnvName "python=$PyVersion" -y | Out-Host
}

$envPython = & conda run -n $EnvName python -c "import sys; print(sys.executable)"
if (-not $envPython) { throw "Could not resolve env python for $EnvName" }
$envPython = $envPython.Trim()
Write-Host "  -> using python at: $envPython"

Write-Host "[2/4] Upgrading pip..." -ForegroundColor Cyan
& $envPython -m pip install --upgrade pip | Out-Host

Write-Host "[3/4] Installing PyTorch 2.8.0+cu128 (Windows wheel)..." -ForegroundColor Cyan
& $envPython -m pip install torch==2.8.0 torchvision==0.23.0 `
    --index-url https://download.pytorch.org/whl/cu128 | Out-Host

Write-Host "[4/4] Installing remaining requirements..." -ForegroundColor Cyan
& $envPython -m pip install -r requirements-windows.txt | Out-Host

Write-Host ""
Write-Host "Verifying CUDA availability..." -ForegroundColor Cyan
& $envPython -c @"
import torch
print('torch          :', torch.__version__)
print('cuda available :', torch.cuda.is_available())
print('device count   :', torch.cuda.device_count())
if torch.cuda.is_available():
    print('device 0       :', torch.cuda.get_device_name(0))
    print('bf16 supported :', torch.cuda.is_bf16_supported())
"@

Write-Host ""
Write-Host "Setup complete. Next steps:" -ForegroundColor Green
Write-Host "  1) Download the model weights:"
Write-Host "       conda activate $EnvName"
Write-Host "       python -c `"from huggingface_hub import snapshot_download; snapshot_download('opendatalab/MinerU-Diffusion-V1-0320-2.5B', local_dir='./model')`""
Write-Host "  2) Run inference:"
Write-Host "       .\scripts\run_inference.ps1 -ImagePath .\assets\image.png"
