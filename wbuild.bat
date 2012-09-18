@echo off
rem windows batch script for building clover
rem 2012-09-06 apianti

rem get default EDK2 tools and arch
@call %WORKSPACE%\Clover\GetVariables.bat

rem setup current dir and edk2 if needed
pushd .
set CURRENTDIR=%CD%
if not defined WORKSPACE (
   echo Searching for EDK2
   goto searchforedk
)

rem have edk2 prepare to build
:foundedk
   echo Found EDK2. Generating %WORKSPACE%\Clover\Version.h
   cd %WORKSPACE%\Clover
   rem get svn revision number
   svnversion -n > vers.txt
   set /p s= < vers.txt
   del vers.txt
   set SVNREVISION=

   rem get the current revision number
   :fixrevision
      if x%s% == x goto generateversion
      set c=%s:~0,1%
      set s=%s:~1%
      if x%c::=% == x goto generateversion
      if x%c:M=% == x goto generateversion
      if x%c:S=% == x goto generateversion
      if x%c:P=% == x goto generateversion
      set SVNREVISION=%SVNREVISION%%c%
      goto fixrevision

   :generateversion
      rem check for revision number
      if x%SVNREVISION% == x goto noedk
      rem generate build date and time
      set BUILDDATE=
      echo Dim cdt, output, temp > buildtime.vbs
      rem output year
      echo cdt = Now >> buildtime.vbs
      echo output = Year(cdt) ^& "-" >> buildtime.vbs
      rem output month
      echo temp = Month(cdt) >> buildtime.vbs
      echo If temp ^< 10 Then >> buildtime.vbs
      echo    output = output ^& "0" >> buildtime.vbs
      echo End If >> buildtime.vbs
      echo output = output ^& temp ^& "-" >> buildtime.vbs
      rem output day
      echo temp = Day(cdt) >> buildtime.vbs
      echo If temp ^< 10 Then >> buildtime.vbs
      echo    output = output ^& "0" >> buildtime.vbs
      echo End If >> buildtime.vbs
      echo output = output ^& temp ^& " " >> buildtime.vbs
      rem output hours
      echo temp = Hour(cdt) >> buildtime.vbs
      echo If temp ^< 10 Then >> buildtime.vbs
      echo    output = output ^& "0" >> buildtime.vbs
      echo End If >> buildtime.vbs
      echo output = output ^& temp ^& ":" >> buildtime.vbs
      rem output minutes
      echo temp = Minute(cdt) >> buildtime.vbs
      echo If temp ^< 10 Then >> buildtime.vbs
      echo    output = output ^& "0" >> buildtime.vbs
      echo End If >> buildtime.vbs
      echo output = output ^& temp ^& ":" >> buildtime.vbs
      rem output seconds
      echo temp = Second(cdt) >> buildtime.vbs
      echo If temp ^< 10 Then >> buildtime.vbs
      echo    output = output ^& "0" >> buildtime.vbs
      echo End If >> buildtime.vbs
      echo output = output ^& temp >> buildtime.vbs
      echo Wscript.Echo output >> buildtime.vbs
      cscript //Nologo buildtime.vbs > buildtime.txt
      del buildtime.vbs
      set /p BUILDDATE= < buildtime.txt
      del buildtime.txt

      rem generate version.h
      echo // Autogenerated Version.h> Version.h
      echo #define FIRMWARE_VERSION "2.31">> Version.h
      echo #define FIRMWARE_BUILDDATE "%BUILDDATE%">> Version.h
      echo #define FIRMWARE_REVISION "%SVNREVISION%">> Version.h
      echo #define REVISION_STR "Clover revision: %SVNREVISION%">> Version.h
      cd %CURRENTDIR%

      rem build clover
      set PARAMS=%*
      if x"%PARAMS%" == x"" goto buildall
      if not x"%PARAMS:-h=%" == x"%PARAMS%" (
         build --help
         goto exitscript
      )
      if not x"%PARAMS:--help=%" == x"%PARAMS%" (
         build --help
         goto exitscript
      )
      if not x"%PARAMS:--version=%" == x"%PARAMS%" (
         build --version
         goto exitscript
      )
      if x"%PARAMS:-p=%" == x"%PARAMS%" goto buildall
      rem build specific dsc
      echo Building selected...
      build %*
      goto exitscript

      :buildall
         rem build all
         echo Building all...
         echo Building CloverEFI IA32 (boot) ...
         build -p %WORKSPACE%\Clover\CloverIa32.dsc -a IA32 %*
         if not x"%errorlevel%" == x"0" goto exitscript
		 call PostBuild.bat IA32
		 
         echo Building CloverIA32.efi ...
         build -p %WORKSPACE%\Clover\rEFIt_UEFI\rEFIt.dsc -a IA32 %*
         if not x"%errorlevel%" == x"0" goto exitscript
         copy /b %WORKSPACE%\Build\rEFIt\%TARGET%_%TOOL_CHAIN_TAG%\IA32\CLOVERIA32.efi %WORKSPACE%\Clover\CloverPackage\CloverV2\EFI\BOOT
         if not x"%errorlevel%" == x"0" goto exitscript
		 
         echo Building CloverEFI X64 (boot) ...
         build -p %WORKSPACE%\Clover\CloverX64.dsc -a X64 %*
         if not x"%errorlevel%" == x"0" goto exitscript
		 call PostBuild.bat X64
		 
         echo Building CloverX64.efi ...
         build -p %WORKSPACE%\Clover\rEFIt_UEFI\rEFIt64.dsc -a X64 %*
         if not x"%errorlevel%" == x"0" goto exitscript
         copy /b %WORKSPACE%\Build\rEFIt\%TARGET%_%TOOL_CHAIN_TAG%\X64\CLOVERX64.efi %WORKSPACE%\Clover\CloverPackage\CloverV2\EFI\BOOT
         if not x"%errorlevel%" == x"0" goto exitscript
         goto exitscript
   
:searchforedk
   if exist edksetup.bat (
      call edksetup.bat
      @echo off
      goto foundedk
   )
   if x"%CD%" == x"%~d0%\" (
      goto noedk
   )
   cd ..
   goto searchforedk

:noedk
   cd %CURRENTDIR%

:exitscript