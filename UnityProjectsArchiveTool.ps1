# ============================================================
# Unity Projects Archive Tool
# ============================================================

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ScriptVersion = @(0, 3, 4)

# ------------------------------------------------------------
# Function: Universal Wait Function
# ------------------------------------------------------------
function Wait-ReturnOrExit {

    Write-Host ""
    Write-Host "Press Enter to return to menu or ESC to exit..." -ForegroundColor Gray

    while ($true) {

        if ([Console]::KeyAvailable) {
            [Console]::ReadKey($true) | Out-Null
        }

        $key = [System.Console]::ReadKey($true)

        switch ($key.Key) {

            "Enter" { return }

            "Escape" { Exit-Tool }
        }
    }
}

# ------------------------------------------------------------
# Function: Scan Progress Function
# ------------------------------------------------------------
function Show-ScanProgress {

    param (
        $Current,
        $Total,
        $ProjectName
    )

    $percent = [math]::Floor(($Current / $Total) * 100)

    $barSize = 30
    $filled = [math]::Floor(($percent / 100) * $barSize)
    $empty = $barSize - $filled

    $bar = ("#" * $filled) + ("-" * $empty)

    $line = "Scanning [$bar] $percent% : $ProjectName"

    # Clear the current console line
    $width = [Console]::WindowWidth
    Write-Host "`r$(' ' * ($width - 1))" -NoNewline

    # Write the new progress line
    Write-Host "`r$line" -NoNewline -ForegroundColor Yellow
}

# ------------------------------------------------------------
# Function: Discover Unity Projects
# ------------------------------------------------------------
function Get-UnityProjects {

    $excludedFolders = @("ScriptBackups")

    $projects = Get-ChildItem -LiteralPath $scriptDir -Directory |
    Where-Object { $excludedFolders -notcontains $_.Name }

    foreach ($folder in $projects) {

        $assetsPath = Join-Path $folder.FullName "Assets"

        if (Test-Path -LiteralPath $assetsPath) {

            [PSCustomObject]@{
                Name       = $folder.Name
                FullName   = $folder.FullName
                AssetsPath = $assetsPath
            }
        }
    }
}

# ------------------------------------------------------------
# Function: Scan Unity Projects
# ------------------------------------------------------------
function Get-UnityProjectsReport {

    Write-Host ""
    Write-Host "===== Scanning Unity Projects =====" -ForegroundColor Cyan
    Write-Host ""

    $projects = Get-UnityProjects
    $scanResults = @()
    $total = $projects.Count
    $i = 0
    foreach ($project in $projects) {

        $i++
        Show-ScanProgress $i $total $project.Name

        $scriptsPath = Join-Path $project.AssetsPath "Scripts"
        $scriptCount = 0

        if (Test-Path -LiteralPath $scriptsPath) {

            $scriptFiles = Get-ChildItem -LiteralPath $scriptsPath -Filter *.cs -Recurse -File -ErrorAction SilentlyContinue
            $scriptCount = $scriptFiles.Count
        }

        $cleanupFolders = @("Library", "Temp", "Obj", "Logs")
        $cleanupSize = 0

        foreach ($folder in $cleanupFolders) {

            $targetPath = Join-Path $project.FullName $folder

            if (Test-Path -LiteralPath $targetPath) {

                $folderSize = (
                    Get-ChildItem -LiteralPath $targetPath -Recurse -File -ErrorAction SilentlyContinue |
                    Measure-Object Length -Sum
                ).Sum

                $cleanupSize += $folderSize
            }
        }

        $cleanupSizeGB = [math]::Round($cleanupSize / 1GB, 2)

        $scanResults += [PSCustomObject]@{
            Project   = $project.Name
            Scripts   = $scriptCount
            CleanupGB = $cleanupSizeGB
        }
    }

    Write-Host ""
    Write-Host "================ SCAN REPORT ================" -ForegroundColor Cyan
    Write-Host ""

    $scanResults | Sort-Object CleanupGB -Descending | Format-Table -AutoSize

    $totalProjects = $scanResults.Count
    $totalScripts = ($scanResults.Scripts | Measure-Object -Sum).Sum
    $totalCleanup = ($scanResults.CleanupGB | Measure-Object -Sum).Sum

    Write-Host ""
    Write-Host "=============================================" -ForegroundColor DarkCyan
    Write-Host "Total Unity Projects : $totalProjects" -ForegroundColor White
    Write-Host "Total Scripts        : $totalScripts" -ForegroundColor White
    Write-Host "Potential Cleanup    : $totalCleanup GB" -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor DarkCyan

    Wait-ReturnOrExit
}

# ------------------------------------------------------------
# Function: Cleanup Unity Cache
# ------------------------------------------------------------
function Clear-UnityProjectCache {

    Write-Host ""
    Write-Host "===== Unity Cleanup Mode =====" -ForegroundColor Cyan
    Write-Host ""

    $projects = Get-UnityProjects
    $cleanupTargets = @()
    $total = $projects.Count
    $i = 0
    foreach ($project in $projects) {

        $cleanupFolders = @("Library", "Temp", "Obj", "Logs")
        $projectCleanupSize = 0
        $pathsToDelete = @()
        $i++

        Show-ScanProgress $i $total $project.Name
        foreach ($folder in $cleanupFolders) {

            $targetPath = Join-Path $project.FullName $folder

            if (Test-Path -LiteralPath $targetPath) {

                $folderSize = (
                    Get-ChildItem -LiteralPath $targetPath -Recurse -File -ErrorAction SilentlyContinue |
                    Measure-Object Length -Sum
                ).Sum

                $projectCleanupSize += $folderSize
                $pathsToDelete += $targetPath
            }
        }

        if ($pathsToDelete.Count -gt 0) {

            $cleanupTargets += [PSCustomObject]@{
                Project = $project.Name
                SizeGB  = [math]::Round($projectCleanupSize / 1GB, 2)
                Paths   = $pathsToDelete
            }
        }
    }

    if ($cleanupTargets.Count -eq 0) {

        Write-Host "No Unity cleanup targets found." -ForegroundColor DarkYellow -BackgroundColor Red
        Write-Host "================================================================"
        return
    }

    Write-Host ""
    Write-Host "================ CLEANUP PREVIEW ================" -ForegroundColor Cyan

    $cleanupTargets | Format-Table Project, SizeGB -AutoSize

    $totalCleanup = ($cleanupTargets.SizeGB | Measure-Object -Sum).Sum

    Write-Host ""
    Write-Host "Total Space Reclaimable: $totalCleanup GB" -ForegroundColor Green
    Write-Host "=================================================" -ForegroundColor DarkCyan
    Write-Host ""

    $confirm = Read-Host "Proceed with cleanup? (Y/N)"

    if ($confirm -notin @("Y", "y")) {

        Write-Host "Cleanup cancelled." -ForegroundColor DarkYellow
        return
    }

    Write-Host ""
    Write-Host "Starting cleanup..." -ForegroundColor Yellow
    Write-Host ""

    foreach ($project in $cleanupTargets) {

        Write-Host "Cleaning project: $($project.Project)" -ForegroundColor Yellow

        foreach ($path in $project.Paths) {

            if (Test-Path -LiteralPath $path) {

                Write-Host "Removing: $path" -ForegroundColor DarkYellow

                Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        Write-Host "Freed approx: $($project.SizeGB) GB" -ForegroundColor Green
        Write-Host ""
    }

    Write-Host "Cleanup completed." -ForegroundColor Green
    Wait-ReturnOrExit
}

# ------------------------------------------------------------
# Function: Backup Scripts
# ------------------------------------------------------------
function Backup-UnityScripts {

    Write-Host ""
    Write-Host "===== Unity Script Backup =====" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "1 - Single zip containing ALL scripts" -ForegroundColor Green
    Write-Host "2 - Separate zip for EACH project" -ForegroundColor Green
    Write-Host "3 - Cancel" -ForegroundColor DarkGray
    Write-Host ""

    $mode = Read-Host "Select backup mode"

    if ($mode -eq "3") { return }

    $projects = Get-UnityProjects

    $backupRoot = Join-Path $scriptDir "ScriptBackups"

    if (!(Test-Path $backupRoot)) {
        New-Item -ItemType Directory -Path $backupRoot | Out-Null
    }

    $dateStamp = Get-Date -Format "yyyy-MM-dd_HH-mm"

    if ($mode -eq "1") {

        $tempFolder = Join-Path $backupRoot "TempBackup"

        if (Test-Path $tempFolder) {
            Remove-Item $tempFolder -Recurse -Force
        }

        New-Item -ItemType Directory -Path $tempFolder | Out-Null
        $total = $projects.Count
        $i = 0
        foreach ($project in $projects) {

            $scriptsPath = Join-Path $project.AssetsPath "Scripts"

            if (Test-Path -LiteralPath $scriptsPath) {
                $i++

                Show-ScanProgress $i $total $project.Name

                $dest = Join-Path $tempFolder $project.Name
                Copy-Item -LiteralPath $scriptsPath -Destination $dest -Recurse -Force
            }
        }

        $zipFile = Join-Path $backupRoot "UnityScripts_Backup_$dateStamp.zip"

        Compress-Archive -Path (Join-Path $tempFolder "*") -DestinationPath $zipFile -Force

        Remove-Item $tempFolder -Recurse -Force

        Write-Host ""
        Write-Host "Backup created:" -ForegroundColor Green
        Write-Host $zipFile -ForegroundColor Gray
    }

    elseif ($mode -eq "2") {

        foreach ($project in $projects) {

            $scriptsPath = Join-Path $project.AssetsPath "Scripts"

            if (Test-Path -LiteralPath $scriptsPath) {

                Write-Host "Zipping scripts from: $($project.Name)" -ForegroundColor Yellow

                $zipFile = Join-Path $backupRoot "$($project.Name)_Scripts_$dateStamp.zip"

                $files = Get-ChildItem -LiteralPath $scriptsPath -Recurse -File -Filter *.cs

                if ($files.Count -gt 0) {

                    Compress-Archive -LiteralPath $files.FullName -DestinationPath $zipFile -Force
                }
            }
        }

        Write-Host ""
        Write-Host "All project backups completed." -ForegroundColor Green
    }

    else {

        Write-Host "Invalid option." -ForegroundColor Red
    }

    Wait-ReturnOrExit
}

# ------------------------------------------------------------
# Function: Dashboard
# ------------------------------------------------------------
function Show-UnityDashboard {

    Write-Host ""
    Write-Host "================ UNITY PROJECT DASHBOARD ================" -ForegroundColor Cyan
    Write-Host ""

    $projects = Get-UnityProjects
    $results = @()
    $total = $projects.Count
    $i = 0
    foreach ($project in $projects) {

        #Write-Host "Scanning project: $($project.Name)" -ForegroundColor Yellow
        $i++

        Show-ScanProgress $i $total $project.Name
        $scriptFiles = Get-ChildItem -LiteralPath $project.AssetsPath -Recurse -File -Filter *.cs -ErrorAction SilentlyContinue
        $scriptCount = $scriptFiles.Count

        $projectSize = (
            Get-ChildItem -LiteralPath $project.FullName -Recurse -File -ErrorAction SilentlyContinue |
            Measure-Object Length -Sum
        ).Sum

        $projectSizeGB = [math]::Round($projectSize / 1GB, 2)

        $cleanupFolders = @("Library", "Temp", "Obj", "Logs")
        $cleanupSize = 0

        foreach ($folder in $cleanupFolders) {

            $path = Join-Path $project.FullName $folder

            if (Test-Path -LiteralPath $path) {

                $size = (
                    Get-ChildItem -LiteralPath $path -Recurse -File -ErrorAction SilentlyContinue |
                    Measure-Object Length -Sum
                ).Sum

                $cleanupSize += $size
            }
        }

        $cleanupGB = [math]::Round($cleanupSize / 1GB, 2)

        $item = Get-Item -LiteralPath $project.FullName -ErrorAction SilentlyContinue
        $lastModified = if ($item) { $item.LastWriteTime.ToString("yyyy-MM-dd") } else { "Unknown" }

        $results += [PSCustomObject]@{
            Project         = $project.Name
            Scripts         = $scriptCount
            "Size(GB)"      = $projectSizeGB
            "Cleanup(GB)"   = $cleanupGB
            "Last Modified" = $lastModified
        }
    }

    Write-Host ""
    $results | Sort-Object "Cleanup(GB)" -Descending | Format-Table -AutoSize

    $totalProjects = $results.Count
    $totalScripts = ($results.Scripts | Measure-Object -Sum).Sum
    $totalSize = ($results."Size(GB)" | Measure-Object -Sum).Sum
    $totalCleanup = ($results."Cleanup(GB)" | Measure-Object -Sum).Sum

    Write-Host ""
    Write-Host "=========================================================" -ForegroundColor DarkCyan
    Write-Host "Total Projects : $totalProjects" -ForegroundColor White
    Write-Host "Total Scripts  : $totalScripts" -ForegroundColor White
    Write-Host "Disk Usage     : $totalSize GB" -ForegroundColor Yellow
    Write-Host "Cleanup Gain   : $totalCleanup GB" -ForegroundColor Green
    Write-Host "=========================================================" -ForegroundColor DarkCyan

    Wait-ReturnOrExit
}

# ------------------------------------------------------------
# Function: Archive Assets Data
# ------------------------------------------------------------
function New-FinalUnityAssetsArchive {

    Write-Host ""
    Write-Host "================ FINAL UNITY ASSETS ARCHIVE ================" -ForegroundColor Cyan

    $projects = Get-UnityProjects

    if (!$projects) {
        Write-Host "No Unity projects found." -ForegroundColor Red
        return
    }

    $excludedAssetFolders = @(
        "Plugins",
        "Extensions",
        "Samples",
        "Scenes",
        "Scene",
        "ThirdParty",
        "StreamingAssets"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
    $zipName = "UnityAssets_FinalArchive_$timestamp.zip"
    $zipPath = Join-Path $scriptDir $zipName

    Write-Host ""
    Write-Host "Preparing archive..." -ForegroundColor Yellow

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::Open($zipPath, "Create")

    $total = $projects.Count
    $i = 0

    foreach ($project in $projects) {

        $i++
        Show-ScanProgress $i $total $project.Name

        $assetFolders = Get-ChildItem -Path $project.AssetsPath -Directory |
        Where-Object { $excludedAssetFolders -notcontains $_.Name }

        foreach ($folder in $assetFolders) {

            $files = Get-ChildItem $folder.FullName -Recurse -File

            foreach ($file in $files) {

                $relativePath = $file.FullName.Substring($project.AssetsPath.Length + 1)

                $zipEntry = Join-Path "Assets" $project.Name
                $zipEntry = Join-Path $zipEntry $relativePath

                $zipEntry = $zipEntry.Replace("\", "/")

                [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                    $zip,
                    $file.FullName,
                    $zipEntry,
                    [System.IO.Compression.CompressionLevel]::Optimal
                )
            }
        }
    }

    $zip.Dispose()

    Write-Host ""
    Write-Host "Archive created:" -ForegroundColor Green
    Write-Host $zipPath -ForegroundColor Gray

    Write-Host ""
    $confirm = (Read-Host "Delete ALL project folders? (yes/no)").ToLower()

    if ($confirm -in @("yes", "y", "ok", "confirm")) {

        foreach ($project in $projects) {

            Write-Host "Deleting project: $($project.Name)" -ForegroundColor DarkYellow
            Remove-Item -LiteralPath $project.FullName -Recurse -Force
        }

        Write-Host ""
        Write-Host "All projects deleted." -ForegroundColor Green
    }
    else {

        Write-Host "Projects were NOT deleted." -ForegroundColor Yellow
    }
}

# -------------------------------------------------
# Startup Cleanup - Remove leftover temp folders
# -------------------------------------------------
function Initialize-ScriptEnvironment {

    Write-Host ""
    Write-Host "Checking for leftover temporary folders..." -ForegroundColor DarkCyan

    $tempFolders = @(
        "TempBackup",
        "_TempMergedAssets"
    )

    foreach ($folderName in $tempFolders) {

        $path = Join-Path $scriptDir $folderName

        if (Test-Path $path) {

            Write-Host "Removing leftover temp folder: $folderName" -ForegroundColor DarkYellow

            try {
                Remove-Item $path -Recurse -Force -ErrorAction Stop
                Write-Host "Removed successfully." -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to remove $folderName : $_" -ForegroundColor Red
            }
        }
    }
}

# ------------------------------------------------------------
# Exit
# ------------------------------------------------------------
function Exit-Tool {

    Write-Host ""
    Write-Host "Closing Unity Projects Archive Tool..." -ForegroundColor Cyan
    Write-Host ""

    exit
}

function Show-Header {
    Write-Host ""
    $versionString = $ScriptVersion -join "."
    Write-Host "============================================================" -ForegroundColor DarkCyan
    Write-Host "Unity Projects Archive Tool" -ForegroundColor Cyan
    Write-Host "Root directory: $scriptDir" -ForegroundColor Gray
    Write-Host "Version: $versionString" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor DarkCyan
}

# ============================================================
# MAIN MENU
# ============================================================
Clear-Host
Show-Header
Start-Sleep -Milliseconds 400

Initialize-ScriptEnvironment

while ($true) {

    Write-Host ""
    Write-Host "1 - Project Dashboard" -ForegroundColor DarkCyan
    Write-Host "2 - Scan Projects" -ForegroundColor Cyan
    Write-Host "3 - Cleanup Projects" -ForegroundColor Yellow
    Write-Host "4 - Backup Scripts" -ForegroundColor Green
    Write-Host "5 - Final Assets Archive (Compress + Optional Delete)" -ForegroundColor DarkYellow
    Write-Host "6 - Exit" -ForegroundColor Red
    Write-Host ""

    Write-Host "Select an option (1-6) or press ESC to exit: " -ForegroundColor Gray 
    

    $key = [System.Console]::ReadKey($true)

    if ($key.Key -eq "Escape") {
        Exit-Tool
    }

    $choice = $key.KeyChar
    Write-Host $choice
    switch ($choice) {

        "1" { Show-UnityDashboard }

        "2" { Get-UnityProjectsReport }

        "3" { Clear-UnityProjectCache }

        "4" { Backup-UnityScripts }

        "5" { New-FinalUnityAssetsArchive }

        "6" { Exit-Tool }

        default {
            Write-Host ""
            Write-Host "Invalid option, please try again." -ForegroundColor Red
        }
    }
}