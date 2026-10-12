# MEMORY.md — Night Shift: Turno Maldito

Archivo de memoria del proyecto. Actualizar con cada cambio importante.

## Estado actual (16/08/2026) — Fases 1 a 6 Completadas al 100%

- **Proyecto 100% Funcional por Script y Compilado con Rojo 7.7.0**.
- **Fase 1 (Atmósfera & Terror)**:
  - Iluminación nocturna inmersiva (`ShadowMap`, ClockTime 0.2, niebla de horror, post-procesado `ColorCorrectionEffect`, `BloomEffect`, `Atmosphere`).
  - Fluorescentes con parpadeo estocástico por caída de energía (`PowerService.luau`) y luces rojas de emergencia pulsantes en medianoche.
  - Balanceo de cámara dinámico (*Head Bobbing*) al caminar/correr (`CameraController.luau`).
- **Fase 2 (IA Inteligente del Monstruo con Pathfinding)**:
  - `MonsterService.luau` integrado con `PathfindingService:CreatePath()`.
  - Navegación realista que bordea estanterías y pasillos sin atravesar paredes.
  - Cono de visión (FOV 120° + Raycast) y rango de audición sensorial cuando el jugador corre cerca.
  - Audio espacial 3D en el torso del monstruo.
- **Fase 3 (Tareas & Circuito Cerrado CCTV)**:
  - 5 Tareas pulidas con feedback visual y auditivo.
  - Sistema de CCTV en la oficina de seguridad (`Task_CheckCamera`): interfaz retro interactiva para alternar cámaras (CAM 01 Pasillos, CAM 02 Cajas, CAM 03 Congeladores, CAM 04 Bodega) y vigilar al Cliente Cero en vivo.
- **Fase 4 (Mecánica Cooperativa Downed & Revive)**:
  - Estado `Downed` al ser alcanzado por el monstruo: cámara a ras del suelo, movimiento lento de arrastre, overlay de emergencia y temporizador de desangrado (45s).
  - Los compañeros de equipo pueden reanimarlo con `Remotes.RequestRevive` y reciben +25 Monedas y +40 XP.
- **Fase 5 (Sistema de Anomalías Paranormales)**:
  - `AnomalyService.luau`: Generación aleatoria por turno (Maniquí Errante, Gravedad Cero / Productos Flotantes, Desfase Temporal en Reloj de Pared, Sombra del Pasillo 0).
  - Pizarra de Deducción en la oficina de seguridad con modal interactivo para enviar sospechas y ganar bonificación x2 en resultados.
- **Fase 6 (Persistencia DataStore, Economía y Tienda)**:
  - `DataService.luau`: Gestión segura de perfiles de jugador con `DataStoreService` (Coins, XP, Nivel, Rondas Ganadas, Inventario, Upgrades).
  - Tienda de Empleados en el Lobby (tecla `B` o botón HUD) con skins de linterna (Neón Cyan, Táctico Rojo, UV) y mejoras pasivas (Zapatillas Ligeras, Batería de Litio).

---

## Entorno

- **Ubicación del proyecto bueno**: `C:\Users\user\firts_game_roblox` (FUERA de OneDrive).
- **Ubicación de respaldo**: `C:\Users\user\OneDrive\Desktop\firts_game_roblox` (sincronizada).
- **Build**: `rojo build -o firts_game_roblox.rbxlx` (dentro de `C:\Users\user\firts_game_roblox`).
- **Abrir el juego**: abrir `firts_game_roblox.rbxlx` en Roblox Studio.
- **Studio**: `RobloxStudioBeta.exe`.

## Reglas de Arquitectura
1. Todos los scripts del servidor residen en `src/server/` y se inicializan limpiamente en `init.server.luau`.
2. Módulos hermanos se referencian siempre con `require(script.Parent.Modulo)`.
3. Todos los remotes centralizados en `src/shared/Remotes.luau`.
4. Todos los parámetros de balance y configuración en `src/shared/GameConfig.luau`.
