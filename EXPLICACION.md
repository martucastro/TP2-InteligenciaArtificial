# Explicación del TP 2 – Búsqueda

Guía para entender el código de punta a punta y poder defenderlo: qué hace cada archivo, qué clases y funciones tiene, cómo se llaman entre sí y cómo funciona cada algoritmo.

**Lo que implementamos nosotros está en `search.py`** (los 4 algoritmos). El resto es el juego de Pacman que da la cátedra.

## Índice

1. [El mapa general](#1-el-mapa-general)
2. [Qué pasa cuando corremos un comando (la cadena de llamadas)](#2-qué-pasa-cuando-corremos-un-comando)
3. [Archivo por archivo](#3-archivo-por-archivo)
4. [El problema de búsqueda](#4-el-problema-de-búsqueda)
5. [Las estructuras de datos: pila, cola y cola de prioridad](#5-las-estructuras-de-datos)
6. [El esqueleto común a los 4 algoritmos](#6-el-esqueleto-común-a-los-4-algoritmos)
7. [Los 4 algoritmos en detalle](#7-los-4-algoritmos-en-detalle)
8. [Heurísticas](#8-heurísticas)
9. [Resultados](#9-resultados)
10. [Costos distintos: por qué existe UCS](#10-costos-distintos-por-qué-existe-ucs)
11. [Qué se ve al correrlo](#qué-se-ve-al-correrlo)
12. [Lo que sacamos del código base](#12-lo-que-sacamos-del-código-base)
13. [Preguntas probables](#13-preguntas-probables)

---

## 1. El mapa general

Conviene pensar el proyecto en 4 capas. Cada una solo habla con la de al lado:

```
          ┌──────────────────────────┐
  CAPA 1  │ search.py                │  <- LO NUESTRO: los 4 algoritmos
          └────────────▲─────────────┘
                       │ SearchAgent llama a dfs / bfs / ucs / astar
          ┌────────────┴─────────────┐
  CAPA 2  │ searchAgents.py          │  <- arma el problema y le pide el camino a search.py
          └────────────▲─────────────┘
                       │ el juego le pregunta al agente "¿qué hacés?"
          ┌────────────┴─────────────┐
  CAPA 3  │ pacman.py   game.py      │  <- el motor: reglas, turnos, mapas
          │ layout.py   util.py      │
          │ *Agents.py               │
          └────────────▲─────────────┘
                       │ dibuja cada turno
          ┌────────────┴─────────────┐
  CAPA 4  │ graphicsDisplay.py       │  <- la pantalla
          │ graphicsUtils.py         │
          │ textDisplay.py           │
          └──────────────────────────┘
```

La idea clave: **nuestros algoritmos no saben nada de Pacman**. Solo reciben un objeto `problem` con 3 métodos (dónde arranco, si llegué, a dónde puedo ir). Por eso el mismo código serviría para cualquier otro problema de búsqueda, como un puzzle o un GPS.

---

## 2. Qué pasa cuando corremos un comando

Ejemplo:

```bash
python pacman.py -l tp2Maze -p SearchAgent -a fn=astar,heuristic=manhattanHeuristic
```

Esta es la cadena de llamadas real, en orden:

```
pacman.py  (bloque if __name__ == '__main__')
│
├─ readCommand(sys.argv)                       lee los parámetros de la consola
│   ├─ layout.getLayout('tp2Maze')             carga layouts/tp2Maze.lay -> objeto Layout
│   ├─ loadAgent('SearchAgent', ...)           busca la clase SearchAgent en los *Agents.py
│   ├─ parseAgentArgs('fn=astar,heuristic=...')   -> {'fn': 'astar', 'heuristic': 'manhattanHeuristic'}
│   └─ SearchAgent(fn='astar', heuristic='manhattanHeuristic')
│        └─ busca search.astar y searchAgents.manhattanHeuristic, y los guarda
│
└─ runGames(...)
    └─ ClassicGameRules.newGame(...)           crea el GameState inicial y el objeto Game
        └─ Game.run()
            │
            ├─ SearchAgent.registerInitialState(estado)       <- ACÁ SE BUSCA EL CAMINO
            │   ├─ problem = PositionSearchProblem(estado)
            │   ├─ self.actions = search.aStarSearch(problem, heuristic=manhattanHeuristic)
            │   │     └─ llama muchas veces a problem.getStartState / isGoalState / getSuccessors
            │   │        (cuando encuentra la meta, se pintan de rojo las casillas exploradas)
            │   └─ imprime "Path found with total cost of 15" y "Search nodes expanded: 19"
            │
            └─ bucle de turnos, hasta que termine el juego:
                ├─ SearchAgent.getAction(estado)     devuelve la siguiente acción de self.actions
                ├─ estado.generateSuccessor(...)      mueve a Pacman y come la comida
                ├─ display.update(...)                redibuja la pantalla
                └─ ClassicGameRules.process(...)      ¿ganó? ¿perdió?
```

Dos cosas importantes para la defensa:

- **Toda la búsqueda pasa una sola vez, antes de que Pacman se mueva**, en `registerInitialState`. Después Pacman solo ejecuta la lista de acciones, una por turno, sin volver a pensar.
- El puntaje final en `tp2Maze` es **495**: +10 por la comida, +500 por ganar y −1 por cada uno de los 15 pasos.

---

## 3. Archivo por archivo

### `search.py` – **lo nuestro**

| Elemento | Tipo | Qué hace |
|---|---|---|
| `SearchProblem` | clase abstracta | Define la "forma" de cualquier problema de búsqueda: `getStartState`, `isGoalState`, `getSuccessors`, `getCostOfActions`. Acá no hacen nada (llaman a `util.raiseNotDefined()`), porque cada problema concreto los implementa. |
| `depthFirstSearch(problem)` | función | **DFS**, con pila. Ver [7.1](#71-búsqueda-en-profundidad--dfs). |
| `breadthFirstSearch(problem)` | función | **BFS**, con cola. Ver [7.2](#72-búsqueda-en-anchura--bfs). |
| `uniformCostSearch(problem)` | función | **UCS**, con cola de prioridad por costo. Ver [7.3](#73-búsqueda-de-costo-uniforme--ucs). |
| `nullHeuristic(state, problem)` | función | Heurística nula: siempre devuelve 0. Es el valor por defecto de A\*. |
| `aStarSearch(problem, heuristic)` | función | **A\***, con cola de prioridad por costo + heurística. Ver [7.4](#74-búsqueda-a). |
| `bfs`, `dfs`, `ucs`, `astar` | alias | Otros nombres para las mismas funciones. Por eso en la consola se puede escribir `-a fn=bfs` en vez de `fn=breadthFirstSearch`. |

### `searchAgents.py` – el puente entre el juego y la búsqueda

| Elemento | Tipo | Qué hace |
|---|---|---|
| **`SearchAgent`** | clase (agente) | **El Pacman que usa nuestros algoritmos.** Ver abajo. |
| **`PositionSearchProblem`** | clase (problema) | **El problema que resolvemos**: llegar desde la posición de Pacman hasta la meta `(1,1)`. Ver la [sección 4](#4-el-problema-de-búsqueda). |
| `StayEastSearchAgent` | clase (agente) | Usa UCS con costo `0.5 ** x`, así que caminar por la derecha es barato. Ver la [sección 10](#10-costos-distintos-por-qué-existe-ucs). |
| `StayWestSearchAgent` | clase (agente) | Usa UCS con costo `2 ** x`, así que caminar por la izquierda es barato. |
| **`manhattanHeuristic(position, problem)`** | función | Heurística de A\*: `|x1 − x2| + |y1 − y2|` hasta la meta. |

**`SearchAgent` por dentro**

- `__init__(fn, prob, heuristic)`: recibe los textos que vienen de `-a`.
  1. Busca en `search.py` la función que se llama como `fn` (`getattr(search, fn)`). Si no existe, tira error.
  2. Se fija si esa función tiene un parámetro `heuristic` (`func.__code__.co_varnames`). Solo A\* lo tiene.
     - Si no lo tiene (DFS, BFS, UCS), la guarda tal cual en `self.searchFunction`.
     - Si lo tiene (A\*), busca la heurística por nombre y guarda `lambda x: func(x, heuristic=heur)`, una función que ya "trae puesta" la heurística.
  3. Guarda la clase del problema (`PositionSearchProblem` por defecto) en `self.searchType`.
- `registerInitialState(state)`: el juego la llama **una vez al principio**. Crea el problema, llama a nuestro algoritmo, guarda la lista de acciones en `self.actions` e imprime el costo y los nodos expandidos.
- `getAction(state)`: el juego la llama **en cada turno**. Devuelve `self.actions[i]` y avanza el índice. Cuando se terminan las acciones, devuelve `Stop`.

### `pacman.py` – el que se ejecuta

| Elemento | Tipo | Qué hace |
|---|---|---|
| **`GameState`** | clase | Una "foto" del juego en un momento: posición de Pacman y fantasmas, comida, paredes, puntaje. Métodos que usamos indirectamente: `getPacmanPosition()`, `getWalls()`, `getFood()`, `hasFood(x, y)`, `getNumFood()`, `generateSuccessor(agente, acción)` (devuelve el estado siguiente), `isWin()`, `isLose()`. |
| `ClassicGameRules` | clase | Reglas generales: arma la partida (`newGame`) y, después de cada movimiento, se fija si se ganó o perdió (`process`, `win`, `lose`). |
| `PacmanRules` | clase | Reglas de Pacman: qué movimientos son legales, cómo se mueve (`applyAction`) y qué pasa al comer (`consume`: +10 por punto, +500 al comer el último y ganar). |
| `GhostRules` | clase | Reglas de los fantasmas: cómo se mueven, cuándo se comen a Pacman o Pacman los come a ellos. |
| `readCommand(argv)` | función | Lee los parámetros de la consola (ver la tabla de abajo) y arma todos los objetos. |
| `parseAgentArgs(str)` | función | Convierte `"fn=bfs,heuristic=x"` en el diccionario `{'fn': 'bfs', 'heuristic': 'x'}`. |
| `loadAgent(nombre, ...)` | función | Busca en todos los archivos que terminan en `gents.py` una clase con ese nombre. Así encuentra `SearchAgent` en `searchAgents.py`. |
| `runGames(...)` | función | Corre las partidas e imprime el resumen final (puntaje, `Win Rate`, `Record: Win`). |

**Parámetros de consola más útiles**

| Parámetro | Qué hace | Ejemplo |
|---|---|---|
| `-l` | Laberinto (archivo de `layouts/`, sin `.lay`) | `-l mediumMaze` |
| `-p` | Agente que controla a Pacman | `-p SearchAgent` |
| `-a` | Argumentos para el agente | `-a fn=astar,heuristic=manhattanHeuristic` |
| `-q` | Sin ventana, solo texto (rápido) | `-q` |
| `-z` | Zoom de la ventana | `-z 0.5` |
| `--frameTime` | Segundos entre cuadros (0 = lo más rápido posible) | `--frameTime 0` |

### `game.py` – las piezas genéricas del juego

| Elemento | Tipo | Qué hace |
|---|---|---|
| `Agent` | clase base | Todo agente (Pacman o fantasma) hereda de acá y tiene que implementar `getAction(state)`. `SearchAgent` hereda de `Agent`. |
| `Directions` | clase (constantes) | Los nombres de las acciones: `NORTH = 'North'`, `SOUTH`, `EAST`, `WEST`, `STOP`. Son los textos que aparecen en el camino que devolvemos. |
| `Actions` | clase (utilidades) | Traduce acciones a vectores: `directionToVector('North')` → `(0, 1)`. `getSuccessors` lo usa para calcular a qué casilla lleva cada movimiento. |
| `Configuration` | clase | Posición y dirección de un agente. |
| `AgentState` | clase | El estado de un agente: su `Configuration`, si es Pacman y si está asustado (`scaredTimer`). |
| `Grid` | clase | Matriz de booleanos que se indexa `grid[x][y]`. Se usa para las paredes (`walls[x][y] == True` es pared) y la comida. |
| `GameStateData` | clase | Los datos crudos que tiene adentro un `GameState`. |
| **`Game`** | clase | **El bucle principal** (`run`): llama a `registerInitialState` de cada agente y después, turno por turno, pide `getAction`, aplica la acción, actualiza la pantalla y se fija si terminó. |

Coordenadas: `x` crece hacia la derecha e `y` crece **hacia arriba**. Por eso `(1,1)` es la esquina de **abajo a la izquierda**.

### `util.py` – herramientas

| Elemento | Qué hace |
|---|---|
| **`Stack`** | Pila (LIFO). La usa **DFS**. |
| **`Queue`** | Cola (FIFO). La usa **BFS**. |
| **`PriorityQueue`** | Cola de prioridad (un heap). La usan **UCS y A\***. |
| `manhattanDistance(a, b)` | Distancia Manhattan entre dos puntos. |
| `Counter` | Diccionario que devuelve 0 si la clave no existe. Lo usan los fantasmas para sus probabilidades. |
| `raiseNotDefined()` | Corta el programa avisando que un método no está implementado. |
| `normalize`, `sample`, `chooseFromDistribution` | Azar con probabilidades. Los usan los fantasmas para elegir hacia dónde moverse. |
| `nearestPoint`, `pause`, `TimeoutFunction` | Utilidades internas del motor (redondear posiciones, pausas, tiempos límite). |

### `layout.py` – los mapas

| Elemento | Qué hace |
|---|---|
| `Layout` | Representa un mapa: ancho, alto, paredes, comida, cápsulas y posiciones iniciales de los agentes. |
| `Layout.processLayoutChar` | Traduce cada carácter del `.lay`: `%` pared, `.` comida, `o` cápsula, `P` Pacman, `G` fantasma. |
| `getLayout(nombre)` | Busca y carga `layouts/<nombre>.lay`. |

### Agentes del juego

| Archivo | Clases | Qué hacen |
|---|---|---|
| `ghostAgents.py` | `GhostAgent`, `RandomGhost` | Fantasmas que se mueven al azar. El motor siempre los carga, pero solo aparecen en laberintos que tienen `G`, y los nuestros no tienen. |

### Pantalla

| Archivo | Qué hace |
|---|---|
| `graphicsDisplay.py` | Dibuja el juego en una ventana (`PacmanGraphics`): paredes, comida, Pacman y fantasmas. Su método `drawExpandedCells` **pinta de rojo las casillas que exploró el algoritmo**: las primeras con un rojo más fuerte y las últimas más suave. |
| `graphicsUtils.py` | Funciones básicas de dibujo sobre Tkinter: `circle`, `square`, `line`, `text`, `begin_graphics`, etc. |
| `textDisplay.py` | `NullGraphics`: la "pantalla" que no muestra nada. Es la que se usa con `-q`. |

### Otros archivos

| Archivo | Qué es |
|---|---|
| `layouts/` | Los laberintos en texto. `tp2Maze.lay` es el laberinto chico que armamos para explicar. |
| `README.md` | Presentación del TP. |
| `jugar.bat` | Menú para correrlo en Windows: elegís con vista o sin vista, el algoritmo y el laberinto, y arma el comando de `pacman.py` por vos. |
| `.gitattributes` | Hace que git guarde `jugar.bat` con saltos de línea de Windows, que es lo que necesita `cmd` para ejecutarlo bien. |
| `EXPLICACION.md` | Esta guía. |
| `docs/` | El enunciado en PDF y las imágenes del README. |
| `.gitignore` | Le dice a git que ignore `__pycache__/`, los `.pyc` que Python genera solo y el entorno virtual `.venv/`. |

---

## 4. El problema de búsqueda

Pacman está en un laberinto y tiene que llegar a la comida que está en `(1,1)`.

| Concepto | En nuestro problema |
|---|---|
| **Estado** | La posición de Pacman, una tupla `(x, y)` |
| **Estado inicial** | Donde aparece la `P` en el mapa. En `tp2Maze` es `(4, 9)` |
| **Acciones** | `North`, `South`, `East`, `West`, siempre que no haya pared |
| **Test de meta** | ¿El estado es `(1, 1)`? |
| **Costo** | 1 por paso (salvo en `StayEast`/`StayWest`) |
| **Solución** | Una lista de acciones, por ejemplo `['West', 'West', 'West', 'South', ...]` |

Esto lo implementa **`PositionSearchProblem`** (en `searchAgents.py`), que hereda de `SearchProblem`:

| Método | Qué devuelve | Cómo lo hace |
|---|---|---|
| `getStartState()` | La posición inicial | Devuelve `self.startState`, que sacó de `gameState.getPacmanPosition()`. |
| `isGoalState(state)` | `True` / `False` | Compara `state == self.goal`. Si es la meta y hay ventana, además **pinta de rojo** las casillas exploradas. |
| `getSuccessors(state)` | Lista de `(sucesor, acción, costo)` | Prueba las 4 direcciones en orden **North, South, East, West**. Para cada una calcula la casilla de destino con `Actions.directionToVector` y, si no es pared, la agrega con su costo (`self.costFn`). **También suma 1 a `self._expanded`**: ese es el número de "nodos expandidos" que se imprime. |
| `getCostOfActions(actions)` | Costo total de un camino | Recorre las acciones sumando costos. Si alguna choca contra una pared, devuelve 999999. |

Ejemplo real: en `tp2Maze`, `getSuccessors((4, 9))` devuelve `[((3, 9), 'West', 1)]`. Desde el inicio solo se puede ir al oeste.

---

## 5. Las estructuras de datos

Están en `util.py`. Son las que definen el comportamiento de cada algoritmo.

**`Stack` (pila, LIFO: último en entrar, primero en salir)**
```python
push(item)  ->  self.list.append(item)      # agrega al final
pop()       ->  self.list.pop()             # saca del final
```

**`Queue` (cola, FIFO: primero en entrar, primero en salir)**
```python
push(item)  ->  self.list.insert(0, item)   # agrega al principio
pop()       ->  self.list.pop()             # saca del final, o sea el más viejo
```

**`PriorityQueue` (cola de prioridad)**
```python
push(item, prioridad)  ->  heapq.heappush(self.heap, (prioridad, self.count, item))
pop()                  ->  saca el elemento con la prioridad MÁS CHICA
```
- Por dentro es un **heap** (montículo binario), así que meter y sacar cuesta O(log n).
- `self.count` es un contador que aumenta con cada `push`. Sirve para **desempatar**: si dos elementos tienen la misma prioridad, sale primero el que entró antes. Además evita que Python tenga que comparar los `item` entre sí.

---

## 6. El esqueleto común a los 4 algoritmos

Los 4 algoritmos son **el mismo bucle**. Lo único que cambia es la **frontera**: la estructura donde guardamos los caminos que faltan explorar, y en qué orden se sacan.

```python
frontera = <Stack / Queue / PriorityQueue>
frontera.push((estado_inicial, []))        # cada elemento guarda su propio camino
visitados = set()

while not frontera.isEmpty():
    estado, camino = frontera.pop()        # <- ACÁ cambia cada algoritmo
    if problem.isGoalState(estado):
        return camino                      # llegamos: devolvemos las acciones
    if estado in visitados:
        continue                           # ya lo expandimos por otro camino
    visitados.add(estado)
    for sucesor, accion, costo in problem.getSuccessors(estado):
        if sucesor not in visitados:
            frontera.push((sucesor, camino + [accion]))

return []                                  # se vació la frontera: no hay solución
```

Las decisiones de diseño que hay que saber justificar:

1. **Cada elemento de la frontera guarda su camino** (`camino + [accion]`). Cuando sacamos la meta, ya tenemos la lista de acciones lista para devolver, sin tener que reconstruirla.
2. **`visitados` es un `set`**, así que preguntar `estado in visitados` cuesta O(1). Evita expandir dos veces la misma casilla y quedarse dando vueltas. A esto se le llama **búsqueda en grafo**, a diferencia de la búsqueda en árbol, que no recuerda lo visitado.
3. **El test de meta se hace al *sacar* de la frontera, no al *meter*.** En UCS y A\* esto es necesario para garantizar el óptimo: puede haber en la frontera un camino más caro a la meta que todavía no salió, mientras otro más barato todavía se está construyendo.
4. **Se marca visitado al *sacar*, no al *meter*.** Por eso un mismo estado puede estar varias veces en la frontera con caminos distintos. El `if estado in visitados: continue` descarta las copias que salen después. En UCS y A\* la primera copia que sale es siempre la más barata.
5. **Si no hay solución devuelve `[]`**, una lista vacía de acciones.

En UCS y A\* cada elemento guarda además su costo acumulado: `(estado, camino, costo_acum)`.

---

## 7. Los 4 algoritmos en detalle

Para los ejemplos usamos `tp2Maze` (está en `layouts/tp2Maze.lay`). Pacman arranca en `(4, 9)` y la meta es `(1, 1)`:

```
        x: 0 1 2 3 4 5
  y=10     % % % % % %
  y= 9     %       P %      P = inicio (4,9)
  y= 8     %   % % % %
  y= 7     %       % %
  y= 6     %   %   % %
  y= 5     %   %     %
  y= 4     %   % %   %
  y= 3     %         %
  y= 2     % % %   % %
  y= 1     % .       %      . = meta (1,1)
  y= 0     % % % % % %
```

Desde el inicio hay un único pasillo hacia el oeste hasta `(1,9)`, y ahí empieza a bajar. En `(1,7)` el laberinto se divide: por la **izquierda** (columna 1) se baja directo, y por la **derecha** se da una vuelta por `(3,7) → (3,5) → (4,5) → (4,3)`. Las dos ramas se juntan en la fila `y = 3`.

### 7.1 Búsqueda en profundidad – DFS

```python
def depthFirstSearch(problem):
    frontera = util.Stack()
    frontera.push((problem.getStartState(), []))
    visitados = set()
    while not frontera.isEmpty():
        estado, camino = frontera.pop()
        if problem.isGoalState(estado):
            return camino
        if estado in visitados:
            continue
        visitados.add(estado)
        for sucesor, accion, costo in problem.getSuccessors(estado):
            if sucesor not in visitados:
                frontera.push((sucesor, camino + [accion]))
    return []
```

- **Frontera:** `util.Stack()`, una pila. Sale **el último que entró**.
- **Cómo se comporta:** siempre sigue por el vecino que agregó último. Se mete por un camino hasta el fondo y, recién cuando se traba (no quedan vecinos sin visitar), vuelve al último punto donde dejó opciones pendientes. Eso es el *backtracking*.
- **Ignora el costo**: no usa la variable `costo` para nada.

**En `tp2Maze`** (expandió 22 casillas, camino de **17** pasos):
```
(4,9) (3,9) (2,9) (1,9) (1,8) (1,7)                         pasillo inicial
(2,7) (3,7) (3,6) (3,5) (4,5) (4,4) (4,3) (3,3) (2,3) (1,3)  se mete por la RAMA DERECHA
(1,4) (1,5) (1,6)                                            sube por un callejón sin salida
(3,2) (3,1) (2,1)  -> meta (1,1)                             vuelve atrás y baja a la meta
```
En `(1,7)` metió a la pila primero el sur `(1,6)` y después el este `(2,7)`. Como sale el último que entró, se fue por el este, la vuelta larga, y por eso llegó con 17 pasos en vez de 15.

| Propiedad | DFS |
|---|---|
| ¿Completo (encuentra solución si hay)? | Sí, en espacios finitos y con `visitados` |
| ¿Óptimo (camino más corto/barato)? | **No** |
| Tiempo | O(b^m) |
| Memoria | O(b·m) en la versión clásica. Acá un poco más, porque guardamos el camino en cada elemento |

(*b* = factor de ramificación, es decir cuántos vecinos tiene cada estado; *m* = profundidad máxima del espacio; *d* = profundidad de la solución más corta.)

### 7.2 Búsqueda en anchura – BFS

```python
def breadthFirstSearch(problem):
    frontera = util.Queue()
    ...  # exactamente el mismo bucle que DFS
```

- **Frontera:** `util.Queue()`, una cola. Sale **el primero que entró**.
- **Cómo se comporta:** explora **por niveles**. Primero todas las casillas a 1 paso, después todas las de 2 pasos, y así. Es como una mancha que se expande pareja desde el inicio.
- **Por qué encuentra el camino más corto:** como saca por niveles, la primera vez que saca la meta lo hace desde el nivel más bajo posible, o sea con la menor cantidad de pasos.

**En `tp2Maze`** (expandió 23 casillas, camino de **15** pasos):
```
(4,9) (3,9) (2,9) (1,9) (1,8) (1,7)        pasillo inicial
(1,6) (2,7) (1,5) (3,7) (1,4) (3,6) ...    avanza las DOS ramas a la vez, intercalando
... (3,1) (4,1) (2,1)  -> meta (1,1)
```
Se ve cómo intercala `(1,6)` (rama izquierda) con `(2,7)` (rama derecha): avanza un paso en cada una. Gana la rama izquierda porque llega antes a la meta.

| Propiedad | BFS |
|---|---|
| ¿Completo? | Sí |
| ¿Óptimo? | **Sí, si todos los pasos cuestan lo mismo** |
| Tiempo | O(b^d) |
| Memoria | O(b^d): guarda todo un nivel entero. Es su punto débil |

### 7.3 Búsqueda de costo uniforme – UCS

```python
def uniformCostSearch(problem):
    frontera = util.PriorityQueue()
    frontera.push((problem.getStartState(), [], 0), 0)
    visitados = set()
    while not frontera.isEmpty():
        estado, camino, costo_acum = frontera.pop()
        if problem.isGoalState(estado):
            return camino
        if estado in visitados:
            continue
        visitados.add(estado)
        for sucesor, accion, costo in problem.getSuccessors(estado):
            if sucesor not in visitados:
                nuevo_costo = costo_acum + costo
                frontera.push((sucesor, camino + [accion], nuevo_costo), nuevo_costo)
    return []
```

- **Frontera:** `util.PriorityQueue()`, ordenada por **`g(n)` = costo acumulado** desde el inicio.
- **Diferencias con BFS:**
  - Cada elemento lleva su `costo_acum`.
  - Al meter un sucesor, su prioridad es `costo_acum + costo`.
- **Cómo se comporta:** siempre expande el camino **más barato encontrado hasta ahora**, sin importar cuántos pasos tenga. Es la idea del algoritmo de Dijkstra.
- **Por qué es óptimo:** como saca siempre el más barato y los costos nunca son negativos, cuando saca la meta no puede existir un camino más barato todavía sin explorar.

**En `tp2Maze`** expande **exactamente las mismas 23 casillas, en el mismo orden que BFS**, y encuentra el mismo camino de 15. ¿Por qué? Porque todos los pasos cuestan 1, entonces "costo acumulado" = "cantidad de pasos", y ordenar por costo es lo mismo que ordenar por nivel. Además, el contador de la `PriorityQueue` desempata por orden de llegada, igual que una cola.

UCS se diferencia de BFS cuando **los costos son distintos** (ver la [sección 10](#10-costos-distintos-por-qué-existe-ucs)).

| Propiedad | UCS |
|---|---|
| ¿Completo? | Sí, si todo costo es > 0 |
| ¿Óptimo? | **Sí, con cualquier costo no negativo** |
| Tiempo y memoria | O(b^(1 + C\*/ε)), donde C\* es el costo de la solución óptima y ε el costo mínimo de un paso |

### 7.4 Búsqueda A\*

```python
def aStarSearch(problem, heuristic=nullHeuristic):
    inicio = problem.getStartState()
    frontera = util.PriorityQueue()
    frontera.push((inicio, [], 0), heuristic(inicio, problem))
    visitados = set()
    while not frontera.isEmpty():
        estado, camino, costo_acum = frontera.pop()
        if problem.isGoalState(estado):
            return camino
        if estado in visitados:
            continue
        visitados.add(estado)
        for sucesor, accion, costo in problem.getSuccessors(estado):
            if sucesor not in visitados:
                nuevo_costo = costo_acum + costo
                prioridad = nuevo_costo + heuristic(sucesor, problem)
                frontera.push((sucesor, camino + [accion], nuevo_costo), prioridad)
    return []
```

- **Frontera:** `util.PriorityQueue()` ordenada por **`f(n) = g(n) + h(n)`**:
  - `g(n)` = `nuevo_costo`: lo que **ya** caminamos desde el inicio.
  - `h(n)` = `heuristic(sucesor, problem)`: lo que **estimamos** que falta hasta la meta.
  - `f(n)`: la estimación del costo total de un camino que pase por `n`.
- **Ojo:** en la tupla guardamos `nuevo_costo` (g) y no la prioridad (f). Si guardáramos f, la heurística se iría acumulando en cada paso y los costos quedarían mal.
- **Cómo se comporta:** como UCS, pero "tirando" hacia la meta. Entre dos caminos igual de baratos, prefiere el que está más cerca del objetivo.
- **Con `nullHeuristic`** (h = 0 siempre), f = g y A\* es exactamente UCS.

**En `tp2Maze`** (expandió solo **19** casillas, camino de **15**):
```
(4,9) (3,9) (2,9) (1,9) (1,8) (1,7)
(1,6) (1,5) (1,4) (1,3)      baja derecho por la rama IZQUIERDA, la que va hacia la meta
(2,7) (2,3) (3,7) (3,3) (3,6) (3,2) (3,5) (3,1) (2,1)  -> meta (1,1)
```
A diferencia de BFS, no intercala las ramas desde el principio. Baja derecho por la columna 1, porque cada paso hacia el sur baja h. De la rama derecha solo mira el principio, `(2,7) → (3,5)`, y nunca llega a `(4,5)`, `(4,4)` ni `(4,3)`. Encuentra el mismo camino óptimo que BFS/UCS pero mirando 19 casillas en vez de 23.

| Propiedad | A\* |
|---|---|
| ¿Completo? | Sí |
| ¿Óptimo? | **Sí, si la heurística es admisible** (y consistente, en búsqueda en grafo como la nuestra) |
| Tiempo y memoria | Depende de qué tan buena sea la heurística. En el peor caso (h = 0) es igual a UCS |

### Resumen de los 4

| | Frontera | Ordena por | ¿Óptimo? | ¿Usa heurística? |
|---|---|---|---|---|
| DFS | Pila | Último en entrar | No | No |
| BFS | Cola | Primero en entrar | Sí, con costos iguales | No |
| UCS | Cola de prioridad | g(n) | Sí | No |
| A\* | Cola de prioridad | g(n) + h(n) | Sí, con h admisible | **Sí** |

> El enunciado los llama "búsqueda informada" a los 4, pero en rigor **solo A\* es informada**, porque es la única que usa información extra sobre dónde está la meta (la heurística). DFS, BFS y UCS son **búsquedas no informadas** (o ciegas).

---

## 8. Heurísticas

Una heurística es una función `h(estado)` que **estima** cuánto falta para llegar a la meta. Tiene que ser rápida de calcular: no puede ser "resolver el problema de nuevo".

**`manhattanHeuristic`** (la que usamos con A\*):
```python
def manhattanHeuristic(position, problem, info={}):
    xy1 = position
    xy2 = problem.goal
    return abs(xy1[0] - xy2[0]) + abs(xy1[1] - xy2[1])
```
Es lo que caminaría Pacman **si no hubiera paredes**, moviéndose solo en horizontal y vertical. Por ejemplo, desde el inicio de `tp2Maze`: `|4 − 1| + |9 − 1| = 3 + 8 = 11`. El camino real es de 15.

- **Admisible:** nunca sobreestima. Las paredes solo pueden hacer el camino real **igual o más largo**, nunca más corto. Esto es lo que garantiza que A\* encuentre el óptimo.
- **Consistente:** al dar un paso (que cuesta 1), h baja como mucho 1. Esto garantiza que, con nuestra lista de `visitados`, la primera vez que se expande un estado es por su camino más barato.

**Cuanto más se acerque h al costo real sin pasarse, menos nodos expande A\*.** Por ejemplo, la distancia en línea recta también sería admisible, pero da valores más chicos que Manhattan (desde el inicio de `tp2Maze`, ≈ 8.5 contra 11), así que guiaría peor. Y con `nullHeuristic` (h = 0) A\* no tiene ninguna guía y expande lo mismo que UCS.

---

## 9. Resultados

Costo del camino / nodos expandidos (medido corriendo `python pacman.py -l <laberinto> -p SearchAgent -a fn=<algoritmo> -q`; todos ganan):

| Laberinto | DFS | BFS | UCS | A\* (Manhattan) |
|---|---|---|---|---|
| `tp2Maze` | 17 / 22 | 15 / 23 | 15 / 23 | 15 / **19** |
| `mediumMaze` | 130 / 146 | 68 / 269 | 68 / 269 | 68 / **221** |

Cómo leer la tabla:
- **DFS** da el camino más largo: no es óptimo. En `mediumMaze` da 130 pasos contra 68.
- **BFS y UCS** dan exactamente lo mismo, porque todos los pasos cuestan 1.
- **A\*** da el mismo camino óptimo que BFS/UCS, pero **siempre expandiendo menos**: un 18 % menos en `mediumMaze` (221 contra 269).
- DFS a veces expande menos nodos que BFS (146 contra 269 en `mediumMaze`), pero a cambio encuentra un camino mucho peor.

---

## 10. Costos distintos: por qué existe UCS

Los agentes `StayEastSearchAgent` y `StayWestSearchAgent` (en `searchAgents.py`) usan UCS sobre un `PositionSearchProblem` con una **función de costo que depende de la columna** `x`:

```python
class StayEastSearchAgent(SearchAgent):
    def __init__(self):
        self.searchFunction = search.uniformCostSearch
        costFn = lambda pos: .5 ** pos[0]     # más a la derecha = más barato
        ...

class StayWestSearchAgent(SearchAgent):
    def __init__(self):
        self.searchFunction = search.uniformCostSearch
        costFn = lambda pos: 2 ** pos[0]      # más a la derecha = carísimo
        ...
```

- **StayEast:** pisar la columna `x` cuesta `0.5^x`. A la derecha es casi gratis, así que UCS prefiere ir por el este aunque dé más pasos.
- **StayWest:** pisar la columna `x` cuesta `2^x`. A la derecha es carísimo, así que UCS se pega al oeste.

**BFS no ve estos costos**: solo cuenta pasos y elegiría siempre el camino más corto. Acá se ve la diferencia real entre BFS y UCS. En `mediumMaze`:

| | Pasos del camino |
|---|---|
| BFS (o UCS con costo 1) | 68 |
| `StayEastSearchAgent` | 74 |
| `StayWestSearchAgent` | 152 |

UCS elige caminos con **más pasos** porque son **más baratos** según esos costos.

```bash
python pacman.py -l mediumMaze -p StayEastSearchAgent
python pacman.py -l mediumMaze -p StayWestSearchAgent
```

---

## Qué se ve al correrlo

Hay dos formas de correrlo: **con vista** y **sin vista**. El comando es el mismo; sin vista solo se le agrega `-q`. El menú de `jugar.bat` ofrece las mismas dos opciones y arma el comando solo.

**1. Con vista**

```bash
python pacman.py -l tp2Maze -p SearchAgent -a fn=astar,heuristic=manhattanHeuristic
```

1. Antes de que Pacman se mueva, el algoritmo **ya buscó el camino entero**. Las casillas que exploró se pintan de **rojo**: más fuerte las primeras que miró, más suave las últimas.
2. Después Pacman **recorre** ese camino hasta la meta, se come el punto y gana. La ventana se cierra sola.
3. En la consola queda el resumen: `Path found with total cost of 15` y `Search nodes expanded: 19`.

Lo interesante es **comparar el rojo** entre algoritmos en el mismo laberinto:
- **DFS:** poco rojo, pero Pacman da una vuelta larga.
- **BFS / UCS:** mucho rojo, que se expande parejo en todas direcciones.
- **A\*:** menos rojo, concentrado en dirección a la meta.

**2. Sin vista**

```bash
python pacman.py -l mediumMaze -p SearchAgent -a fn=bfs -q
```

No abre ventana: imprime el resultado al instante. Corriendo los 4 algoritmos así se arma la tabla de la [sección 9](#9-resultados):
- **`total cost`** (pasos del camino): qué tan bueno es el camino. **Menos es mejor.**
- **`nodes expanded`** (casillas exploradas): cuánto tuvo que buscar. Es el rojo de la ventana, contado. **Menos es más eficiente.**

Para la defensa: mostrá el juego con vista para que se **vea** la diferencia y los números sin vista para **explicarla**.

---

## 12. Lo que sacamos del código base

El juego que da la cátedra trae más cosas que esta consigna no pide. Las borramos para que quede solo lo que se usa:

| Qué | Para qué era |
|---|---|
| `CornersProblem`, `FoodSearchProblem`, `ClosestDotSearchAgent` y sus heurísticas y agentes (`searchAgents.py`) | Otros ejercicios: pasar por las 4 esquinas, comer toda la comida, ir a la comida más cercana |
| `GoWestAgent`, `euclideanHeuristic`, `mazeDistance` (`searchAgents.py`) y `tinyMazeSearch` (`search.py`) | Ejemplos y utilidades de esos ejercicios |
| `pacmanAgents.py` y `keyboardAgents.py` | Pacmans que no buscan y el control por teclado |
| `DirectionalGhost` (`ghostAgents.py`) | Fantasmas que persiguen a Pacman |
| Grabar y reproducir partidas (`-r`, `--replay`), modo texto (`-t`), entrenamiento (`-x`) en `pacman.py` | Funciones del motor para otros TPs |
| El autograder (`grading.py`, `testClasses.py`, ...) y `eightpuzzle.py` | Corrección automática y otro problema de ejemplo |
| Los otros laberintos (quedaron solo `tp2Maze` y `mediumMaze`) | Con esos dos alcanza: uno chico para explicar paso a paso y uno mediano para comparar con números |

Ahora, si se corre `python pacman.py` sin parámetros, arranca `SearchAgent` (con DFS, el valor por defecto) en `tp2Maze`.

---

## 13. Preguntas probables

**¿Qué diferencia hay entre los 4 algoritmos en el código?**
Solo la frontera: pila (DFS), cola (BFS), cola de prioridad por g (UCS) y cola de prioridad por g + h (A\*). El resto del bucle es igual.

**¿Dónde se llama a nuestro código?**
En `SearchAgent.registerInitialState` (`searchAgents.py`), con `self.actions = self.searchFunction(problem)`. El juego llama a ese método una vez antes del primer turno.

**¿Cómo sabe `SearchAgent` qué algoritmo usar?**
Por el parámetro `-a fn=...`. `pacman.py` lo convierte en un diccionario y se lo pasa al constructor. El constructor busca en `search.py` la función con ese nombre (`getattr(search, fn)`).

**¿Qué devuelven los algoritmos?**
Una lista de acciones, como `['West', 'South', ...]`. Si no hay solución, `[]`.

**¿Qué es un "nodo expandido"?**
Un estado al que le pedimos sus sucesores (`getSuccessors`). Lo cuenta `PositionSearchProblem` en `self._expanded`.

**¿Por qué DFS no da el camino más corto?**
Porque se mete por el primer camino que encuentra hasta el fondo, sin comparar longitudes. En `tp2Maze` se fue por la rama derecha (17 pasos) en vez de la izquierda (15).

**¿Por qué BFS y UCS dan exactamente los mismos resultados?**
Porque todos los pasos cuestan 1. Ordenar por costo acumulado es lo mismo que ordenar por cantidad de pasos, y la `PriorityQueue` desempata por orden de llegada, igual que una cola.

**¿Entonces para qué sirve UCS?**
Para cuando los pasos cuestan distinto. Con `StayEastSearchAgent` / `StayWestSearchAgent` UCS elige el camino más barato aunque tenga más pasos. BFS no podría.

**¿Qué es una heurística? ¿Por qué Manhattan?**
Una estimación de cuánto falta para la meta. Manhattan es la distancia sin paredes y moviéndose en cruz, igual que Pacman. Es admisible (nunca sobreestima) y consistente, así que A\* sigue encontrando el óptimo.

**¿Por qué A\* expande menos nodos?**
Porque suma la heurística a la prioridad: los caminos que se alejan de la meta quedan con f más alto y se postergan. En `tp2Maze` deja sin explorar la mitad de la rama derecha.

**¿Qué pasaría con una heurística que sobreestima?**
A\* podría descartar el camino óptimo y devolver uno peor, porque creería que ese camino es más caro de lo que realmente es.

**¿Para qué sirve `visitados`?**
Para no expandir dos veces la misma casilla. Sin eso, el algoritmo podría ir y volver entre dos casillas para siempre.

**¿Por qué se chequea la meta y se marca visitado al *sacar* de la frontera y no al *meter*?**
Porque en UCS y A\* puede aparecer más tarde un camino más barato a una casilla que ya está en la frontera. Si decidiéramos al meterla, ese camino mejor se perdería. Al decidir cuando sale, la primera vez que se expande (o se reconoce como meta) es por el camino más barato.

**¿Por qué en A\* guardamos `nuevo_costo` y no `prioridad` en la tupla?**
Porque el costo acumulado tiene que ser solo g. Si guardáramos f, en el paso siguiente sumaríamos la heurística encima de otra heurística.

**¿Qué archivos modificamos?**
`search.py`, donde implementamos los 4 algoritmos. El resto es el juego que provee la cátedra.
