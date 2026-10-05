@echo off
REM Strictly cmd.exe so the backtick in ConcatEnumerator`2 survives to argv untouched.
REM Usage: dumper.bat --list   <asm>
REM         dumper.bat        <asm>  <ClassName>  <MethodName>
REM Pass the class arg as a BARE token (no double-quotes, no escaped backtick).
SETLOCAL
dotnet run --project "%~dp0dumper.csproj" %*
