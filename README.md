# make-openssl
Powershell script for compiling OpenSSL on Windows x86/x64.

#### Requirements
- Perl (https://www.activestate.com/activeperl)
- NASM (http://www.nasm.us/)
- 7zip (http://www.7-zip.org/)
- GPG (https://www.gpg4win.org/)
- GIT (https://git-scm.com/) for compiling source from github. (make-openssl-github-master.ps1)  

- Visual Studio command prompt tools.
  If you want to use other versions of VS add element to `$vcvarsall` array with full path to `vcvarsall.bat` file.

  Example:
  ```
  $vcvarsall =
    # Visual Studio 2019
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat",
    # Visual Studio 2017
    "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Auxiliary\Build\vcvarsall.bat",
    "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\VC\Auxiliary\Build\vcvarsall.bat"
  ```      

#### Usage example
  `.\make-openssl.ps1 https://www.openssl.org/source/openssl-1.1.1n.tar.gz`

  `.\make-openssl.ps1 -TryGetLatestSource`

<<<<<<< HEAD
##### Tested on Windows 10 (x64) with following sources:
- openssl-1.1.1n (https://www.openssl.org/source/openssl-1.1.1n.tar.gz)
- openssl-1.1.0h (https://www.openssl.org/source/openssl-1.1.0h.tar.gz)
- openssl-1.1.1-pre5 (https://www.openssl.org/source/openssl-1.1.1-pre5.tar.gz)
- openssl-1.1.1-pre4 (https://www.openssl.org/source/openssl-1.1.1-pre4.tar.gz)
- openssl-1.1.1-pre3
- openssl-1.1.1-pre2
- openssl-1.1.1-pre1
- openssl-1.1.0g (https://www.openssl.org/source/openssl-1.1.0g.tar.gz)

  `.\make-openssl-github-master.ps1`

##### Tested on Windows 10 (x64)
- openssl-1.1.1n (https://www.openssl.org/source/openssl-1.1.1n.tar.gz)
