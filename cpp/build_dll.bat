@echo off

rem Set up Visual Studio environment using the provided path
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"

rem Create output directory
@REM mkdir bin 2>nul
@REM set OBJ_DIR=obj
@REM set BIN_DIR=bin
set SRC_FILE="setvol_dll.cpp" 

@REM if not exist %OBJ_DIR% md %OBJ_DIR%
@REM if not exist %BIN_DIR% md %BIN_DIR%

rem Compile DLL
cl /W4 /EHsc /utf-8 /LD %SRC_FILE%
@REM /link /out:"%BIN_DIR%\setvol_dll.dll"
@REM    /Fo"%OBJ_DIR%\" ^
@REM    /Fe"%BIN_DIR%\setvol_dll.dll"

rem Check compilation result
if %ERRORLEVEL% == 0 (
    echo Compilation successful! DLL generated in bin directory
    echo Generated files:
    dir setvol_dll.* /B
    dumpbin /exports setvol_dll.dll
) else (
    echo Compilation failed!
    exit /b 1
)
