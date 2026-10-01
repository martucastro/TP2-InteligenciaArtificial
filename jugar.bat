@echo off
rem Corre Pacman con nuestros algoritmos de busqueda.
rem
rem   jugar                   -> menu (o doble clic en el archivo)
rem   jugar bfs mediumMaze    -> abre el juego directo con BFS en mediumMaze
rem
rem Algoritmos: dfs, bfs, ucs, astar
rem Laberintos: los archivos de layouts\ (sin .lay)

setlocal enabledelayedexpansion
cd /d "%~dp0"

rem Busca con que comando esta instalado Python
set "PYTHON="
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

rem Con argumentos: abre el juego directo, sin menu
if not "%~1"=="" (
    set "LAB=%~2"
    if "!LAB!"=="" set "LAB=tp2Maze"
    if not exist "layouts\!LAB!.lay" (
        echo No existe el laberinto "!LAB!".
        goto :eof
    )
    call :visual %~1
    goto :eof
)


rem ================== MENU PRINCIPAL ==================
:menu
cls
echo.
echo   ==============================================
echo     TP2 - Busqueda en Pacman
echo   ==============================================
echo.
echo    1) Ver el juego          (Pacman moviendose en una ventana)
echo    2) Comparar algoritmos   (tabla con los numeros de los 4)
echo    3) Salir
echo.
set "op="
set /p "op=  Elegi una opcion: "
if "%op%"=="1" goto :opcion_ver
if "%op%"=="2" goto :opcion_comparar
if "%op%"=="3" goto :eof
goto :menu


rem ================== 1) VER EL JUEGO ==================
:opcion_ver
call :elegir_algoritmo
if errorlevel 1 goto :menu
call :elegir_laberinto
if errorlevel 1 goto :menu
if "%ALG%"=="todos" (
    for %%a in (dfs bfs ucs astar) do call :visual %%a
) else (
    call :visual %ALG%
)
echo.
pause
goto :menu


rem ================== 2) COMPARAR ==================
:opcion_comparar
call :elegir_laberinto
if errorlevel 1 goto :menu
echo.
echo   Corriendo los 4 algoritmos en %LAB% (sin ventana)...
echo.
echo   Algoritmo               Pasos del camino   Casillas exploradas
echo   ---------------------   ----------------   -------------------
for %%a in (dfs bfs ucs astar) do (
    call :correr %%a -q
    set "c1=!NOMBRE!                         "
    set "c2=!COSTO!                  "
    echo   !c1:~0,21!   !c2:~0,16!   !NODOS!
)
echo.
echo   Pasos del camino    = que tan largo es el camino que encontro.  Menos es mejor.
echo   Casillas exploradas = cuanto tuvo que buscar para encontrarlo.  Menos es mas eficiente.
echo.
pause
goto :menu


rem ================== subrutinas ==================

:elegir_algoritmo
echo.
echo   Algoritmo:
echo    1) Profundidad (DFS)
echo    2) Anchura (BFS)
echo    3) Costo uniforme (UCS)
echo    4) A* (con heuristica Manhattan)
echo    5) Los 4, uno atras del otro
set "op="
set "ALG="
set /p "op=  Elegi una opcion: "
if "%op%"=="1" set "ALG=dfs"
if "%op%"=="2" set "ALG=bfs"
if "%op%"=="3" set "ALG=ucs"
if "%op%"=="4" set "ALG=astar"
if "%op%"=="5" set "ALG=todos"
if "%ALG%"=="" exit /b 1
exit /b 0

:elegir_laberinto
echo.
echo   Laberinto:
echo    1) tp2Maze      (chico, ideal para explicar)
echo    2) tinyMaze     (muy chico)
echo    3) mediumMaze   (mediano)
echo    4) openMaze     (grande y abierto, donde mas se nota A*)
set "op="
set "LAB="
set /p "op=  Elegi una opcion: "
if "%op%"=="1" set "LAB=tp2Maze"
if "%op%"=="2" set "LAB=tinyMaze"
if "%op%"=="3" set "LAB=mediumMaze"
if "%op%"=="4" set "LAB=openMaze"
if "%LAB%"=="" exit /b 1
exit /b 0

:visual
rem Abre el juego con ventana y al final muestra el resultado
call :nombre %1
if not defined NOMBRE (
    echo Algoritmo invalido: "%1". Opciones: dfs, bfs, ucs, astar
    exit /b 1
)
echo.
echo   ^>^> %NOMBRE% en %LAB%
echo      Primero el algoritmo busca el camino: las casillas que explora se pintan de rojo.
echo      Despues Pacman recorre el camino hasta la meta. La ventana se cierra sola al ganar.
call :correr %1
if defined COSTO (
    echo      Resultado: camino de %COSTO% pasos, exploro %NODOS% casillas.
) else (
    echo      El juego se cerro antes de terminar.
)
exit /b 0

:correr
rem Corre pacman.py y guarda COSTO y NODOS. Con -q como segundo parametro, sin ventana.
call :nombre %1
set "COSTO="
set "NODOS="
for /f "tokens=1-7" %%a in ('%PYTHON% pacman.py -l %LAB% -p SearchAgent -a "!ARG!" %2 2^>nul') do (
    if "%%a"=="Path" set "COSTO=%%g"
    if "%%a"=="Search" set "NODOS=%%d"
)
exit /b 0

:nombre
rem Traduce el nombre corto al nombre completo y al argumento que espera pacman.py
set "NOMBRE="
set "ARG="
if /i "%1"=="dfs"   set "NOMBRE=Profundidad (DFS)"    & set "ARG=fn=dfs"
if /i "%1"=="bfs"   set "NOMBRE=Anchura (BFS)"        & set "ARG=fn=bfs"
if /i "%1"=="ucs"   set "NOMBRE=Costo uniforme (UCS)" & set "ARG=fn=ucs"
if /i "%1"=="astar" set "NOMBRE=A* (Manhattan)"       & set "ARG=fn=astar,heuristic=manhattanHeuristic"
exit /b 0
