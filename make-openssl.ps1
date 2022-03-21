#
# Make-OpenSSL
# Krzysztof Cieślak K!2018
# Last update: 2018-05-07
#
# Usage: 
#       .\make-openssl -Source https://www.openssl.org/source/openssl-1.1.0g.tar.gz
#       .\make-openssl -TryGetLatestSource
#
param (
    [parameter(ParameterSetName="Source", Position=0)]
    [string]$Source,

    [switch]$TryGetLatestSource
)

if (-not $Source -and -not $TryGetLatestSource) {
    Write-host -ForeGroundColor Red "Source is not set. Copy link from https://www.openssl.org/source/ or run with -TryGetLatestSource parameter.";
    exit;
}

if ($TryGetLatestSource) {
    $Source = . .\Get-OpenSSLSourceLinks.ps1 -WithoutPre -WithoutFips | Sort-Object Name -Desc | Select-Object -ExpandProperty Link -First 1
    write-host "- Source:"$Source
}

# -=- Variables -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# https://www.openssl.org/community/omc.html
$fprints = 
    "8657ABB260F056B1E5190839D9C4D26D0E604491", # Matt Caswell matt@openssl.org
    "7953AC1FBC3DC8B3B292393ED5E9E43F7DF9EE8C"; # Richard Levitte levitte@openssl.org

$SourceSHA256 = $Source + ".sha256";
$SourceSHA1 = $Source + ".sha1";
$SourcePGP = $Source + ".asc";

$CurrentDir = $PSScriptRoot;

$DestinationFile = Join-Path $CurrentDir $([io.path]::GetFileName($Source));
$DestinationFileSHA256 = Join-Path $CurrentDir $([io.path]::GetFileName($SourceSHA256));
$DestinationFileSHA1 = Join-Path $CurrentDir $([io.path]::GetFileName($SourceSHA1));
$DestinationFilePGP = Join-Path $CurrentDir $([io.path]::GetFileName($SourcePGP));
$DestinationFilePGP_PublicKey = Join-Path $CurrentDir "publickey.asc" 
$DestinationFilePGP_PublicKey_GPG_format = Join-Path $CurrentDir "publickey.gpg";

$vcvarsall = 
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

# -=- Download -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
$startTime = get-date;

write-host "[0] Checking environment"
try { gpg -h | out-null } catch { Write-host -ForeGroundColor Red "GPG is not installed or path is not set."; exit; }
try { 7z | out-null } catch { Write-host -ForeGroundColor Red "7zip is not installed or path is not set."; exit; }
try { perl -v | out-null } catch { Write-host -ForeGroundColor Red "Perl is not installed or path is not set."; exit; }
try { nasm -v | out-null } catch { Write-host -ForeGroundColor Red "NASM is not installed or path is not set."; exit; }

$vcvarsall_path = $vcvarsall | Where-Object { Test-Path $_ } | Select-Object
if ($vcvarsall_path -eq 0) { Write-host -ForeGroundColor Red "vcvarsall.bat not found."; exit; }

write-host "[1] Downloading"
write-host "- Downloading $Source -> $DestinationFile"
Invoke-WebRequest $Source -O $DestinationFile;
write-host "- Downloading $SourceSHA256 -> $DestinationFileSHA256"
Invoke-WebRequest $SourceSHA256 -O $DestinationFileSHA256;
write-host "- Downloading $SourceSHA1 -> $DestinationFileSHA1"
Invoke-WebRequest $SourceSHA1 -O $DestinationFileSHA1;
write-host "- Downloading $SourcePGP -> $DestinationFilePGP" 
Invoke-WebRequest $SourcePGP -O $DestinationFilePGP;

# -=- Veryfication -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

write-host "[2] Verifying"

$sha256 = (Get-FileHash -Algorithm SHA256 $DestinationFile).Hash
$sha1 = (Get-FileHash -Algorithm SHA1 $DestinationFile).Hash

$sha256_from_file = (Get-Content $DestinationFileSHA256).ToUpper();
$sha1_from_file = (Get-Content $DestinationFileSHA1).ToUpper();

$sha256_result = $sha256_from_file.Equals($sha256);
$sha1_result = $sha1_from_file.Equals($sha1); 

if ($sha256_result) {
    write-host "- SHA256: $sha256_result";
}
else {
    Write-host -ForeGroundColor Red "SHA256 verification error. Hashes doesn't match.";
    exit;
}

if ($sha1_result) {
    write-host "- SHA1: $sha1_result";
}
else {
    Write-host -ForeGroundColor Red "SHA1 verification error. Hashes doesn't match.";
    exit;
}

write-host "- PGP:"

foreach ($fprint in $fprints) {
    $pgpkey_url = "https://keys.openpgp.org/vks/v1/by-fingerprint/$fprint";
    

    write-host "- Downloading $pgpkey_url -> $DestinationFilePGP"
    Invoke-WebRequest $pgpkey_url -O $DestinationFilePGP_PublicKey;

    gpg -o $DestinationFilePGP_PublicKey_GPG_format --yes --dearmour $DestinationFilePGP_PublicKey
    $gpgout = gpg --status-fd 1  --no-default-keyring --keyring $DestinationFilePGP_PublicKey_GPG_format --trust-mode always --verify $DestinationFilePGP; 

    $pgp_result = 0;
    $gpgout | Where-Object { $_.ToUpper().Contains("GOODSIG") -or $_.ToUpper().Contains("VALIDSIG $fprint") } | ForEach-Object { $pgp_result++; }
    $pgp_result = $pgp_result -eq 2;

    if ($pgp_result) { break; }
}

if ($pgp_result) {
    write-host "- PGP: $pgp_result";
}
else {
    Write-host -ForeGroundColor Red "PGP verification error. Check file or signature.";
    exit;
}

# -=- Decompression -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

write-host "[3] Decompression"
$tar_fileName = [io.path]::GetFileNameWithoutExtension($DestinationFile);
$fileName = [io.path]::GetFileNameWithoutExtension($tar_fileName);

$directory_x86_source = join-path $CurrentDir $($fileName + "-x86-src");
$directory_x64_source = join-path $CurrentDir $($fileName + "-x64-src");

RemoveDirectory $directory_x86_source;
RemoveDirectory $directory_x64_source;

7z x -y $DestinationFile > $null 2>&1

write-host "- extracting tar for x86 source"
7z x -y -aoa $tar_fileName > $null 2>&1  

Rename-Item $filename $directory_x86_source;

write-host "- extracting tar for x64 source"
7z x -y -aoa $tar_fileName  > $null 2>&1

Rename-Item $filename $directory_x64_source;

# -=- COMPILE -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

write-host "[4] Building"

$CurrentDriveLetter = Split-Path -Path $CurrentDir -Qualifier

# x86 version -=-
$directory_x86_release = join-path $CurrentDir $($fileName + "-x86-release");
RemoveDirectory $directory_x86_release;
$perl_x86_command = "perl Configure VC-WIN32 --prefix=" + $directory_x86_release;
$command_line = "`"$vcvarsall_path`" x86 & $CurrentDriveLetter & cd $directory_x86_source & $perl_x86_command & nmake & nmake test & nmake install & exit";
cmd /k $command_line

# x64 version -=-
$directory_x64_release = join-path $CurrentDir $($fileName + "-x64-release");
RemoveDirectory $directory_x64_release;
$perl_x64_command = "perl Configure VC-WIN64A --prefix=" + $directory_x64_release;
$command_line = "`"$vcvarsall_path`" amd64 & $CurrentDriveLetter & cd $directory_x64_source & $perl_x64_command & nmake & nmake test & nmake install & exit";
cmd /k $command_line

# -=- CLEANING -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

write-host "[5] Cleaning";

RemoveFile $DestinationFile;
RemoveFile $(join-path $currentDir $tar_fileName);
RemoveFile $DestinationFileSHA256;
RemoveFile $DestinationFileSHA1;
RemoveFile $DestinationFilePGP;
RemoveFile $DestinationFilePGP_PublicKey; 
RemoveFile $DestinationFilePGP_PublicKey_GPG_format;

RemoveDirectory $directory_x86_source;
RemoveDirectory $directory_x64_source;

$endTime = get-date;
write-host "Execution time: $($endTime-$startTime).";
