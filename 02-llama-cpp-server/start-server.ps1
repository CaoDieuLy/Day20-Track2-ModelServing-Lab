# Launch llama-server (via llama-cpp-python) reading models/active.json.
# Windows PowerShell 7+.
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

$python = Join-Path (Get-Location) '.venv\Scripts\python.exe'
if (-not (Test-Path $python)) {
    $python = 'python'
}

$nativeServer = Join-Path (Get-Location) 'BONUS-llama-cpp-optimization\llama.cpp\build\bin\Release\llama-server.exe'
$activeModel = Get-Content -Raw 'models\active.json' | ConvertFrom-Json
$hardware = Get-Content -Raw 'hardware.json' | ConvertFrom-Json
$model = $activeModel.primary_model
$threads = if ($hardware.cpu.cores_physical) { $hardware.cpu.cores_physical } else { 4 }
$hasAccelerator = $false
foreach ($backend in $hardware.gpu.backends.PSObject.Properties) {
    if ($backend.Name -ne 'cpu_only' -and [bool]$backend.Value) {
        $hasAccelerator = $true
    }
}
$gpu = if ($env:LAB_N_GPU_LAYERS) { $env:LAB_N_GPU_LAYERS } elseif ($hasAccelerator) { '99' } else { '0' }
$ctx = if ($env:LAB_N_CTX) { $env:LAB_N_CTX } else { '2048' }
$parallel = if ($env:LAB_PARALLEL) { $env:LAB_PARALLEL } else { '4' }
$port = if ($env:LAB_SERVER_PORT) { $env:LAB_SERVER_PORT } else { '8080' }

Write-Host "==> Starting llama-server" -ForegroundColor Cyan
Write-Host "    model     : $model"
Write-Host "    threads   : $threads"
Write-Host "    gpu_layers: $gpu"
Write-Host "    ctx       : $ctx"
Write-Host "    parallel  : $parallel"
Write-Host "    listening : http://0.0.0.0:$port"
Write-Host ""

if (Test-Path $nativeServer) {
    & $nativeServer `
        -m "$model" `
        --alias local `
        --host 0.0.0.0 --port $port `
        -t $threads `
        -ngl $gpu `
        -c $ctx `
        -np $parallel `
        --cont-batching `
        --metrics
} else {
    Write-Host "    native llama-server not found; falling back to llama-cpp-python server without /metrics" -ForegroundColor Yellow
    & $python -m llama_cpp.server `
        --model "$model" `
        --model_alias local `
        --host 0.0.0.0 --port $port `
        --n_threads $threads `
        --n_gpu_layers $gpu `
        --n_ctx $ctx
}
