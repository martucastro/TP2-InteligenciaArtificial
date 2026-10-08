# TP 2 – Búsqueda (Pacman)
Inteligencia Artificial · UADE · Docente: Christian Parkinson

Implementación de 4 algoritmos de búsqueda para que Pacman encuentre el camino a la meta dentro de un laberinto. Se trabajó sobre el juego de Pacman que provee la cátedra (adaptado por Nelson Ponzoni).

![Pacman resolviendo un laberinto](docs/img/pacman_game.gif)

- Enunciado: [`docs/enunciado-TP2-Busqueda.pdf`](docs/enunciado-TP2-Busqueda.pdf)
- Explicación completa del código (archivos, clases, cadena de llamadas, cada algoritmo paso a paso): [`EXPLICACION.md`](EXPLICACION.md)

## Qué pide la consigna

1. **Completar el código de los 4 algoritmos:** búsqueda en profundidad, en anchura, de costo uniforme y A\*.
2. **Presentar el código funcionando.**

Cada integrante tiene que poder justificar las respuestas.

## Qué se implementó

Todo el trabajo está en **`search.py`**. El resto de los archivos es el juego que provee la cátedra.

| Función | Algoritmo | Frontera (de dónde saca el próximo estado) | ¿Camino óptimo? |
|---|---|---|---|
| `depthFirstSearch` | Profundidad (DFS) | Pila: sale el último que entró | No |
| `breadthFirstSearch` | Anchura (BFS) | Cola: sale el primero que entró | Sí, si todos los pasos cuestan igual |
| `uniformCostSearch` | Costo uniforme (UCS) | Cola de prioridad por costo acumulado | Sí |
| `aStarSearch` | A\* | Cola de prioridad por costo acumulado + heurística | Sí, con heurística admisible |

Los 4 hacen lo mismo: sacan un estado de la frontera, se fijan si es la meta y, si no, agregan sus vecinos. **Lo único que cambia es la frontera.**

## Resultados (todos ganan)

Costo del camino / nodos expandidos:

| Laberinto | DFS | BFS | UCS | A\* (Manhattan) |
|---|---|---|---|---|
| `tp2Maze` | 17 / 22 | 15 / 23 | 15 / 23 | 15 / **19** |
| `mediumMaze` | 130 / 146 | 68 / 269 | 68 / 269 | 68 / **221** |

DFS encuentra caminos más largos. BFS y UCS dan lo mismo porque todos los pasos cuestan 1. A\* encuentra el mismo camino óptimo que BFS y UCS, pero explorando menos casillas.

---

## Instalación

**Requisito:** Python 3.8 o superior ([python.org](https://www.python.org/downloads/)).

El proyecto usa solo la biblioteca estándar de Python, así que **no hay paquetes para instalar**. La ventana del juego usa `tkinter`, que viene con Python en Windows y macOS. En Linux puede hacer falta instalarlo aparte: `sudo apt install python3-tk`.

Igual recomendamos usar un entorno virtual, que es lo prolijo.

### Windows (cmd)
```bat
git clone https://github.com/martucastro/TP2-InteligenciaArtificial.git
cd TP2-InteligenciaArtificial
python -m venv .venv
.venv\Scripts\activate
```

### Windows (PowerShell)
```powershell
git clone https://github.com/martucastro/TP2-InteligenciaArtificial.git
cd TP2-InteligenciaArtificial
python -m venv .venv
.venv\Scripts\Activate.ps1
```
Si PowerShell no deja activar el entorno ("la ejecución de scripts está deshabilitada"), corré una vez `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

### Linux / macOS
```bash
git clone https://github.com/martucastro/TP2-InteligenciaArtificial.git
cd TP2-InteligenciaArtificial
python3 -m venv .venv
source .venv/bin/activate
```

Para salir del entorno virtual: `deactivate`.

> Si en Windows `python` no anda, probá con `py`, que es el lanzador que instala Python.

---

## Cómo correrlo

Hay dos maneras: con el menú de `jugar.bat` (Windows) o escribiendo el comando a mano. Las dos hacen lo mismo y cada una se puede correr **con vista** (ventana del juego) o **sin vista** (solo los números).

### Opción A: con `jugar.bat` (Windows)

Doble clic en **`jugar.bat`**, o escribir `jugar` en `cmd` desde la carpeta del proyecto. Si existe el entorno virtual `.venv` lo usa solo; si no, busca Python instalado (`py`, `python` o `python3`).

```
1) Con vista   (se abre la ventana del juego)
2) Sin vista   (solo los resultados, al instante)
3) Salir
```

Después pregunta el algoritmo (DFS, BFS, UCS, A\* o los 4) y el laberinto. Sin vista y con "los 4", arma una tabla comparativa:

```
Algoritmo               Pasos del camino   Casillas exploradas
Profundidad (DFS)       130                146
Anchura (BFS)           68                 269
Costo uniforme (UCS)    68                 269
A* (Manhattan)          68                 221
```

### Opción B: a mano

Desde la carpeta del proyecto (con el entorno virtual activado, si lo usás). La estructura del comando es siempre la misma:

```
python pacman.py -l <laberinto> -p SearchAgent -a fn=<algoritmo>
```

| Parámetro | Qué es | Valores |
|---|---|---|
| `-l` | Laberinto | `tp2Maze` (chico, para explicar) o `mediumMaze` (mediano, para comparar) |
| `-p` | Quién controla a Pacman | `SearchAgent` (el que usa nuestros algoritmos) |
| `-a fn=` | Algoritmo | `dfs`, `bfs`, `ucs`, `astar` |
| `-a fn=astar,heuristic=` | Heurística de A\* | `manhattanHeuristic` (si no se pone, usa `nullHeuristic`, que siempre da 0 y hace que A\* se comporte como UCS) |

**Con vista.** Se abre una ventana. Primero se pintan de **rojo** las casillas que exploró el algoritmo, y después Pacman recorre el camino que encontró.

```bash
python pacman.py -l tp2Maze -p SearchAgent -a fn=dfs
python pacman.py -l tp2Maze -p SearchAgent -a fn=bfs
python pacman.py -l tp2Maze -p SearchAgent -a fn=ucs
python pacman.py -l tp2Maze -p SearchAgent -a fn=astar,heuristic=manhattanHeuristic
```

**Sin vista.** El mismo comando con `-q` al final. No se abre ventana: imprime el resultado al instante.

```bash
python pacman.py -l mediumMaze -p SearchAgent -a fn=bfs -q
```
```
Path found with total cost of 68 in 0.0 seconds     <- largo del camino
Search nodes expanded: 269                          <- casillas exploradas
Record:        Win
```

**Para la defensa:** mostrar `tp2Maze` con vista, donde se ve la diferencia en el rojo, y después los 4 sin vista para explicarla con números.

---

## Estructura del proyecto

```
search.py            <- LO NUESTRO: los 4 algoritmos
EXPLICACION.md       <- guía completa para entender y defender el TP
README.md            <- este archivo
jugar.bat            <- menú para correrlo en Windows

pacman.py            <- arranca el juego (el que se ejecuta)
searchAgents.py      <- SearchAgent: arma el problema y llama a nuestras funciones de búsqueda
game.py              <- motor del juego: agentes, direcciones, bucle de turnos
util.py              <- estructuras de datos: Stack, Queue, PriorityQueue
layout.py            <- lee los mapas
ghostAgents.py       <- fantasmas (el motor los necesita, pero nuestros laberintos no tienen)
graphicsDisplay.py, graphicsUtils.py <- la ventana del juego
textDisplay.py       <- la "pantalla vacía" que se usa con -q
layouts/             <- los 2 laberintos: tp2Maze (chico, lo armamos para explicar) y mediumMaze
docs/                <- enunciado e imágenes
```

Todos los `.py` tienen que quedar en la misma carpeta, porque `pacman.py` los importa por nombre.

## Integrantes
- Martina Toffoletto
- Agustin Buset
- Elias Gantus
- Martina Castro
