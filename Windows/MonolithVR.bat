@echo off
pushd "%~dp0"
if not exist id1\pak0.pak goto missing
if not exist id1\pak1.pak goto missing
if exist "..\..\Maps\mvr_start.bsp" (
    copy /y "..\..\Maps\mvr_start.bsp" "mvr\maps\mvr_start.bsp" >nul || exit /b 1
    if exist "..\..\Maps\mvr_start.lit" (
        copy /y "..\..\Maps\mvr_start.lit" "mvr\maps\mvr_start.lit" >nul || exit /b 1
    ) else if exist "mvr\maps\mvr_start.lit" del "mvr\maps\mvr_start.lit"
)
ironwail.exe -nomapindex -game mvr +vr_enabled 1 +map mvr_start %*
set result=%errorlevel%
popd
exit /b %result%
:missing
echo Place your Quake pak0.pak and pak1.pak in the id1 folder.
pause
popd
exit /b 1
