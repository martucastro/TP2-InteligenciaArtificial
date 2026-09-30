# TP 2 – Búsqueda (Pacman)
Inteligencia Artificial · UADE · Docente: Christian Parkinson

Implementación de 4 algoritmos de búsqueda para que Pacman encuentre el camino a la meta dentro de un laberinto, sobre el proyecto de Pacman AI de la Universidad de Berkeley (adaptado por Nelson Ponzoni para la cátedra).

##Estado
Las 4 funciones están implementadas en `search.py` y probadas corriendo Pacman en varios laberintos (`tinyMaze`, `mediumMaze`, `openMaze`, `mediumDottedMaze`), ganando en todos los casos.

## Qué se implementó
En `search.py`:
- `depthFirstSearch` — búsqueda en **profundidad** (usa una pila)
- `breadthFirstSearch` — búsqueda en **anchura** (usa una cola)
- `uniformCostSearch` — búsqueda de **costo uniforme** (usa una cola de prioridad por costo acumulado)
- `aStarSearch` — búsqueda **A\*** (cola de prioridad por costo acumulado + heurística)

Los 4 comparten la misma lógica: van sacando estados de una "frontera" (la lista de pendientes), y lo único que cambia entre uno y otro es el orden en que se saca el próximo. Marcan los estados ya visitados para no repetir caminos.

> Aclaración: el enunciado del TP llama "búsqueda informada" a los 4 algoritmos, pero en rigor solo A\* lo es (porque usa una heurística). Profundidad, anchura y costo uniforme son búsquedas no informadas.

## Cómo correrlo
Requiere Python 3. Desde esta carpeta:
```bash
python pacman.py -l tinyMaze -p SearchAgent -a fn=dfs
python pacman.py -l mediumMaze -p SearchAgent -a fn=bfs
python pacman.py -l mediumMaze -p SearchAgent -a fn=ucs
python pacman.py -l openMaze -p SearchAgent -a fn=astar,heuristic=manhattanHeuristic
```
Agregando `-q` al final corre en modo texto (rápido, sin ventana); sin `-q` se abre el juego para ver a Pacman moverse.

## Estructura del proyecto
```
search.py          <- acá está lo implementado (las 4 funciones)
searchAgents.py     <- agentes que usan las funciones de búsqueda
pacman.py           <- ejecuta el juego
game.py, util.py    <- infraestructura del proyecto (no se modifica)
layouts/            <- los mapas de los laberintos (.lay)
```

## Integrantes
- Martina Toffoletto
- Agustin Buset
- Elias Gantus
- Martina Castro
