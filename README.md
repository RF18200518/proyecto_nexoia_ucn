# Night Shift: Turno Maldito — Prototipo

Proyecto Roblox (Rojo 7.7.0). Horror cooperativo en el supermercado MoonMart 24.

## Como correrlo

1. Compilar el lugar:

```bash
rojo build -o firts_game_roblox.rbxlx
```

2. Abrir `firts_game_roblox.rbxlx` en Roblox Studio.

3. Iniciar el servidor de Rojo para editar en vivo:

```bash
rojo serve
```

4. Play. Un jugador solo funciona; con mas jugadores se prueba el modo cooperativo.

## Que esta implementado (prototipo Semana 1)

- **Mapa completo** generado por script (`src/server/MapBuilder.luau`): piso, techo, paredes, 6 pasillos con estanterias y productos, cajas registradoras, sala de empleados, oficina de seguridad, almacen, muelle de carga, congeladores, banos y letrero MOONMART 24.
- **Ciclo de ronda** (`RoundService`): Sala de espera -> Briefing -> Turno normal -> Medianoche -> Investigacion -> Caceria -> Resultados. Se reinicia solo.
- **5 tareas** (`TaskService`): colocar cajas, limpiar derrame, reparar fusible, revisar camaras, regresar carrito. Necesitas completar 3 para avanzar (configurable).
- **Electricidad** (`PowerService`): drena con el tiempo, luces que parpadean por niveles, apagon en Medianoche con luces rojas de emergencia.
- **Cliente Cero** (`MonsterService`): aparece con aviso despues de la medianoche, persigue, atrapa jugadores (estado Caido) y se retira.
- **Interfaz** (`UIController`): reloj en tiempo de juego, barra de electricidad, panel de objetivos, stamina, bateria de linterna, overlay de apagon, aviso del monstruo, resultados.
- **Controles**: Shift = correr (con stamina), F = linterna, botones tactiles en movil.
- **Salida**: la puerta se bloquea en Medianoche y se abre en Investigacion/Caceria. Usa el prompt para escapar y ganar.

## Pendiente (proximas semanas)

- Anomalias aleatorias con 3 pistas + votacion.
- Jugador caido con revive por compañero.
- Monedas/XP con DataStore y tienda.
- Sonidos reales (los `SoundId` en `GameConfig` estan vacios).
- Modelos/arte detallado y Pasillo 0.

## Estructura

```
src/shared     -> GameConfig (todos los valores), Remotes
src/server     -> MapBuilder, RoundService, TaskService, PowerService, MonsterService
src/client     -> ClientController (input), UIController (UI), AudioController, ClientState
```

## Ajustes rapidos

Todos los numeros (tiempos de fases, velocidad, stamina, drenaje de energia, tareas requeridas) viven en `src/shared/GameConfig.luau`.

## Seguridad

Los objetos de tarea llevan atributos (`InteractType`, `TaskId`, `IsActive`, etc.) y el servidor valida fase y estado antes de completar. La autoridad de monedas/recompensas aun no existe (se agregara con DataService).
