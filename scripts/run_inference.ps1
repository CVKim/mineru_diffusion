# PowerShell wrapper around scripts/run_inference.py (equivalent to run_inference.sh).
# Usage:
#   .\scripts\run_inference.ps1 -ImagePath .\assets\image.png
#   .\scripts\run_inference.ps1 -ImagePath .\my_doc.png -PromptType layout
#   .\scripts\run_inference.ps1 -ModelPath .\model -ImagePath .\my_doc.png -Engine hf

param(
    [string]$Engine = $(if ($env:ENGINE) { $env:ENGINE } else { "hf" }),
    [string]$ModelPath = $(if ($env:MODEL_PATH) { $env:MODEL_PATH } else { ".\model" }),
    [string]$ImagePath = $(if ($env:IMAGE_PATH) { $env:IMAGE_PATH } else { ".\assets\image.png" }),
    [ValidateSet("text", "table", "formula", "layout")]
    [string]$PromptType = "text",
    [string]$Prompt = "",
    [string]$Device = "cuda",
    [ValidateSet("bfloat16", "float16", "float32")]
    [string]$Dtype = "bfloat16",
    [int]$MaxLength = 4096,
    [int]$GenLength = 1024,
    [int]$BlockSize = 32,
    [double]$Temperature = 1.0,
    [string]$RemaskStrategy = "low_confidence_dynamic",
    [double]$DynamicThreshold = 0.95,
    [string]$EnvName = $(if ($env:DMINERU_ENV) { $env:DMINERU_ENV } else { "dmineru" })
)

$ErrorActionPreference = "Stop"

$RepoDir = Split-Path -Parent $PSScriptRoot
$RunInferencePy = Join-Path $RepoDir "scripts\run_inference.py"

$resolvedModel = (Resolve-Path -LiteralPath $ModelPath -ErrorAction SilentlyContinue)
if (-not $resolvedModel) {
    Write-Host "Model path '$ModelPath' does not exist." -ForegroundColor Red
    Write-Host "Download with:"
    Write-Host "  conda activate $EnvName"
    Write-Host "  python -c `"from huggingface_hub import snapshot_download; snapshot_download('opendatalab/MinerU-Diffusion-V1-0320-2.5B', local_dir='./model')`""
    exit 1
}

$resolvedImage = (Resolve-Path -LiteralPath $ImagePath -ErrorAction SilentlyContinue)
if (-not $resolvedImage) {
    Write-Host "Image path '$ImagePath' does not exist." -ForegroundColor Red
    exit 1
}

$args = @(
    "--engine", $Engine,
    "--model-path", "$resolvedModel",
    "--image-path", "$resolvedImage",
    "--prompt-type", $PromptType,
    "--prompt", $Prompt,
    "--device", $Device,
    "--dtype", $Dtype,
    "--max-length", $MaxLength,
    "--gen-length", $GenLength,
    "--block-size", $BlockSize,
    "--temperature", $Temperature,
    "--remask-strategy", $RemaskStrategy,
    "--dynamic-threshold", $DynamicThreshold
)

# Force UTF-8 stdout so non-ASCII tokens (em-dash, Greek letters, CJK) don't blow up
# on Windows code pages such as CP949.
$env:PYTHONIOENCODING = "utf-8"
$env:PYTHONUTF8 = "1"

Write-Host "Running inference with engine='$Engine', dtype='$Dtype'..." -ForegroundColor Cyan
conda run -n $EnvName --no-capture-output python $RunInferencePy @args
