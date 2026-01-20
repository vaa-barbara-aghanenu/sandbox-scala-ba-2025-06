[CmdletBinding()]
param(
    [string]$Python = "python",
    [string]$EnvPath = ".venv",
    [switch]$ForceRecreate
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$envFullPath = Resolve-Path -Path $EnvPath -ErrorAction SilentlyContinue

if ($null -eq $envFullPath -or $ForceRecreate.IsPresent) {
    if ($ForceRecreate) {
        Write-Host "Removing existing virtual environment at $EnvPath..."
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $EnvPath | Out-Null
    }
    Write-Host "Creating virtual environment ($EnvPath) with $Python ..."
    & $Python -m venv $EnvPath
    $envFullPath = Resolve-Path -Path $EnvPath
}

$venvPython = Join-Path $envFullPath "Scripts\\python.exe"
if (-not (Test-Path $venvPython)) {
    throw "Unable to find python.exe in $envFullPath. Did venv creation succeed?"
}

Write-Host "Upgrading pip..." -ForegroundColor Cyan
& $venvPython -m pip install --upgrade pip setuptools wheel | Write-Output

$requirements = Join-Path $repoRoot "requirements-dev.txt"
Write-Host "Installing requirements from $requirements ..." -ForegroundColor Cyan
& $venvPython -m pip install -r $requirements | Write-Output

Write-Host ""
Write-Host "Local development environment ready." -ForegroundColor Green
Write-Host "Activate it with:`n`t& $EnvPath\\Scripts\\Activate.ps1"
