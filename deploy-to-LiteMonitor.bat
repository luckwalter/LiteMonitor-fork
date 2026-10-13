@echo off
REM ============================================================
REM  LiteMonitor 本地部署脚本
REM  目标目录: C:\LiteMonitor (本机发布/运行目录)
REM
REM  策略: 先 publish 到临时暂存目录，再"挑选性"复制文件，
REM        绝不整目录覆盖 —— 这样 settings.json / HardwareHistory.json /
REM        TrafficHistory.json 等配置与历史数据永远不会被误伤。
REM
REM  注意: 单文件模式不会把 resources\*.exe 落到磁盘，需手动补齐，
REM        否则 FPS 计数与检查更新功能会失效。
REM ============================================================
setlocal

set DOTNET=C:\Users\luckw\.dotnet\dotnet.exe
set PROJ=%~dp0LiteMonitor.csproj
set DST=C:\LiteMonitor
set STAGE=%~dp0publish\_staging

echo ============================================================
echo  LiteMonitor 部署  -^> %DST%
echo ============================================================
echo.

echo [1/6] 关闭正在运行的 LiteMonitor ...
taskkill /F /IM LiteMonitor.exe /T >nul 2>&1
taskkill /F /IM LiteMonitorFPS.exe /T >nul 2>&1
ping -n 3 127.0.0.1 >nul

echo [2/6] 发布 net10 依赖式单文件版 ...
if exist "%STAGE%" rmdir /S /Q "%STAGE%"
"%DOTNET%" publish "%PROJ%" -c Release -r win-x64 --self-contained false -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -o "%STAGE%"
if errorlevel 1 (
    echo.
    echo [失败] 发布会报错，已中止部署。目标目录未做任何改动。
    exit /b 1
)

echo [3/6] 部署主程序 ...
if not exist "%DST%" mkdir "%DST%"
copy /Y "%STAGE%\LiteMonitor.exe" "%DST%\LiteMonitor.exe" >nul

echo [4/6] 同步 resources (语言 / 插件 / 主题) ...
if not exist "%DST%\resources" mkdir "%DST%\resources"
xcopy /Y /S /I /Q "%STAGE%\resources\lang"    "%DST%\resources\lang"    >nul
xcopy /Y /S /I /Q "%STAGE%\resources\plugins" "%DST%\resources\plugins" >nul
xcopy /Y /S /I /Q "%STAGE%\resources\themes"  "%DST%\resources\themes"  >nul

echo [5/6] 同步使用说明(必读).txt ...
copy /Y "%STAGE%\使用说明(必读).txt" "%DST%\使用说明(必读).txt" >nul

echo [6/6] 补齐单文件模式未落盘的辅助程序 ...
copy /Y "%~dp0resources\LiteMonitor.Updater.exe"    "%DST%\resources\LiteMonitor.Updater.exe" >nul
copy /Y "%~dp0resources\assets\LiteMonitorFPS.exe"  "%DST%\resources\LiteMonitorFPS.exe"      >nul

echo.
echo ============================================================
echo  部署完成。
echo.
echo  以下内容保持原样未被触碰:
echo    - settings.json           (你的个性化配置)
echo    - HardwareHistory.json    (硬件历史)
echo    - TrafficHistory.json     (流量历史)
echo    - 使用说明(必读).txt
echo.
echo  注意: HardwareHistoryLogger 写死了 7 天保留期,
echo        超过 7 天的历史数据会在启动时被自动裁剪。
echo ============================================================
endlocal
