param(
    [string]$Message = ""
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath ".git")) {
    throw "This folder is not a Git repository. Run git init first."
}

if ([string]::IsNullOrWhiteSpace($Message)) {
    $Message = "Update project files $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}

git add -A

$status = git status --porcelain
if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Host "No changes to upload."
    exit 0
}

git commit -m $Message
git push origin main
