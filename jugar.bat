@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

rem Busca Python: primero el del entorno virtual, si existe
set "PYTHON="
if exist ".venv\Scripts\python.exe" set "PYTHON=.venv\Scripts\python.exe"
for %%c in (py python python3) do (
    if not defined PYTHON (
        %%c --version >nul 2>&1 && set "PYTHON=%%c"
    )
)
if not defined PYTHON (
    echo No se encontro Python. Instalalo desde https://www.python.org/
    pause
    goto :eof
)


:menu
cls
echo.
echo   ==============================================
echo     TP2 - Busqueda en Pacman
echo   ==============================================
echo.
echo    1) Con vista   (se abre la ventana del juego)
echo    2) Sin vista   (solo los resultados, al instante)
echo    3) Salir
echo.
set "op="
set /p "op=  Elegi una opcion: "
if not defined op goto :eof
if "%op%"=="1" set "MODO=vista"    & goto :elegir
if "%op%"=="2" set "MODO=sinvista" & goto :elegir
if "%op%"=="3" goto :eof
goto :menu


:elegir
echo.
echo   Algoritmo:
echo    1) Profundidad (DFS)
echo    2) Anchura (BFS)
echo    3) Costo uniforme (UCS)
echo    4) A* (heuristica Manhattan)
echo    5) Los 4
set "op="
set "ALGS="
set /p "op=  Elegi una opcion: "
if "%op%"=="1" set "ALGS=dfs"
if "%op%"=="2" set "ALGS=bfs"
if "%op%"=="3" set "ALGS=ucs"
if "%op%"=="4" set "ALGS=astar"
if "%op%"=="5" set "ALGS=dfs bfs ucs astar"
if not defined ALGS goto :menu

echo.
echo   Laberinto:
echo    1) tp2Maze      (chico, ideal para explicar)
echo    2) mediumMaze   (mediano, donde mas se notan las diferencias)
set "op="
set "LAB="
set /p "op=  Elegi una opcion: "
if "%op%"=="1" set "LAB=tp2Maze"
if "%op%"=="2" set "LAB=mediumMaze"
if not defined LAB goto :menu

echo.
if "%MODO%"=="vista" (
    for %%a in (%ALGS%) do call :con_vista %%a
) else (
    echo   Algoritmo               Pasos del camino   Casillas exploradas
    echo   ---------------------   ----------------   -------------------
    for %%a in (%ALGS%) do call :sin_vista %%a
    echo.
    echo   Pasos del camino    = largo del camino que encontro.  Menos es mejor.
    echo   Casillas exploradas = cuanto tuvo que buscar.         Menos es mas eficiente.
)
echo.
pause
goto :menu


:con_vista
call :nombre %1
echo   ^>^> %NOMBRE% en %LAB%: primero se pintan de rojo las casillas exploradas
echo      y despues Pacman recorre el camino. La ventana se cierra sola al ganar.
call :correr
if defined COSTO (
    echo      Resultado: camino de %COSTO% pasos, exploro %NODOS% casillas.
) else (
    echo      El juego se cerro antes de terminar.
)
echo.
exit /b 0

:sin_vista
call :nombre %1
call :correr -q
set "c1=!NOMBRE!                         "
set "c2=!COSTO!                  "
echo   !c1:~0,21!   !c2:~0,16!   !NODOS!
exit /b 0

:correr
rem Corre pacman.py y guarda el largo del camino (COSTO) y las casillas exploradas (NODOS)
set "COSTO="
set "NODOS="
for /f "tokens=1-7" %%a in ('%PYTHON% pacman.py -l %LAB% -p SearchAgent -a "!ARG!" %* 2^>nul') do (
    if "%%a"=="Path" set "COSTO=%%g"
    if "%%a"=="Search" set "NODOS=%%d"
)
exit /b 0

:nombre
set "NOMBRE="
set "ARG="
if "%1"=="dfs"   set "NOMBRE=Profundidad (DFS)"    & set "ARG=fn=dfs"
if "%1"=="bfs"   set "NOMBRE=Anchura (BFS)"        & set "ARG=fn=bfs"
if "%1"=="ucs"   set "NOMBRE=Costo uniforme (UCS)" & set "ARG=fn=ucs"
if "%1"=="astar" set "NOMBRE=A* (Manhattan)"       & set "ARG=fn=astar,heuristic=manhattanHeuristic"
exit /b 0
