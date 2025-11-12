# Estructura del Proyecto Agarrini

Este documento describe la organización modular del código del servidor.

## 📁 Estructura de Archivos

```
src/server/
├── init.server.luau          # Script principal que orquesta todos los módulos
├── Config.luau                # Configuración central del juego
├── TerrainManager.luau        # Generación del terreno
├── SpawnDecorator.luau        # Decoración del área de spawn
├── CastleWalls.luau           # Construcción de las murallas del castillo
├── PoopManager.luau           # Sistema de spawneo y limpieza de poops
├── RebirthManager.luau        # Sistema de rebirths y mejoras
├── ShovelManager.luau         # Sistema de palas (creación, pickup, etc.)
└── PlayerManager.luau         # Gestión de jugadores y leaderstats
```

## 📝 Descripción de Módulos

### `Config.luau`
**Propósito**: Almacena todas las constantes y configuraciones del juego.

**Contiene**:
- Configuración del terreno (tamaño, alturas, etc.)
- Configuración de las murallas del castillo
- Configuración de spawneo de poops
- Tipos de Super Poops (Neon, Gold, Ruby, Diamond, Rainbow)
- Niveles de Rebirth
- Configuración de mascotas y huevos
- Configuración del jugador

**Por qué es útil**: Centralizar la configuración permite ajustar parámetros fácilmente sin buscar valores en múltiples archivos.

---

### `TerrainManager.luau`
**Propósito**: Maneja toda la lógica de generación del terreno.

**Funciones exportadas**:
- `GenerateTerrain()` - Genera el terreno con variaciones naturales
- `GetTerrainHeightAtPosition(worldX, worldZ)` - Obtiene la altura del terreno en una posición
- `IsInSpawnArea(x, z)` - Verifica si una posición está en el área de spawn

**Por qué es útil**: Encapsula toda la lógica de terreno, haciéndola reutilizable por otros módulos (como PoopManager).

---

### `SpawnDecorator.luau`
**Propósito**: Decora el área de spawn con fogata, troncos para sentarse, y el piso de roca.

**Funciones exportadas**:
- `Decorate()` - Crea toda la decoración del spawn

**Por qué es útil**: Separa la lógica de decoración de la generación del terreno, manteniendo cada sistema independiente.

---

### `CastleWalls.luau`
**Propósito**: Construye las murallas del castillo alrededor del mapa.

**Funciones exportadas**:
- `Build()` - Construye las murallas, almenas y torres

**Por qué es útil**: Aisla la lógica de construcción de las murallas en un módulo dedicado.

---

### `PoopManager.luau`
**Propósito**: Sistema completo de gestión de poops (normales y super poops).

**Funciones exportadas**:
- `StartSpawner()` - Inicia el sistema de spawneo de poops
- `SetupClearingHandler()` - Configura el handler para limpiar poops
- `GetPoopMultiplier(player)` - Obtiene el multiplicador de poops de un jugador

**Características**:
- Spawneo inicial y continuo de poops
- Sistema de Super Poops con diferentes rarezas
- Sistema de lucky chances (1000x, 100x, 50x, etc.)
- Validación anti-exploit (distancia, permisos)

**Por qué es útil**: Agrupa toda la lógica de poops en un solo lugar, facilitando ajustes y debugging.

---

### `RebirthManager.luau`
**Propósito**: Sistema de rebirths con mejoras visuales y de estadísticas.

**Funciones exportadas**:
- `SetupRebirthHandler()` - Configura el handler de rebirths
- `ApplySpeedBoost(player)` - Aplica el boost de velocidad
- `ApplyPlayerEffects(player)` - Aplica efectos visuales (auras, trails, sparkles)

**Características**:
- 5 niveles de rebirth
- Multiplicadores de poops
- Boosts de velocidad
- Efectos visuales progresivos
- Efecto rainbow animado para Rebirth V

**Por qué es útil**: Centraliza toda la lógica de rebirths, incluyendo validaciones y efectos visuales.

---

### `ShovelManager.luau`
**Propósito**: Sistema completo de palas (creación, pickup, distribución).

**Funciones exportadas**:
- `CreateShovelTool()` - Crea una herramienta de pala funcional
- `GiveShovelToPlayer(player)` - Da una pala a un jugador específico
- `CreatePickableShovel()` - Crea una pala recogible en el spawn

**Características**:
- Soporte para modelos personalizados del workspace
- Sistema de pickup con ProximityPrompt
- Animaciones (flotación y rotación)
- Respawn automático después de ser recogida

**Por qué es útil**: Separa toda la lógica compleja de la pala en un módulo dedicado.

---

### `PlayerManager.luau`
**Propósito**: Gestión del ciclo de vida de jugadores.

**Funciones exportadas**:
- `SetupPlayers()` - Configura jugadores existentes y nuevos

**Características**:
- Creación de leaderstats
- Aplicación automática de efectos de rebirth al spawn/respawn
- Manejo de jugadores que se unen durante el juego

**Por qué es útil**: Centraliza la lógica de setup de jugadores y sus estadísticas.

---

### `init.server.luau`
**Propósito**: Script principal que orquesta todo el sistema.

**Fases de inicialización**:
1. **WORLD GENERATION**: Terreno, spawn, murallas
2. **GAME SYSTEMS**: Poops, rebirths, shovel
3. **PLAYER MANAGEMENT**: Setup de jugadores

**Por qué es útil**: Provee un punto de entrada claro y organizado, mostrando el flujo de inicialización.

---

## 🔄 Flujo de Inicialización

```
1. init.server.luau carga todos los módulos
2. Se genera el mundo (terreno → decoración → murallas)
3. Se inicializan los sistemas de juego (poops → rebirths → shovel)
4. Se configuran los jugadores (leaderstats → efectos)
5. ✅ Juego listo para jugar
```

## ⚙️ Ventajas de esta Estructura

### ✅ Modularidad
Cada sistema está en su propio archivo, facilitando el mantenimiento.

### ✅ Reutilizabilidad
Los módulos se pueden reutilizar (ej: `TerrainManager` es usado por `PoopManager`).

### ✅ Facilidad de Testing
Puedes probar cada módulo individualmente.

### ✅ Colaboración
Diferentes desarrolladores pueden trabajar en diferentes módulos sin conflictos.

### ✅ Escalabilidad
Es fácil agregar nuevos sistemas creando nuevos módulos.

### ✅ Configuración Centralizada
Todos los valores ajustables están en `Config.luau`.

### ✅ Claridad
El código es más fácil de entender y navegar.

## 🔧 Cómo Agregar un Nuevo Sistema

1. Crea un nuevo archivo `.luau` en `src/server/`
2. Define tu módulo:
   ```lua
   local MiNuevoSistema = {}

   local Config = require(script.Parent.Config)

   function MiNuevoSistema.Inicializar()
       -- Tu código aquí
   end

   return MiNuevoSistema
   ```
3. Importa y usa en `init.server.luau`:
   ```lua
   local MiNuevoSistema = require(script.MiNuevoSistema)
   MiNuevoSistema.Inicializar()
   ```
4. Si necesitas configuración, agrégala a `Config.luau`

## 🎯 Próximos Pasos Sugeridos

- [ ] Agregar sistema de datastore para persistencia
- [ ] Crear módulo de pets separado
- [ ] Agregar sistema de achievements
- [ ] Crear módulo de UI/GUI
- [ ] Implementar sistema de eventos temporales

---

**Última actualización**: 2025-10-20
