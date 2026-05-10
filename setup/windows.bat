@echo off
color 0a
cd ..
@echo on
echo Installing dependencies...
echo This might take a few moments depending on your internet speed.
haxelib install lime 8.1.2
haxelib install openfl 9.3.3
haxelib install flixel 5.6.1
haxelib install flixel-addons 3.2.2
haxelib install flixel-tools 1.5.1
haxelib install hscript-iris 1.1.3
haxelib install tjson 1.4.0
haxelib install hxdiscord_rpc 1.2.4
haxelib install hxvlc 2.0.1 --skip-dependencies
haxelib set lime 8.1.2
haxelib set openfl 9.3.3
haxelib git flxanimate https://github.com/Dot-Stuff/flxanimate 768740a56b26aa0c072720e0d1236b94afe68e3e
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit 1906c4a96f6bb6df66562b3f24c62f4c5bba14a7
haxelib git funkin.vis https://github.com/FunkinCrew/funkVis 22b1ce089dd924f15cdc4632397ef3504d464e90
haxelib git grig.audio https://gitlab.com/haxe-grig/grig.audio.git cbf91e2180fd2e374924fe74844086aab7891666

@echo off
echo.
echo ============================================================
echo  Applying OpenAL fix for MSVC (OpenALAudioContext.h)...
echo  Fix: NOGDI + NOMINMAX + undef ERROR
echo  This prevents "String should be Bool" / C2059 errors.
echo ============================================================

:: Localiza o arquivo do Lime via haxelib path
for /f "delims=" %%P in ('haxelib path lime 2^>nul ^| findstr /i "include"') do (
    set "LIME_INCLUDE=%%P"
)

:: Caminho padrão caso o haxelib path não retorne o include
if not defined LIME_INCLUDE (
    for /f "delims=" %%H in ('haxelib config') do set "HAXELIB_ROOT=%%H"
    set "LIME_INCLUDE=%HAXELIB_ROOT%\lime\8,1,2\include"
)

set "OPENAL_HEADER=%LIME_INCLUDE%\lime\media\OpenALAudioContext.h"

if not exist "%OPENAL_HEADER%" (
    echo.
    echo [AVISO] Arquivo nao encontrado em:
    echo   %OPENAL_HEADER%
    echo   Aplique o fix manualmente - veja as instrucoes no README.
    echo.
    goto :skip_fix
)

:: Verifica se o fix já foi aplicado para não duplicar
findstr /c:"OPENAL_MSVC_FIX" "%OPENAL_HEADER%" >nul 2>&1
if %errorlevel% == 0 (
    echo [OK] Fix ja aplicado anteriormente. Pulando.
    goto :skip_fix
)

:: Cria arquivo temporário com o fix no topo + conteúdo original
set "TEMP_HEADER=%TEMP%\OpenALAudioContext_fixed.h"

(
    echo // OPENAL_MSVC_FIX — adicionado automaticamente pelo windows.bat
    echo // Evita conflito entre macros do Windows SDK e constantes do OpenAL
    echo // Erros corrigidos: C2059 'constante', C2238, "String should be Bool"
    echo #if defined^(_WIN32^) ^|^| defined^(_WIN64^)
    echo #ifndef NOGDI
    echo #  define NOGDI
    echo #endif
    echo #ifndef NOMINMAX
    echo #  define NOMINMAX
    echo #endif
    echo #ifdef ERROR
    echo #  undef ERROR
    echo #endif
    echo #endif // _WIN32 ^|^| _WIN64
    echo.
    type "%OPENAL_HEADER%"
) > "%TEMP_HEADER%"

copy /y "%TEMP_HEADER%" "%OPENAL_HEADER%" >nul
if %errorlevel% == 0 (
    echo [OK] Fix aplicado com sucesso em:
    echo   %OPENAL_HEADER%
) else (
    echo [ERRO] Nao foi possivel aplicar o fix. Tente rodar como Administrador.
)

:skip_fix
@echo on
echo.
echo Finished!
pause