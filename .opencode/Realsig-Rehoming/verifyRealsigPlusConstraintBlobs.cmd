@echo off
dotnet run --project %~dp0\..\tools\dumper\dumper.csproj  "ConcatEnumerator`2" "takeInner@301" %*
