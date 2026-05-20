param(
    [string]$Message = ""
)

$ErrorActionPreference = "Stop"

function Invoke-Git {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$GitArgs
    )

    & git @GitArgs
    if ($LASTEXITCODE -ne 0) {
        throw "git $($GitArgs -join ' ') failed with exit code $LASTEXITCODE"
    }
}

if (-not (Test-Path -LiteralPath ".git")) {
    throw "This folder is not a Git repository. Run git init first."
}

$proxyHost = "127.0.0.1"
$proxyPort = 7897
$proxyAvailable = Test-NetConnection -ComputerName $proxyHost -Port $proxyPort -InformationLevel Quiet -WarningAction SilentlyContinue
if ($proxyAvailable) {
    $proxyUrl = "http://${proxyHost}:${proxyPort}"
    $env:HTTP_PROXY = $proxyUrl
    $env:HTTPS_PROXY = $proxyUrl
    $env:ALL_PROXY = $proxyUrl
    Write-Host "Using proxy $proxyUrl for GitHub upload."
}

if ([string]::IsNullOrWhiteSpace($Message)) {
    $Message = "Update project files $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}

Invoke-Git add -A

$status = & git status --porcelain
if ($LASTEXITCODE -ne 0) {
    throw "git status --porcelain failed with exit code $LASTEXITCODE"
}
if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Host "No changes to upload."
    exit 0
}

Invoke-Git commit -m $Message
Invoke-Git push origin main
