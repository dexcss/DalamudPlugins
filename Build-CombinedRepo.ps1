# Build-CombinedRepo.ps1
# Fetches each plugin's individual repo.json and merges them into one combined repo.json.
# Run this whenever you bump a plugin version. It always pulls the latest from each source repo,
# so you never have to hand-edit version numbers in the combined file.

$ErrorActionPreference = "Stop"

# --- Configuration: the source repo.json for each plugin ---
$sources = @(
    "https://raw.githubusercontent.com/dexcss/VenueHelper/main/repo.json",
    "https://raw.githubusercontent.com/dexcss/FCTracker/main/repo.json",
    "https://raw.githubusercontent.com/dexcss/HousingLottoTracker/main/repo.json",
    "https://raw.githubusercontent.com/dexcss/MarketHelper/main/repo.json"
)

# Where to write the combined file (current folder by default)
$outFile = Join-Path $PSScriptRoot "repo.json"

$combined = @()

foreach ($url in $sources) {
    Write-Host "Fetching $url" -ForegroundColor Cyan
    # Cache-bust so GitHub's CDN doesn't hand back a stale copy
    $bustUrl = "$url`?t=$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"
    $resp = Invoke-WebRequest -Uri $bustUrl -Headers @{ "Cache-Control" = "no-cache" } -UseBasicParsing
    $plugins = $resp.Content | ConvertFrom-Json

    # Each source file is an array (usually with one plugin); add every entry
    foreach ($p in $plugins) {
        $combined += $p
        Write-Host "  + $($p.Name) $($p.AssemblyVersion)" -ForegroundColor Green
    }
}

# Write combined array as pretty JSON (UTF-8 without BOM, which Dalamud prefers)
$json = $combined | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($outFile, $json, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ""
Write-Host "Wrote $($combined.Count) plugins to $outFile" -ForegroundColor Yellow
