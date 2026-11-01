@echo off

rem
rem End to end tests for TypeProviders
rem To succeed it depends on both the coreclr compiler and the net40 desktop compiler being built
rem It only runs under ci_part3
rem

setlocal
set __scriptpath=%~dp0
set configuration=Debug

rem Read TFM from centralized source using MSBuild
for /f "usebackq delims=" %%a in (`dotnet msbuild "%__scriptpath%..\..\..\eng\TargetFrameworks.props" --getProperty:FSharpNetCoreProductTargetFramework`) do set PRODUCT_TFM=%%a

:parseargs
if "%1" == "" goto argsdone
if /i "%1" == "-c" goto set_configuration

echo Unsupported argument: %1
goto failure

:set_configuration
set configuration=%2
shift
shift
goto parseargs

:argsdone

pushd %__scriptpath%
rem
rem Build typeprovider package with desktop compiler
rem Test it with both desktop and coreclr compilers
rem

if not '%NUGET_PACKAGES%' == '' rd %NUGET_PACKAGES%\BasicProvider /s /q
taskkill /F /IM dotnet.exe

echo dotnet build BasicProvider.DesignTime\BasicProvider.DesignTime.fsproj -o %~dp0artifacts -c %configuration% -bl -p:FSharpTestCompilerVersion=net40
     dotnet build BasicProvider.DesignTime\BasicProvider.DesignTime.fsproj -o %~dp0artifacts -c %configuration% -bl -p:FSharpTestCompilerVersion=net40
if ERRORLEVEL 1 echo Error: TestBasicProvider failed  && goto :failure

rem echo dotnet pack BasicProvider\BasicProvider.fsproj -o %~dp0artifacts -c %configuration% -v minimal -p:FSharpTestCompilerVersion=net40 s
rem      dotnet pack BasicProvider\BasicProvider.fsproj -o %~dp0artifacts -c %configuration% -v minimal -p:FSharpTestCompilerVersion=net40
rem if ERRORLEVEL 1 echo Error: TestBasicProvider failed  && goto :failure
rem 
rem echo dotnet test --project BasicProvider.Tests\BasicProvider.Tests.fsproj -c %configuration% -v minimal -p:TestTargetFramework=net472 -p:FSharpTestCompilerVersion=net40
rem      dotnet test --project BasicProvider.Tests\BasicProvider.Tests.fsproj -c %configuration% -v minimal -p:TestTargetFramework=net472 -p:FSharpTestCompilerVersion=net40
rem if ERRORLEVEL 1 echo Error: TestBasicProvider failed  && goto :failure
rem 
rem echo dotnet test --project BasicProvider.Tests\BasicProvider.Tests.fsproj -c %configuration% -v minimal -p:TestTargetFramework=%PRODUCT_TFM% -p:FSharpTestCompilerVersion=coreclr
rem      dotnet test --project BasicProvider.Tests\BasicProvider.Tests.fsproj -c %configuration% -v minimal -p:TestTargetFramework=%PRODUCT_TFM% -p:FSharpTestCompilerVersion=coreclr
rem if ERRORLEVEL 1 echo Error: TestBasicProvider failed  && goto :failure
rem 
rem rem
rem rem Build typeprovider package with coreclr compiler
rem rem Test it with both desktop and coreclr compilers
rem rem
rem if not '%NUGET_PACKAGES%' == '' rd %NUGET_PACKAGES%\BasicProvider /s /q
rem 
rem echo dotnet pack BasicProvider\BasicProvider.fsproj -o %~dp0artifacts -c %configuration% -v minimal -p:FSharpTestCompilerVersion=coreclr
rem      dotnet pack BasicProvider\BasicProvider.fsproj -o %~dp0artifacts -c %configuration% -v minimal -p:FSharpTestCompilerVersion=coreclr
rem if ERRORLEVEL 1 echo Error: TestBasicProvider failed  && goto :failure
rem 
rem echo dotnet test --project BasicProvider.Tests\BasicProvider.Tests.fsproj -c %configuration% -v minimal -p:TestTargetFramework=net472 -p:FSharpTestCompilerVersion=net40
rem      dotnet test --project BasicProvider.Tests\BasicProvider.Tests.fsproj -c %configuration% -v minimal -p:TestTargetFramework=net472 -p:FSharpTestCompilerVersion=net40
rem if ERRORLEVEL 1 echo Error: TestBasicProvider failed  && goto :failure
rem 
rem echo dotnet test --project BasicProvider.Tests\BasicProvider.Tests.fsproj -c %configuration% -v minimal -p:TestTargetFramework=%PRODUCT_TFM% -p:FSharpTestCompilerVersion=coreclr
rem      dotnet test --project BasicProvider.Tests\BasicProvider.Tests.fsproj -c %configuration% -v minimal -p:TestTargetFramework=%PRODUCT_TFM% -p:FSharpTestCompilerVersion=coreclr
rem if ERRORLEVEL 1 echo Error: TestBasicProvider failed  && goto :failure
rem 
:success
endlocal
echo Succeeded
popd
exit /b 0

:failure
endlocal
echo Failed
popd
exit /b 1
