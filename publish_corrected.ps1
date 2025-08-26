param(
  [Parameter(Mandatory=$true)][string]$RepoName,
  [string]$Visibility
)
function Die($m){ Write-Host "ERROR: $m" -ForegroundColor Red; exit 1 }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Info($m){ Write-Host $m -ForegroundColor Cyan }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }

if ([string]::IsNullOrWhiteSpace($Visibility)) { $Visibility = "public" }
$valid = @("public","private","internal")
if ($valid -notcontains $Visibility) { Warn "Visibility non valida '$Visibility'. Uso 'public'."; $Visibility = "public" }

$here = $PSScriptRoot
Set-Location -LiteralPath $here
if ($here -match '(?i)\\Windows(\\System32)?$') { Die "Cartella non valida: $here . Sposta il pacchetto in Download/Documenti/Desktop." }

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Die "Git non trovato. Installa: https://git-scm.com/downloads" }
if (-not (Get-Command gh  -ErrorAction SilentlyContinue)) { Die "GitHub CLI non trovata. Installa: https://cli.github.com/" }

$null = & gh auth status 2>$null
if ($LASTEXITCODE -ne 0) { & gh auth login; if ($LASTEXITCODE -ne 0) { Die "Login GitHub fallito" } }

$owner = (& gh api user --jq ".login" 2>$null)
if (-not $owner) { Die "Impossibile ottenere l'utente GitHub" }
$remoteUrl = "https://github.com/$owner/$RepoName.git"
Info ("Utente GitHub: " + $owner)
Info ("Repo: " + $remoteUrl)

# Checks
$wf = Join-Path $here ".github\workflows\pages.yml"
if (-not (Test-Path $wf)) { Die "Manca .github\workflows\pages.yml nel pacchetto." }
if (-not (Test-Path (Join-Path $here "site\index.html"))) { Die "Manca site\index.html nel pacchetto." }

# Ensure git identity
$cfgEmail = (& git config user.email)
if (-not $cfgEmail) { & git config user.email "$owner@users.noreply.github.com" }
$cfgName = (& git config user.name)
if (-not $cfgName) { & git config user.name $owner }

# Init repo here
if (-not (Test-Path (Join-Path $here ".git"))) { & git init | Out-Null }

# 1) Save our bundle on a temp branch
& git checkout -B bundle_local | Out-Null
& git add -A
& git commit -m "snapshot: corrected bundle" --allow-empty | Out-Null

# 2) Ensure remote exists / is created
$exists = $true
try { & gh repo view "$owner/$RepoName" 2>$null | Out-Null } catch { $exists = $false }
if (-not $exists) {
  & gh repo create "$owner/$RepoName" --$Visibility --confirm
  if ($LASTEXITCODE -ne 0) { Die "Creazione repo fallita (permessi/connessione)" }
}

# 3) Reset local main to remote main (fast-forward base)
& git fetch origin --prune 2>$null | Out-Null
$hasRemoteMain = $true
try { & git ls-remote --heads origin main 2>$null | Out-Null } catch { $hasRemoteMain = $false }

if ($hasRemoteMain) {
  & git checkout -B main origin/main | Out-Null
} else {
  & git checkout -B main | Out-Null
}

# 4) Bring our bundle on top of remote main
& git checkout bundle_local -- .
& git add -A
& git commit -m "publish: overwrite with corrected bundle (rebased on remote main)" --allow-empty | Out-Null

# 5) Set origin and push
& git remote remove origin 2>$null | Out-Null
& git remote add origin $remoteUrl 2>$null | Out-Null
& git push -u origin main
if ($LASTEXITCODE -ne 0) { Die "git push non riuscito. Controlla credenziali o permessi." }

# 6) Tag
$tag = "v" + (Get-Date -Format "yyyy.MM.dd-HHmm")
& git tag $tag
& git push origin $tag

Ok ("Pubblicato! URL: https://{0}.github.io/{1}/" -f $owner,$RepoName)
