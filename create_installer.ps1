# PowerShell Script to build Icon Converter EXE
# Run with: .\Build-IconConverterExe.ps1

Write-Host "=== Icon Converter EXE Builder ===" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "NOTE: Some operations may require administrator privileges." -ForegroundColor Yellow
    Write-Host "If you encounter errors, try running this script as administrator." -ForegroundColor Yellow
    Write-Host ""
}

# Path to the Python script (change if needed)
$pythonScriptPath = "C:\Users\Local Admin\Downloads\BIG button folders (1)\BIG.extension\icon_converter.py"

# Check if the script exists
if (-not (Test-Path $pythonScriptPath)) {
    Write-Host "Error: Cannot find the Python script at: $pythonScriptPath" -ForegroundColor Red
    Write-Host "Please update the script path in this PowerShell script." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Create work directory if it doesn't exist
$workDir = Split-Path -Parent $pythonScriptPath
Set-Location $workDir
Write-Host "Working in directory: $workDir" -ForegroundColor Cyan

# Function to check if a package is installed
function Test-PackageInstalled {
    param (
        [string]$PackageName
    )
    
    try {
        $output = & pip show $PackageName 2>&1
        return ($LASTEXITCODE -eq 0)
    }
    catch {
        return $false
    }
}

# Check and install required packages
$packages = @("pyinstaller", "Pillow")
foreach ($package in $packages) {
    if (-not (Test-PackageInstalled -PackageName $package)) {
        Write-Host "Installing $package..." -ForegroundColor Yellow
        $output = & pip install $package 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to install $package. Please check your Python installation." -ForegroundColor Red
            Read-Host "Press Enter to exit"
            exit 1
        }
    }
    else {
        Write-Host "$package is already installed." -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Building executable with PyInstaller..." -ForegroundColor Cyan
Write-Host ""

# Run PyInstaller with redirected output to prevent PowerShell from treating it as errors
$process = Start-Process -FilePath "pyinstaller" -ArgumentList "--onefile", "--console", "`"$pythonScriptPath`"" -NoNewWindow -PassThru -Wait
if ($process.ExitCode -ne 0) {
    Write-Host ""
    Write-Host "Failed to build executable. PyInstaller exited with error code: $($process.ExitCode)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Build completed successfully!" -ForegroundColor Green

# Check if dist folder exists
$distFolder = Join-Path -Path $workDir -ChildPath "dist"
if (-not (Test-Path $distFolder)) {
    Write-Host "Warning: Cannot find the dist folder. Check if PyInstaller created it elsewhere." -ForegroundColor Yellow
} else {
    Write-Host "The executable is located in: $distFolder" -ForegroundColor Green
    
    # Get the executable name from the script name
    $exeName = [System.IO.Path]::GetFileNameWithoutExtension($pythonScriptPath) + ".exe"
    $exePath = Join-Path -Path $distFolder -ChildPath $exeName
    
    if (Test-Path $exePath) {
        # Copy the executable to the current directory for convenience
        Copy-Item -Path $exePath -Destination $workDir -Force
        Write-Host "Copied $exeName to: $workDir" -ForegroundColor Green
    } else {
        Write-Host "Warning: Cannot find the executable in the dist folder." -ForegroundColor Yellow
    }
}

Write-Host ""

# Add File Explorer integration (optional)
$addToContext = Read-Host "Would you like to add this tool to your right-click context menu? (y/n)"
if ($addToContext -eq "y" -or $addToContext -eq "Y") {
    if (-not $isAdmin) {
        Write-Host "Adding to context menu requires administrator privileges." -ForegroundColor Yellow
        Write-Host "Please run this script as administrator to enable this feature." -ForegroundColor Yellow
    }
    else {
        $exePath = Join-Path -Path $workDir -ChildPath ([System.IO.Path]::GetFileNameWithoutExtension($pythonScriptPath) + ".exe")
        if (Test-Path $exePath) {
            $regPath = "Registry::HKEY_CLASSES_ROOT\Directory\shell\IconConverter"
            
            try {
                New-Item -Path $regPath -Force | Out-Null
                Set-ItemProperty -Path $regPath -Name "(Default)" -Value "Convert Icons to Dark Mode"
                
                New-Item -Path "$regPath\command" -Force | Out-Null
                Set-ItemProperty -Path "$regPath\command" -Name "(Default)" -Value "`"$exePath`" -d `"%1`""
                
                Write-Host "Added to context menu successfully!" -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to add to context menu: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "Cannot find executable to add to context menu." -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "All done!" -ForegroundColor Cyan
Read-Host "Press Enter to exit"