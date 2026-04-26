# restart_and_deploy.ps1
# Starts cloudflared + uvicorn, updates config.json, rebuilds Flutter, deploys to Firebase.
# Run from the repo root: .\restart_and_deploy.ps1

param(
    [switch]$SkipBuild   # pass -SkipBuild if you only want to restart services
)

$Root      = "C:\Users\Mihai\OneDrive\Desktop\Facultate\Thesis\UHack"
$Backend   = "$Root\backend"
$CfBin     = "C:\Users\Mihai\AppData\Local\npm-cache\_npx\8a26fc3a61fe4212\node_modules\cloudflared\bin\cloudflared.exe"
$CfLog     = "C:\temp\cf_tunnel.log"
$UvLog     = "C:\temp\uvicorn_err.log"

# ── 1. Kill old cloudflared + python processes ────────────────────────────────
Write-Host "`n[1/5] Stopping old processes..."
Stop-Process -Name "cloudflared" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "python"      -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# ── 2. Start new Cloudflare tunnel ───────────────────────────────────────────
Write-Host "[2/5] Starting Cloudflare tunnel..."
New-Item -ItemType Directory -Path "C:\temp" -Force | Out-Null
Remove-Item $CfLog -ErrorAction SilentlyContinue
Start-Process -FilePath $CfBin -ArgumentList "tunnel --url http://localhost:8000" `
    -RedirectStandardError $CfLog -NoNewWindow

# Wait for URL (up to 20 s)
$tunnelUrl = $null
for ($i = 0; $i -lt 20; $i++) {
    Start-Sleep -Seconds 1
    $log = Get-Content $CfLog -Raw -ErrorAction SilentlyContinue
    if ($log -match 'https://[a-z0-9-]+\.trycloudflare\.com') {
        $tunnelUrl = $Matches[0]
        break
    }
}
if (-not $tunnelUrl) { Write-Host "ERROR: Could not get tunnel URL. Check $CfLog"; exit 1 }
Write-Host "   Tunnel URL: $tunnelUrl"

# ── 3. Update web/config.json ────────────────────────────────────────────────
Write-Host "[3/5] Updating config.json..."
$config = @{ apiBaseUrl = "$tunnelUrl/api/v1" } | ConvertTo-Json -Depth 2
Set-Content -Path "$Root\web\config.json" -Value $config -Encoding utf8

# Patch CORS in main.py (add new URL if not present)
$mainPy = Get-Content "$Backend\app\main.py" -Raw
if ($mainPy -notmatch [regex]::Escape($tunnelUrl)) {
    $mainPy = $mainPy -replace '(allow_origins=\[)', "`$1`n        `"$tunnelUrl`","
    Set-Content "$Backend\app\main.py" $mainPy -Encoding utf8
    Write-Host "   CORS updated with $tunnelUrl"
}

# ── 4. Start uvicorn ─────────────────────────────────────────────────────────
Write-Host "[4/5] Starting uvicorn..."
Start-Process -FilePath "python" -ArgumentList "-m uvicorn app.main:app --host 0.0.0.0 --port 8000" `
    -WorkingDirectory $Backend -RedirectStandardError $UvLog -NoNewWindow
Start-Sleep -Seconds 6

$uvLog = Get-Content $UvLog -Raw -ErrorAction SilentlyContinue
if ($uvLog -match "Application startup complete") {
    Write-Host "   Backend running on port 8000"
} else {
    Write-Host "   WARNING: Backend may not have started. Check $UvLog"
}

# ── 5. Build + deploy (unless -SkipBuild) ────────────────────────────────────
if (-not $SkipBuild) {
    Write-Host "[5/5] Building Flutter web..."
    Set-Location $Root
    flutter build web --release
    if ($LASTEXITCODE -ne 0) { Write-Host "Flutter build FAILED"; exit 1 }

    Write-Host "      Deploying to Firebase..."
    firebase deploy --only hosting --project uhack26-8050e
    if ($LASTEXITCODE -ne 0) { Write-Host "Firebase deploy FAILED"; exit 1 }

    Write-Host "`nDone! App live at https://uhack26-8050e.web.app"
} else {
    Write-Host "[5/5] Skipped build (services restarted, config updated)"
    Write-Host "      Run 'flutter build web --release && firebase deploy --only hosting --project uhack26-8050e' manually when ready."
}
