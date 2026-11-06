@echo off
rem build.cmd -- compile src\main\java into src\main\webapp\WEB-INF\classes
rem so VS Code's exploded Tomcat deployment can load the DAO classes.
rem Run it (double-click, or "build" in a terminal opened in fittrack\),
rem then right-click Tomcat -> Publish Server (Full).
setlocal EnableDelayedExpansion
cd /d "%~dp0"

set "OUT=src\main\webapp\WEB-INF\classes"
set "JAVAC=javac"
if defined JAVA_HOME set "JAVAC=%JAVA_HOME%\bin\javac"

rem start clean so deleted/renamed classes don't linger
if exist "%OUT%" rmdir /s /q "%OUT%"
mkdir "%OUT%"
if not exist build mkdir build
if exist build\sources.txt del build\sources.txt

rem list every .java file, quoted, with forward slashes (safe with spaces)
for /r src\main\java %%f in (*.java) do (
    set "p=%%f"
    echo "!p:\=/!">> build\sources.txt
)
if not exist build\sources.txt (
    echo No .java files in src\main\java, nothing to compile.
    exit /b 0
)

"%JAVAC%" --release 21 -encoding UTF-8 -d "%OUT%" @build\sources.txt
if errorlevel 1 (
    echo.
    echo BUILD FAILED - fix the errors above.
    exit /b 1
)
echo.
echo Compiled into %OUT%
echo Now right-click Tomcat -^> Publish Server (Full).
