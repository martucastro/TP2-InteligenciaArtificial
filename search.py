import util

class SearchProblem:
    def getStartState(self):
        util.raiseNotDefined()

    def isGoalState(self, state):
        util.raiseNotDefined()

    def getSuccessors(self, state):
        util.raiseNotDefined()

    def getCostOfActions(self, actions):
        util.raiseNotDefined()


def depthFirstSearch(problem):
    # DFS: usa una pila, asi que se la juega por un camino hasta el fondo
    # y recien despues vuelve a probar otro. No garantiza el camino mas corto.
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


def breadthFirstSearch(problem):
    # BFS: usa una cola, asi que va explorando nivel por nivel.
    # Encuentra el camino con menos pasos.
    frontera = util.Queue()
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


def uniformCostSearch(problem):
    # UCS: cola de prioridad ordenada por lo que cuesta llegar hasta ahi.
    # Siempre expande el camino mas barato que tenga.
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


def nullHeuristic(state, problem=None):
    # heuristica nula: dice que falta 0 siempre, con eso A* queda igual que UCS
    return 0

def aStarSearch(problem, heuristic=nullHeuristic):
    # A*: como UCS pero la prioridad es costo acumulado + heuristica,
    # o sea lo que ya gastamos mas lo que estimamos que falta para la meta.
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


bfs = breadthFirstSearch
dfs = depthFirstSearch
astar = aStarSearch
ucs = uniformCostSearch
