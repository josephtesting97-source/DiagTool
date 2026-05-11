param(
    [string]$OutputPath = (Get-Location).Path
)

# ==========================================
# WINDOWS DIAGNOSTICS TOOL
# ==========================================

# Create output directory if it doesn't exist
if (!(Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Build report filename
$ReportPath = Join-Path `
    $OutputPath `
    "PC-Diagnostic-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"

function Write-Report {
    param (
        [string]$Text
    )

    Add-Content -Path $ReportPath -Value $Text
}

function Header {
    Clear-Host

    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host " WINDOWS DIAGNOSTICS TOOL" -ForegroundColor Yellow
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Report "======================================"
    Write-Report " WINDOWS DIAGNOSTICS REPORT"
    Write-Report "======================================"
    Write-Report "Generated: $(Get-Date)"
    Write-Report ""
}

function System-Info {

    Write-Host "Collecting System Information..." -ForegroundColor Green

    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor

    $info = @"
SYSTEM INFORMATION
------------------
Computer Name : $env:COMPUTERNAME
User          : $env:USERNAME
OS            : $($os.Caption)
Version       : $($os.Version)
Architecture  : $($os.OSArchitecture)
CPU           : $($cpu.Name)

"@

    Write-Host $info
    Write-Report $info
}

function CPU-RAM {

    Write-Host "Checking CPU and RAM..." -ForegroundColor Green

    $cpuLoad = Get-CimInstance Win32_Processor |
        Measure-Object -Property LoadPercentage -Average |
        Select-Object -ExpandProperty Average

    $os = Get-CimInstance Win32_OperatingSystem

    $totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedRAM = [math]::Round($totalRAM - $freeRAM, 2)

    $info = @"
CPU / MEMORY
------------
CPU Usage : $cpuLoad%
Total RAM : $totalRAM GB
Used RAM  : $usedRAM GB
Free RAM  : $freeRAM GB

"@

    Write-Host $info
    Write-Report $info
}

function Disk-Info {

    Write-Host "Checking Disk Space..." -ForegroundColor Green

    $drives = Get-PSDrive -PSProvider FileSystem

    $diskInfo = "DISK INFORMATION`n------------------`n"

    foreach ($drive in $drives) {

        $used = [math]::Round(($drive.Used / 1GB), 2)
        $free = [math]::Round(($drive.Free / 1GB), 2)

        $diskInfo += @"
Drive $($drive.Name)
Used Space : $used GB
Free Space : $free GB

"@
    }

    Write-Host $diskInfo
    Write-Report $diskInfo
}

function Internet-Test {

    Write-Host "Testing Internet..." -ForegroundColor Green

    $test = Test-Connection 8.8.8.8 -Count 2 -Quiet

    if ($test) {
        $status = "CONNECTED"
    }
    else {
        $status = "NOT CONNECTED"
    }

    $info = @"
INTERNET STATUS
---------------
$status

"@

    Write-Host $info
    Write-Report $info
}

function Network-Info {

    Write-Host "Collecting Network Information..." -ForegroundColor Green

    $network = ipconfig

    $info = @"
NETWORK INFORMATION
-------------------
$network

"@

    Write-Host $info
    Write-Report $info
}

function Running-Processes {

    Write-Host "Collecting Top Processes..." -ForegroundColor Green

    $processes = Get-Process |
        Sort-Object WorkingSet -Descending |
        Select-Object -First 10 Name, Id,
        @{Name="RAM_MB";Expression={[math]::Round($_.WorkingSet / 1MB,2)}}

    $table = $processes | Format-Table -AutoSize | Out-String

    $info = @"
TOP PROCESSES
-------------
$table

"@

    Write-Host $table
    Write-Report $info
}

# =========================
# MAIN SCRIPT
# =========================

Header
System-Info
CPU-RAM
Disk-Info
Internet-Test
Network-Info
Running-Processes

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "REPORT SAVED TO:" -ForegroundColor Yellow
Write-Host $ReportPath -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan

#notepad $ReportPath
