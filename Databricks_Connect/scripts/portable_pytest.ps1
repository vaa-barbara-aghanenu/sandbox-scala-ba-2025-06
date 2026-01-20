[CmdletBinding()]
param(
    [string[]]$PytestArgs,
    [switch]$BootstrapOnly
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$toolsDir = Join-Path $repoRoot ".tools"
$pythonVersion = "3.11.9"
$pythonEmbedZip = "python-$pythonVersion-embed-amd64.zip"
$pythonDownloadUrl = "https://www.python.org/ftp/python/$pythonVersion/$pythonEmbedZip"
$pythonDir = Join-Path $toolsDir "python"
$pythonExe = Join-Path $pythonDir "python.exe"
$pythonZipPath = Join-Path $toolsDir $pythonEmbedZip

$jdkArchive = "OpenJDK17U-jre_x64_windows_hotspot_17.0.12_7.zip"
$jdkDownloadUrl = "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.12%2B7/$jdkArchive"
$jdkDir = Join-Path $toolsDir "jdk"
$jdkArchivePath = Join-Path $toolsDir $jdkArchive

New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null

function Get-OrDownloadFile {
    param(
        [string]$Url,
        [string]$Destination
    )

    if (-not (Test-Path $Destination)) {
        Write-Host "Downloading $Url ..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $Url -OutFile $Destination
    }
}

function Enable-ImportSite {
    $parts = $pythonVersion.Split(".")
    $pthName = ("python{0}{1}._pth" -f $parts[0], $parts[1])
    $pthPath = Join-Path $pythonDir $pthName
    if (-not (Test-Path $pthPath)) {
        return
    }

    $content = Get-Content $pthPath
    $changed = $false
    $updated = foreach ($line in $content) {
        if ($line -match "^\s*#\s*import site") {
            $changed = $true
            "import site"
        }
        else {
            $line
        }
    }

    if (-not $changed -and -not ($updated -contains "import site")) {
        $updated += "import site"
    }

    Set-Content -Path $pthPath -Value $updated -Encoding ASCII
}

function Ensure-EmbeddedPython {
    if (-not (Test-Path $pythonExe)) {
        Write-Host "Preparing embedded Python $pythonVersion ..." -ForegroundColor Cyan
        Get-OrDownloadFile -Url $pythonDownloadUrl -Destination $pythonZipPath
        Expand-Archive -Path $pythonZipPath -DestinationPath $pythonDir -Force
        Enable-ImportSite
        Install-Pip
    }
    elseif (-not (Test-Path (Join-Path $pythonDir "Scripts\\pip.exe"))) {
        Install-Pip
    }
}

function Install-Pip {
    $getPipPath = Join-Path $toolsDir "get-pip.py"
    Get-OrDownloadFile -Url "https://bootstrap.pypa.io/get-pip.py" -Destination $getPipPath
    Write-Host "Installing pip into embedded Python..." -ForegroundColor Cyan
    & $pythonExe $getPipPath | Write-Output
}

function Get-JavaHome {
    if (Test-Path (Join-Path $jdkDir "bin\\java.exe")) {
        return $jdkDir
    }

    $candidates = Get-ChildItem -Path $jdkDir -Directory -Recurse
    foreach ($candidate in $candidates) {
        $javaPath = Join-Path $candidate.FullName "bin\\java.exe"
        if (Test-Path $javaPath) {
            return $candidate.FullName
        }
    }

    return $null
}

function Ensure-JavaRuntime {
    $javaHome = Get-JavaHome
    if ($javaHome) {
        return $javaHome
    }

    Write-Host "Preparing Temurin JRE 17 ..." -ForegroundColor Cyan
    Get-OrDownloadFile -Url $jdkDownloadUrl -Destination $jdkArchivePath
    Expand-Archive -Path $jdkArchivePath -DestinationPath $jdkDir -Force

    $javaHome = Get-JavaHome
    if (-not $javaHome) {
        throw "Unable to locate java.exe after extracting $jdkArchive."
    }

    return $javaHome
}

function Install-Requirements {
    $requirements = Join-Path $repoRoot "requirements-dev.txt"
    Write-Host "Installing Python requirements..." -ForegroundColor Cyan
    & $pythonExe -m pip install --upgrade pip setuptools wheel | Write-Output
    & $pythonExe -m pip install -r $requirements | Write-Output
}

Ensure-EmbeddedPython
$javaHome = Ensure-JavaRuntime
Install-Requirements

$env:JAVA_HOME = $javaHome
$env:PYSPARK_PYTHON = $pythonExe
$env:PATH = "$pythonDir;$pythonDir\\Scripts;$javaHome\\bin;$env:PATH"

Write-Host ""
Write-Host "Portable toolchain ready." -ForegroundColor Green
Write-Host "Python:`t$pythonExe"
Write-Host "JAVA_HOME:`t$javaHome"

if ($BootstrapOnly) {
    Write-Host "Bootstrap-only flag supplied; skipping pytest run."
    exit 0
}

$pytestCommand = @("-m", "pytest")
if ($PytestArgs) {
    $pytestCommand += $PytestArgs
}

Write-Host ""
Write-Host "Running pytest with embedded runtime..." -ForegroundColor Cyan
& $pythonExe $pytestCommand
exit $LASTEXITCODE
