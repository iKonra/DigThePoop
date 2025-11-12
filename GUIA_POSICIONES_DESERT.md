# Guía de Posiciones en Desert Zone

Esta guía te muestra exactamente qué líneas de código modificar para cambiar posiciones de objetos y zonas de interacción en el Desert Zone.

---

## 📍 POSICIONES DE MODELOS EN DESERT

### 1. **Centro del Spawn del Desert**
**Archivo:** `src/server/SpawnDecorator.luau`
**Línea:** `237`
```lua
local desertSpawnCenter = Vector3.new(4000, 74, 0)
```
- **X = 4000**: Posición horizontal (derecha/izquierda)
- **Y = 74**: Altura
- **Z = 0**: Posición de profundidad (adelante/atrás)

---

### 2. **Offset de Altura General** (Bonfire, Logs, Rock Floor)
**Archivo:** `src/server/SpawnDecorator.luau`
**Línea:** `245`
```lua
heightOffset = -8,  -- Bajar 8 studs (bonfire, logs subidos 2 desde -10)
```
- Cambia este valor para subir/bajar todos los elementos decorativos juntos
- **Negativo** = más abajo, **Positivo** = más arriba

---

### 3. **Posición del SHOP en Desert**
**Archivo:** `src/server/SpawnDecorator.luau`
**Línea:** `203`
```lua
local shopPosition = spawnCenter + Vector3.new(53, heightOffset + 5, -5)
```
- **X = +53**: 53 studs a la derecha del centro (4000+53 = 4053)
- **Y = heightOffset + 5**: Altura relativa (74 - 8 + 5 = 71)
- **Z = -5**: 5 studs hacia atrás

**IMPORTANTE:** Esta posición también está documentada en `ZoneManager.luau` línea 41:
```lua
shopPosition = Vector3.new(4053, 71, -5)
```

---

### 4. **Posición del EXCHANGER (Poop Changer) en Desert**
**Archivo:** `src/server/SpawnDecorator.luau`
**Línea:** `214`
```lua
local exchangerPosition = spawnCenter + Vector3.new(25, heightOffset + 1, 8)
```
- **X = +25**: 25 studs a la derecha del centro (4000+25 = 4025)
- **Y = heightOffset + 1**: Altura relativa (74 - 8 + 1 = 67)
- **Z = +8**: 8 studs hacia adelante

**IMPORTANTE:** Esta posición también está documentada en `ZoneManager.luau` línea 42:
```lua
poopChangerPosition = Vector3.new(4027, 67, 8)
```

---

## 🎯 ZONAS DE INTERACCIÓN EN DESERT

### 1. **Zona de Interacción del SHOP**
**Archivo:** `src/server/ShopManager.luau`
**Línea:** `1090`
```lua
interactionPart.Position = position + Vector3.new(0, 4 * SHOP_SCALE, -6 * SHOP_SCALE)
```
- **SHOP_SCALE = 2** (línea 16 del mismo archivo)
- La zona de interacción está en: `shopPosition + Vector3.new(0, 8, -12)`
- Para moverla:
  - **X**: Cambiar el primer valor (0)
  - **Y**: Cambiar `4 * SHOP_SCALE` (actualmente 8 studs arriba)
  - **Z**: Cambiar `-6 * SHOP_SCALE` (actualmente 12 studs atrás)

**Tamaño de la zona:**
**Línea:** `1089`
```lua
interactionPart.Size = Vector3.new(8, 8, 8) * SHOP_SCALE
```
- Actualmente: 16x16x16 studs

---

### 2. **Zona de Interacción del EXCHANGER**
**Archivo:** `src/server/PoopChangerBooth.luau`
**Línea:** `365`
```lua
sellPart.Position = position + Vector3.new(0, 4 * BOOTH_SCALE, -3 * BOOTH_SCALE)
```
- **BOOTH_SCALE = 1.8** (línea 16 del mismo archivo)
- La zona de interacción está en: `exchangerPosition + Vector3.new(0, 7.2, -5.4)`
- Para moverla:
  - **X**: Cambiar el primer valor (0)
  - **Y**: Cambiar `4 * BOOTH_SCALE` (actualmente 7.2 studs arriba)
  - **Z**: Cambiar `-3 * BOOTH_SCALE` (actualmente 5.4 studs atrás)

**Tamaño de la zona:**
**Línea:** `364`
```lua
sellPart.Size = Vector3.new(6, 8, 6) * BOOTH_SCALE
```
- Actualmente: 10.8x14.4x10.8 studs

---

## 📋 CONFIGURACIÓN DE LA ZONA EN ZONEMANAGER

**Archivo:** `src/server/ZoneManager.luau`
**Líneas:** `32-46`

```lua
{
    name = "Desert",
    displayName = "Desert Zone",
    description = "A sandy wasteland with golden poops",
    icon = "🏜️",
    cost = 1000000, -- 1 million coins
    position = Vector3.new(4000, -10, 0), -- Centro de la zona (para generación de terreno)
    size = Vector3.new(800, 0, 800), -- Tamaño de la zona (800x800)
    spawnPoint = Vector3.new(4000, 74, 0), -- Donde se teletransportan los jugadores
    shopPosition = Vector3.new(4053, 71, -5), -- Posición del shop (REFERENCIA)
    poopChangerPosition = Vector3.new(4027, 67, 8), -- Posición del exchanger (REFERENCIA)
    poopType = "golden", -- Tipo de poops que spawnenan
    poopMultiplier = 10, -- Multiplicador de valor x10
    unlocked = false -- Necesita ser comprada
}
```

**NOTA:** Las líneas 41-42 son solo referencias. Las posiciones reales se configuran en `SpawnDecorator.luau`.

---

## 🎮 EJEMPLO RÁPIDO: Mover el Shop 10 studs a la izquierda

1. **Ir a:** `src/server/SpawnDecorator.luau` línea 203
2. **Cambiar:**
   ```lua
   -- ANTES:
   local shopPosition = spawnCenter + Vector3.new(53, heightOffset + 5, -5)

   -- DESPUÉS:
   local shopPosition = spawnCenter + Vector3.new(43, heightOffset + 5, -5)
   ```
   (53 - 10 = 43)

3. **Actualizar referencia en:** `src/server/ZoneManager.luau` línea 41
   ```lua
   -- ANTES:
   shopPosition = Vector3.new(4053, 71, -5)

   -- DESPUÉS:
   shopPosition = Vector3.new(4043, 71, -5)
   ```
   (4053 - 10 = 4043)

---

## 📊 RESUMEN DE ARCHIVOS CLAVE

| Archivo | Qué contiene |
|---------|-------------|
| `src/server/SpawnDecorator.luau` | Posiciones REALES de shop, exchanger, decoraciones |
| `src/server/ZoneManager.luau` | Configuración de zona, referencias de posiciones |
| `src/server/ShopManager.luau` | Zona de interacción del shop |
| `src/server/PoopChangerBooth.luau` | Zona de interacción del exchanger |

---

## ⚠️ IMPORTANTE

Cuando modifiques posiciones:
1. **Siempre modifica las posiciones reales en `SpawnDecorator.luau` primero**
2. **Actualiza las referencias en `ZoneManager.luau` para que coincidan**
3. **Si mueves el modelo, considera mover también la zona de interacción**
4. **Recuerda que las posiciones son RELATIVAS al centro del spawn**

---

**Última actualización:** 2025-01-24
