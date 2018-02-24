# make-openssl
Powershell script to compile OpenSSL on Windows x86/x64

#### Requirments:
- Perl (https://www.activestate.com/activeperl)
- NASM (http://www.nasm.us/)
- 7zip (http://www.7-zip.org/)
- GPG (https://www.gpg4win.org/)
- Visual Studio 2017 with command prompt tools installed.
  If you want to use other versions of VS add element to `$vcvarsall` array with full path to `vcvarsall.bat` file.
  
  Example:
  ```
  $vcvarsall =
    # Visual Studio 2017
    "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Auxiliary\Build\vcvarsall.bat",
    "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\VC\Auxiliary\Build\vcvarsall.bat"
  ```      

#### Usage example:
  `.\make-openssl.ps1 https://www.openssl.org/source/openssl-1.1.0g.tar.gz`

##### Tested on Windows 10 (x64) with following sources:
- openssl-1.1.1-pre1 (https://www.openssl.org/source/openssl-1.1.1-pre1.tar.gz)
- openssl-1.1.0g (https://www.openssl.org/source/openssl-1.1.0g.tar.gz)
