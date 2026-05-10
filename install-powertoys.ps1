# PowerToys 설치 스크립트
# 화면 분할(FancyZones) 기능 포함

param(
    [switch]$Silent
)

$ErrorActionPreference = "Stop"

function Write-Step($msg) {
    Write-Host "[*] $msg" -ForegroundColor Cyan
}

function Write-Success($msg) {
    Write-Host "[OK] $msg" -ForegroundColor Green
}

function Write-Fail($msg) {
    Write-Host "[ERROR] $msg" -ForegroundColor Red
}

# 관리자 권한 확인
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Fail "이 스크립트는 관리자 권한으로 실행해야 합니다."
    Write-Host "PowerShell을 관리자 권한으로 다시 실행하거나, 아래 명령어를 사용하세요:"
    Write-Host "  Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File install-powertoys.ps1' -Verb RunAs"
    exit 1
}

# winget으로 설치 시도
Write-Step "winget으로 PowerToys 설치 중..."
if (Get-Command winget -ErrorAction SilentlyContinue) {
    try {
        if ($Silent) {
            winget install Microsoft.PowerToys --silent --accept-package-agreements --accept-source-agreements
        } else {
            winget install Microsoft.PowerToys --accept-package-agreements --accept-source-agreements
        }
        Write-Success "PowerToys 설치 완료 (winget)"
        exit 0
    } catch {
        Write-Host "winget 설치 실패. GitHub 직접 다운로드로 전환합니다..." -ForegroundColor Yellow
    }
} else {
    Write-Host "winget을 찾을 수 없습니다. GitHub 직접 다운로드로 전환합니다..." -ForegroundColor Yellow
}

# winget 없을 경우 GitHub Release에서 직접 다운로드
Write-Step "GitHub에서 최신 PowerToys 릴리즈 정보 가져오는 중..."
$apiUrl = "https://api.github.com/repos/microsoft/PowerToys/releases/latest"
$release = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell" }
$version = $release.tag_name

Write-Step "최신 버전: $version"

# x64 설치 파일 찾기
$asset = $release.assets | Where-Object { $_.name -match "PowerToysSetup.*x64.*\.exe$" } | Select-Object -First 1
if (-not $asset) {
    Write-Fail "설치 파일을 찾을 수 없습니다."
    exit 1
}

$installerUrl = $asset.browser_download_url
$installerPath = Join-Path $env:TEMP $asset.name

Write-Step "다운로드 중: $($asset.name)"
Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing

Write-Step "설치 중..."
if ($Silent) {
    Start-Process -FilePath $installerPath -ArgumentList "/silent" -Wait
} else {
    Start-Process -FilePath $installerPath -Wait
}

Remove-Item $installerPath -Force -ErrorAction SilentlyContinue

Write-Success "PowerToys $version 설치 완료!"
Write-Host ""
Write-Host "FancyZones(화면 분할) 사용법:"
Write-Host "  1. 시스템 트레이에서 PowerToys 아이콘 클릭"
Write-Host "  2. FancyZones 활성화"
Write-Host "  3. Win + Shift + \` 로 레이아웃 편집기 열기"
Write-Host "  4. 창을 드래그할 때 Shift 키를 누르면 분할 영역으로 스냅됩니다"
