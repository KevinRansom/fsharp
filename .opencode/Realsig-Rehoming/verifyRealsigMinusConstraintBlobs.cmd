@echo off
dotnet run --project %~dp0\..\tools\dumper\dumper.csproj  "RuntimeHelpers" "takeInner@301" %*
