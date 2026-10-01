# Explicación del TP 2 – Búsqueda

Guía para entender el código y poder defenderlo. Todo lo que escribimos está en `search.py`.

---

## 0. Qué hace cada archivo

Son muchos archivos, pero **solo escribimos uno**. El resto es el juego de Pacman que da la cátedra. Para entenderlos, conviene pensarlos en 4 capas:

```
          ┌──────────────────────────┐
  CAPA 1  │ search.py                │  <- LO NUESTRO: los 4 algoritmos
          └────────────▲─────────────┘
                       │ llama a nuestras funciones
          ┌────────────┴─────────────┐
  CAPA 2  │ searchAgents.py          │  <- arma el problema y le pide el camino a search.py
          └────────────▲─────────────┘
                       │ el juego le pregunta "¿qué hago?"
          ┌────────────┴─────────────┐
  CAPA 3  │ pacman.py  game.py       │  <- el motor: reglas, turnos, mapas
          │ layout.py  util.py       │
          │ *Agents.py               │
          └────────────▲─────────────┘
                       │ dibuja cada turno
          ┌────────────┴─────────────┐
  CAPA 4  │ graphicsDisplay.py ...   │  <- la pantalla
          └──────────────────────────┘
```

### Capa 1 – Lo nuestro

| Archivo | Qué hace |
|---|---|
| **`search.py`** | Tiene los 4 algoritmos que implementamos: `depthFirstSearch`, `breadthFirstSearch`, `uniformCostSearch` y `aStarSearch`. Al final define los atajos `dfs`, `bfs`, `ucs` y `astar`, que son los nombres que se usan en la consola (`-a fn=bfs`). **Es lo único que modificamos.** |

### Capa 2 – El puente entre el juego y nuestros algoritmos

| Archivo | Qué hace |
|---|---|
| **`searchAgents.py`** | Define **`SearchAgent`**, el Pacman "inteligente". Al arrancar la partida arma el problema (`PositionSearchProblem`: dónde está Pacman, dónde está la meta, qué movimientos hay), llama a nuestra función de `search.py` y guarda la lista de acciones que le devolvemos. Después, en cada turno, ejecuta la siguiente acción. Acá también están `manhattanHeuristic` (la heurística de A\*) y los agentes `StayEastSearchAgent`/`StayWestSearchAgent`. El archivo tiene otras partes (esquinas, comida) que esta consigna no pide. |

### Capa 3 – El motor del juego

| Archivo | Qué hace |
|---|---|
| **`pacman.py`** | **El que se ejecuta.** Lee los parámetros de la consola (`-l` laberinto, `-p` agente, `-a` argumentos, `-q` sin ventana), carga el mapa, crea a Pacman y los fantasmas, y arranca la partida. También tiene las reglas propias de Pacman: comer puntos, ganar, perder. |
| **`game.py`** | Las piezas genéricas del juego: las direcciones (`North`, `South`...), cómo se mueve un agente, la grilla y el bucle de turnos (`Game.run`), que le pregunta a cada agente qué quiere hacer. |
| **`util.py`** | Herramientas. Las que usamos nosotros: **`Stack`** (pila, para DFS), **`Queue`** (cola, para BFS) y **`PriorityQueue`** (cola de prioridad, para UCS y A\*). También tiene `manhattanDistance`. |
| **`layout.py`** | Lee los mapas `.lay` de la carpeta `layouts/` y los convierte en una grilla: dónde hay paredes (`%`), comida (`.`), Pacman (`P`) y fantasmas (`G`). |
| **`layouts/`** | Los laberintos en texto. `tp2Maze.lay` es el chico que agregamos de ejemplo. |
| `pacmanAgents.py` | Pacmans simples que vienen de ejemplo (por ejemplo, uno que elige movimientos al azar). No los usamos. |
| `ghostAgents.py` | Cómo se mueven los fantasmas: al azar o persiguiendo a Pacman. Solo importa en los mapas con fantasmas. |
| `keyboardAgents.py` | Permite jugar con el teclado. Es lo que se usa si corrés `python pacman.py` sin `-p`. |

### Capa 4 – La pantalla

| Archivo | Qué hace |
|---|---|
| `graphicsDisplay.py` | Dibuja el juego en una ventana: laberinto, Pacman, fantasmas y las casillas que exploró el algoritmo (pintadas en rojo, más fuerte las primeras). |
| `graphicsUtils.py` | Funciones básicas de dibujo (círculos, líneas, colores) sobre Tkinter. Las usa `graphicsDisplay.py`. |
| `textDisplay.py` | La "pantalla" sin ventana, la que se usa con `-q`. |

### Otros

| Archivo | Qué hace |
|---|---|
| `README.md` | Presentación del TP. |
| `EXPLICACION.md` | Esta guía. |
| `jugar.bat` | Script para correr el juego sin acordarse los parámetros. Abre un menú: ver el juego o comparar los 4 algoritmos. |
| `commands.txt` | Comandos listos para copiar y probar. |
| `docs/` | El enunciado (PDF) y las imágenes del README. |
| `.gitignore` | Le dice a git que ignore `__pycache__/`. |
| `__pycache__/` | Python la crea solo al correr el juego (versiones compiladas). Se puede borrar sin problema. |

### Qué pasa cuando corremos un comando

`python pacman.py -l tp2Maze -p SearchAgent -a fn=bfs`

1. `pacman.py` lee los parámetros y `layout.py` carga `layouts/tp2Maze.lay`.
2. `pacman.py` crea un `SearchAgent` (de `searchAgents.py`) y le pasa `fn=bfs`.
3. `SearchAgent` arma el problema y llama a `bfs` en `search.py`, **nuestro código**.
4. Nuestra función devuelve la lista de acciones, por ejemplo `['West', 'West', 'South', ...]`.
5. `game.py` corre los turnos: en cada uno, `SearchAgent` entrega la siguiente acción.
6. `graphicsDisplay.py` lo dibuja (o `textDisplay.py` si pusimos `-q`).
7. Pacman llega a la meta, come el punto y gana. Se imprime el costo y los nodos expandidos.

### Qué se ve al correrlo

Doble clic en `jugar.bat` y aparece un menú con dos opciones.

**Opción 1 – Ver el juego (lo principal)**

Elegís un algoritmo y un laberinto, y se abre la ventana del juego:
1. Antes de que Pacman se mueva, el algoritmo **ya buscó el camino entero**. Las casillas que **exploró** quedan pintadas de **rojo**: más fuerte las primeras que miró, más suave las últimas.
2. Después Pacman **recorre** ese camino hasta el punto de la meta, se lo come y gana. La ventana se cierra sola.
3. En la consola queda el resumen, por ejemplo: `Resultado: camino de 68 pasos, exploro 221 casillas.`

Lo interesante es **comparar el rojo** entre algoritmos en el mismo laberinto. La opción "Los 4, uno atrás del otro" los muestra seguidos:
- **DFS:** poco rojo, pero Pacman da una vuelta larga. Exploró poco y encontró un camino malo.
- **BFS / UCS:** mucho rojo, que se expande parejo en todas direcciones. Encuentra el camino más corto, pero mira casi todo.
- **A\*:** menos rojo que BFS, concentrado hacia la meta. El mismo camino corto, mirando menos.

**Opción 2 – Comparar algoritmos (los mismos datos, en números)**

No abre ventanas. Corre los 4 algoritmos en el laberinto que elijas y muestra una tabla:
```
Algoritmo               Pasos del camino   Casillas exploradas
Profundidad (DFS)       130                146     <- camino largo (no es óptimo)
Anchura (BFS)           68                 269     <- camino óptimo, mucho trabajo
Costo uniforme (UCS)    68                 269     <- igual que BFS porque todos los pasos cuestan 1
A* (Manhattan)          68                 221     <- camino óptimo, menos trabajo gracias a la heurística
```
- **Pasos del camino** (en inglés el juego lo llama *total cost*): qué tan bueno es el camino. **Menos es mejor.**
- **Casillas exploradas** (*nodes expanded*): cuánto tuvo que buscar. Es el rojo de la ventana, contado. **Menos es más eficiente.**

En la defensa: mostrá el juego (opción 1) para que se **vea** la diferencia, y la tabla (opción 2) para **explicarla** con números.

---

## 1. El problema

Pacman está en un laberinto y tiene que llegar a una meta (el punto de comida en la casilla `(1,1)`, abajo a la izquierda).

- **Estado:** la posición de Pacman, `(x, y)`.
- **Acciones:** moverse `North`, `South`, `East` o `West`, si no hay pared.
- **Meta:** llegar a `(1,1)`.
- **Costo:** cada paso cuesta 1 (salvo en los agentes `StayEast`/`StayWest`, ver punto 5).
- **Solución:** una **lista de acciones**, por ejemplo `['West', 'West', 'South', ...]`, que Pacman ejecuta una por una.

El juego nos da el problema ya armado (`problem`) con 3 métodos:

| Método | Qué devuelve |
|---|---|
| `problem.getStartState()` | La posición inicial de Pacman |
| `problem.isGoalState(estado)` | `True` si ese estado es la meta |
| `problem.getSuccessors(estado)` | Lista de vecinos: `(sucesor, acción, costo)` |

---

## 2. La idea común a los 4 algoritmos

Los 4 algoritmos son **el mismo bucle**. Lo único que cambia es la **frontera**, es decir, la lista de caminos pendientes por explorar, y en qué orden se sacan.

```
frontera  = [ (inicio, camino vacío) ]
visitados = conjunto vacío

mientras la frontera no esté vacía:
    sacar un (estado, camino) de la frontera     <- ACÁ cambia cada algoritmo
    si estado es la meta: devolver camino        <- terminamos
    si estado ya fue visitado: saltearlo
    marcar estado como visitado
    para cada vecino (sucesor, acción, costo):
        si no fue visitado: agregar (sucesor, camino + [acción]) a la frontera

si se vació la frontera: no hay solución -> devolver []
```

Dos cosas que conviene saber explicar:
- **Cada elemento de la frontera guarda su camino.** Así, cuando encontramos la meta, ya tenemos la lista de acciones lista para devolver.
- **`visitados`** evita volver a expandir una casilla y quedar dando vueltas en círculos. Esto se llama *búsqueda en grafo*.

---

## 3. Los 4 algoritmos

### Profundidad – DFS (`depthFirstSearch`)
- **Frontera:** `util.Stack()`, una **pila**. Sale el **último** que entró.
- **Comportamiento:** sigue un camino hasta el fondo y, recién cuando se traba, vuelve atrás y prueba otro.
- **¿Encuentra el camino más corto?** **No.** Encuentra *un* camino, el primero que le aparece.
- **En los resultados:** en `mediumMaze` da costo **130**, mientras los otros dan **68**.

### Anchura – BFS (`breadthFirstSearch`)
- **Frontera:** `util.Queue()`, una **cola**. Sale el **primero** que entró.
- **Comportamiento:** explora por niveles: primero todo lo que está a 1 paso, después a 2 pasos, etc.
- **¿Encuentra el camino más corto?** **Sí**, siempre que todos los pasos cuesten lo mismo.
- **Contra:** expande muchos nodos (269 en `mediumMaze`).

### Costo uniforme – UCS (`uniformCostSearch`)
- **Frontera:** `util.PriorityQueue()`, una **cola de prioridad** ordenada por el **costo acumulado** del camino.
- **Comportamiento:** siempre expande el camino **más barato hasta ahora**.
- **¿Encuentra el camino óptimo?** **Sí**, incluso si los pasos cuestan distinto.
- Cada elemento guarda también su costo acumulado: `(estado, camino, costo_acum)`.
- Si todos los pasos cuestan 1, se comporta igual que BFS (misma tabla de resultados).

### A\* (`aStarSearch`)
- **Frontera:** cola de prioridad ordenada por **`costo_acumulado + heurística`**.
  - `costo_acumulado` (g): lo que ya caminé.
  - `heurística` (h): una **estimación** de lo que me falta para llegar.
- **Heurística usada:** **distancia Manhattan**, `|x1 - x2| + |y1 - y2|`. Es lo que caminaría Pacman si no hubiera paredes.
- **¿Encuentra el camino óptimo?** **Sí**, porque Manhattan **nunca sobreestima**: con paredes el camino real solo puede ser igual o más largo. A eso se le dice heurística **admisible**.
- **Ventaja:** encuentra el mismo camino óptimo que UCS pero **expandiendo menos nodos**, porque prioriza ir "hacia la meta". En `mediumMaze` expande 221 contra 269.
- Con `nullHeuristic` (h = 0), A\* es exactamente UCS.

### Resumen

| | Frontera | Óptimo | Usa heurística |
|---|---|---|---|
| DFS | Pila | No | No |
| BFS | Cola | Sí (costos iguales) | No |
| UCS | Prioridad por costo | Sí | No |
| A\* | Prioridad por costo + heurística | Sí (heurística admisible) | **Sí** |

> El enunciado dice "búsqueda informada" para los 4, pero en rigor **solo A\* es informada** (usa heurística). DFS, BFS y UCS son **no informadas**.

---

## 4. El laberinto de ejemplo: `tp2Maze`

Es un laberinto chico (está en `layouts/tp2Maze.lay`) para mostrar las diferencias a simple vista:

```
%%%%%%
%   P%     P = Pacman (inicio)
% %%%%     . = meta
%   %%     % = pared
% % %%
% %  %
% %% %
%    %
%%% %%
%.   %
%%%%%%
```

| | Costo del camino | Nodos expandidos |
|---|---|---|
| DFS | 17 | 22 |
| BFS | 15 | 23 |
| UCS | 15 | 23 |
| A\* | 15 | **19** |

DFS toma un desvío (17 pasos). BFS, UCS y A\* encuentran el más corto (15), y A\* lo hace mirando menos casillas.

```bash
python pacman.py -l tp2Maze -p SearchAgent -a fn=dfs
python pacman.py -l tp2Maze -p SearchAgent -a fn=astar,heuristic=manhattanHeuristic
```

---

## 5. Costos distintos: por qué existe UCS

Los agentes `StayEastSearchAgent` y `StayWestSearchAgent` usan UCS con costos que **dependen de la columna**:
- `StayEast`: cada paso cuesta `0.5 ** x`, así que el lado derecho (x grande) es casi gratis.
- `StayWest`: cada paso cuesta `2 ** x`, así que el lado derecho es carísimo.

BFS solo cuenta pasos y no ve estos costos. UCS sí, y elige el camino más barato aunque sea más largo.

```bash
python pacman.py -l mediumDottedMaze -p StayEastSearchAgent
python pacman.py -l mediumScaryMaze -p StayWestSearchAgent
```

---

## 6. Preguntas probables

**¿Qué diferencia hay entre los 4 algoritmos en el código?**
Solo la estructura de la frontera (pila, cola, prioridad por costo, prioridad por costo + heurística). El resto del bucle es igual.

**¿Por qué DFS no da el camino más corto?**
Porque se mete por el primer camino que encuentra hasta el fondo, sin comparar longitudes.

**¿Por qué BFS y UCS dan exactamente los mismos resultados?**
Porque en estos laberintos todos los pasos cuestan 1. Ordenar por costo acumulado es lo mismo que ordenar por cantidad de pasos.

**¿Qué es una heurística? ¿Por qué Manhattan?**
Es una estimación de cuánto falta para la meta. Manhattan es la distancia sin paredes. Nunca sobreestima (es admisible), así que A\* sigue encontrando el óptimo.

**¿Por qué A\* expande menos nodos?**
Porque entre dos caminos igual de baratos prefiere el que está más cerca de la meta, y no pierde tiempo explorando hacia el lado contrario.

**¿Para qué sirve `visitados`?**
Para no expandir dos veces la misma casilla. Sin eso, el algoritmo podría ir y volver entre dos casillas para siempre.

**¿Por qué se marca visitado al *sacar* de la frontera y no al *meter*?**
En UCS y A\* puede aparecer más tarde un camino más barato a una casilla que ya está en la frontera. Si la marcáramos al meterla, ese camino mejor se descartaría y podríamos perder el óptimo. Al marcarla cuando sale, garantizamos que la primera vez que se expande es por el camino más barato.

**¿Qué devuelve la función si no hay solución?**
Una lista vacía `[]`.

**¿Qué archivos modificaron?**
Solo `search.py`. El resto es el juego que provee la cátedra.
