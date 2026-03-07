# ------------------------------------------------------------
# Unity Projects Dummy Data Generator
# Creates test Unity projects with dummy data for testing
# ------------------------------------------------------------

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Show-Header {

    Clear-Host

    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host " Unity Projects Dummy Data Generator" -ForegroundColor Cyan
    Write-Host " Root directory: $scriptDir" -ForegroundColor DarkGray
    Write-Host "================================================="
}

# ------------------------------------------------------------
# Create Dummy File
# ------------------------------------------------------------
function New-DummyFile {

    param(
        [string]$Path,
        [int64]$SizeBytes
    )

    $fs = [System.IO.File]::Create($Path)
    $fs.SetLength($SizeBytes)
    $fs.Close()
}

# ------------------------------------------------------------
# Generate Test Projects
# ------------------------------------------------------------
function Set-TestProjects {

    $projectCount = Read-Host "How many projects to generate?"
    $minGB = Read-Host "Minimum project size (GB)"
    $maxGB = Read-Host "Maximum project size (GB)"

    $projectCount = [int]$projectCount
    $minGB = [int]$minGB
    $maxGB = [int]$maxGB

    for ($i = 1; $i -le $projectCount; $i++) {

        $projectName = "TEST_UnityProject_{0:D3}" -f $i
        $projectPath = Join-Path $scriptDir $projectName

        Write-Host ""
        Write-Host "Creating project: $projectName" -ForegroundColor Yellow

        New-Item -ItemType Directory -Path $projectPath | Out-Null

        $assetsPath = Join-Path $projectPath "Assets"
        $libraryPath = Join-Path $projectPath "Library"

        New-Item -ItemType Directory -Path $assetsPath | Out-Null
        New-Item -ItemType Directory -Path $libraryPath | Out-Null

        # realistic Unity structure
        New-Item -ItemType Directory -Path (Join-Path $assetsPath "Scripts") | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $assetsPath "Materials") | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $assetsPath "Textures") | Out-Null

        $projectSizeGB = Get-Random -Minimum $minGB -Maximum ($maxGB + 1)
        $projectSizeBytes = $projectSizeGB * 1GB

        # split between Assets and Library
        $assetsSize = [math]::Floor($projectSizeBytes * 0.3)
        $librarySize = $projectSizeBytes - $assetsSize

        Write-Host "Target size: $projectSizeGB GB"

        # Assets files
        $assetsFile = Join-Path $assetsPath "dummy_assets.bin"
        New-DummyFile $assetsFile $assetsSize

        # Library files
        $libraryFile = Join-Path $libraryPath "dummy_library.bin"
        New-DummyFile $libraryFile $librarySize

        Write-Host "Created dummy data." -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "Dummy projects generated successfully." -ForegroundColor Green
}

# ------------------------------------------------------------
# Delete Test Projects
# ------------------------------------------------------------
function Remove-TestProjects {

    Write-Host ""
    Write-Host "Searching for generated test projects..." -ForegroundColor Yellow

    $projects = Get-ChildItem -Path $scriptDir -Directory |
    Where-Object { $_.Name -like "TEST_UnityProject_*" }

    if (!$projects) {

        Write-Host "No generated test projects found." -ForegroundColor Red
        return
    }

    $confirm = (Read-Host "Delete ALL generated test projects? [y/N]").ToLower()

    if ($confirm -notin @("y", "yes")) {
        Write-Host "Operation cancelled."
        return
    }

    foreach ($p in $projects) {

        Write-Host "Deleting $($p.Name)" -ForegroundColor DarkYellow
        Remove-Item -LiteralPath $p.FullName -Recurse -Force
    }

    Write-Host ""
    Write-Host "All generated test projects deleted." -ForegroundColor Green
}

function Start-ArchiveTool {

    $toolPath = Join-Path $scriptDir "UnityProjectsArchiveTool.ps1"

    if (!(Test-Path $toolPath)) {

        Write-Host ""
        Write-Host "Archive tool not found!" -ForegroundColor Red
        Write-Host "Expected file:" -ForegroundColor Yellow
        Write-Host $toolPath
        return
    }

    Write-Host ""
    Write-Host "Launching UnityProjectsArchiveTool..." -ForegroundColor Green

    & $toolPath
}

# ------------------------------------------------------------
# Menu
# ------------------------------------------------------------
function Show-Menu {

    Write-Host ""
    Write-Host "1 - Generate Test Projects" -ForegroundColor Cyan
    Write-Host "2 - Delete Generated Projects" -ForegroundColor Yellow
    Write-Host "3 - Run Archive Tool" -ForegroundColor Green
    Write-Host "4 - Exit" -ForegroundColor DarkGray
}

# ------------------------------------------------------------
# Main Loop
# ------------------------------------------------------------
while ($true) {

    Show-Header
    Show-Menu

    $choice = Read-Host "Select option"

    switch ($choice) {

        "1" { Set-TestProjects }

        "2" { Remove-TestProjects }

        "3" { Start-ArchiveTool }

        "4" { break }

        default {
            Write-Host "Invalid selection." -ForegroundColor Red
        }
    }

    Read-Host "`nPress Enter to continue"
}