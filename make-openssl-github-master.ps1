#
# Make-OpenSSL
# Krzysztof Cieślak K!2018
# Last update: 2018-05-07
#
# Usage: 
#       .\make-openssl-github-master
#
# -=- Variables -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
$CurrentDir = $PSScriptRoot;

$Source = "https://github.com/openssl/openssl.git";

$DestinationFolder_x86 = Join-Path $CurrentDir "openssl-github-master-x86-source"
$DestinationFolder_x64 = Join-Path $CurrentDir "openssl-github-master-x64-source"

$vcvarsall = 
    # Visual Studio 2019
    "c:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat",
    # Visual Studio 2017
    "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Auxiliary\Build\vcvarsall.bat",
    "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\VC\Auxiliary\Build\vcvarsall.bat"
        
# -=- Functions -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

function RemoveFile ($path) {
    Remove-Item -Force $path -ErrorVariable Err -ErrorAction SilentlyContinue;
} 

function RemoveDirectory ($path) {
    Remove-Item -R -Force $path -ErrorVariable Err -ErrorAction SilentlyContinue;
}

# -=- Environment -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-
$startTime = get-date;

write-host "[0] Checking environment"
try { perl -v | out-null } catch { Write-host -ForeGroundColor Red "Perl is not installed or path is not set."; exit; }
try { nasm -v | out-null } catch { Write-host -ForeGroundColor Red "NASM is not installed or path is not set."; exit; }
try { git --version | out-null } catch { Write-host -ForeGroundColor Red "GIT is not installed or path is not set."; exit; }

$vcvarsall_path = $vcvarsall | Where-Object { Test-Path $_ } | Select-Object
if ($vcvarsall_path -eq 0) { Write-host -ForeGroundColor Red "vcvarsall.bat not found."; exit; }

# -=- CLONE -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
write-host "[1] Cloning from github"
RemoveDirectory $DestinationFolder_x86
RemoveDirectory $DestinationFolder_x64

git clone $Source $DestinationFolder_x86
Copy-Item -Recurse $DestinationFolder_x86 $DestinationFolder_x64

# -=- COMPILE -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

write-host "[2] Building"

$CurrentDriveLetter = Split-Path -Path $CurrentDir -Qualifier

$fileName = $($null, $second_line, $null = Get-Content "$DestinationFolder_x86\readme"; $second_line).Trim().Replace(" ","-").ToLower()

# x86 version -=-
$directory_x86_release = join-path $CurrentDir $($fileName + "-x86-release");
RemoveDirectory $directory_x86_release;
$perl_x86_command = "perl Configure VC-WIN32 --prefix=" + $directory_x86_release;
$command_line = "`"$vcvarsall_path`" x86 & $CurrentDriveLetter & cd $DestinationFolder_x86 & $perl_x86_command & nmake & nmake test & nmake install & exit";
cmd /k $command_line

# x64 version -=-
$directory_x64_release = join-path $CurrentDir $($fileName + "-x64-release");
RemoveDirectory $directory_x64_release;
$perl_x64_command = "perl Configure VC-WIN64A --prefix=" + $directory_x64_release;
$command_line = "`"$vcvarsall_path`" amd64 & $CurrentDriveLetter & cd $DestinationFolder_x64 & $perl_x64_command & nmake & nmake test & nmake install & exit";
cmd /k $command_line

# -=- CLEANING -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

write-host "[3] Cleaning";
RemoveDirectory $DestinationFolder_x86
RemoveDirectory $DestinationFolder_x64

$endTime = get-date;
write-host "Execution time: $($endTime-$startTime).";
