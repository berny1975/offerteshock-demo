param(
  [Parameter(Mandatory=$true)][string]$RepoName,
  [ValidateSet("public","private")][string]$Visibility = "public"
)
function Die($m){ Write-Host "ERROR: $m" -ForegroundColor Red; exit 1 }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Info($m){ Write-Host $m -ForegroundColor Cyan }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }

# Preflight
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Die "Git non trovato. Installa: https://git-scm.com/downloads" }
if (-not (Get-Command gh  -ErrorAction SilentlyContinue)) { Die "GitHub CLI non trovato. Installa: https://cli.github.com/" }

# Auth
$null = & gh auth status 2>$null
if ($LASTEXITCODE -ne 0) {
  Warn "Non sei loggato a GitHub CLI. Avvio login..."
  & gh auth login
  if ($LASTEXITCODE -ne 0) { Die "Login GitHub fallito" }
}

# Owner
$owner = (& gh api user --jq ".login" 2>$null)
if (-not $owner) { Die "Impossibile ottenere l'utente GitHub (gh api user)" }
Info ("Utente GitHub: " + $owner)

# Git identity default if missing
$email = (& git config --global user.email 2>$null)
$name  = (& git config --global user.name  2>$null)
if ([string]::IsNullOrWhiteSpace($email)) { & git config --global user.email ($owner + "@users.noreply.github.com") | Out-Null; Warn ("Impostata email: " + $owner + "@users.noreply.github.com") }
if ([string]::IsNullOrWhiteSpace($name))  { & git config --global user.name  $owner | Out-Null; Warn ("Impostato name: " + $owner) }

# Working dir
$work = Join-Path $PSScriptRoot $RepoName
$remoteUrl = "https://github.com/$owner/$RepoName.git"
New-Item -ItemType Directory -Path $work -Force | Out-Null
Push-Location $work

# Init if needed
if (-not (Test-Path ".git")) { & git init -b main | Out-Null }

# Ensure remote exists EARLY
$hasOrigin = (git remote | Select-String -SimpleMatch "origin")
$repoExists = $false
$null = & gh repo view "$owner/$RepoName" 2>$null
if ($LASTEXITCODE -eq 0) { $repoExists = $true }

if ($repoExists) {
  if (-not $hasOrigin) { & git remote add origin $remoteUrl }
} else {
  # Create repo, then add origin
  & gh repo create "$owner/$RepoName" --$Visibility -y
  if ($LASTEXITCODE -ne 0) { Die "Creazione repository fallita" }
  & git remote add origin $remoteUrl
}

# Align to remote base if branch exists
& git fetch origin | Out-Null
& git rev-parse --verify origin/main 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
  Write-Host "Allineo alla base remota origin/main..." -ForegroundColor Cyan
  & git checkout -B main origin/main | Out-Null
  & git reset --hard origin/main | Out-Null
  & git clean -fd | Out-Null
} else {
  & git checkout -B main | Out-Null
}

# Copy entire site/ from kit over clean base
$site = Join-Path $work "site"
New-Item -ItemType Directory -Path $site -Force | Out-Null
Copy-Item -Path (Join-Path $PSScriptRoot "site\*") -Destination $site -Recurse -Force

# Ensure .gitattributes
Copy-Item -Path (Join-Path $PSScriptRoot ".gitattributes") -Destination (Join-Path $work ".gitattributes") -Force

# Dynamic sitemap.xml
$baseUrl = "https://$owner.github.io/$RepoName/"
$smap = @"
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>${baseUrl}</loc></url>
  <url><loc>${baseUrl}privacy.html</loc></url>
  <url><loc>${baseUrl}termini.html</loc></url>
  <url><loc>${baseUrl}contatti.html</loc></url>
</urlset>
"@
$smap | Set-Content -Path (Join-Path $site "sitemap.xml") -Encoding UTF8

# robots.txt add sitemap
$robotsPath = Join-Path $site "robots.txt"
if (Test-Path $robotsPath) {
  $r = Get-Content -Raw $robotsPath
  if ($r -notmatch "Sitemap:") { Add-Content -Path $robotsPath -Value ("Sitemap: " + $baseUrl + "sitemap.xml") }
} else {
  ("User-agent: *`nAllow: /`nSitemap: " + $baseUrl + "sitemap.xml") | Set-Content -Path $robotsPath -Encoding ASCII
}

# Write workflow (single-quoted here-string)
$wfDir = Join-Path $work ".github\workflows"
New-Item -ItemType Directory -Path $wfDir -Force | Out-Null
$wfPath = Join-Path $wfDir "pages.yml"
@'
name: Deploy static site to Pages

on:
  push:
    branches: ["main"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: true

jobs:
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/configure-pages@v5
      - uses: actions/upload-pages-artifact@v3
        with:
          path: site
      - id: deployment
        uses: actions/deploy-pages@v4
'@ | Set-Content -Path $wfPath -Encoding UTF8

# Stage & commit
& git add .
& git commit -m "publish multipage v1_4 remote first" --allow-empty | Out-Null

# Push
& git push -u origin main
if ($LASTEXITCODE -ne 0) { Die "git push fallito" }

# Tag
$tag = "v" + (Get-Date -Format "yyyy.MM.dd-HHmm")
& git tag $tag
& git push origin $tag

Ok "`nPubblicato!"
Write-Host ("URL: " + $baseUrl)
Pop-Location
