# Guía del Sistema de Pets

Basado en: https://devforum.roblox.com/t/pet-system-open-source-how-to-make-your-own-look-at-new-version/3118849

---

## 📋 Resumen del Sistema

El sistema de pets permitirá:
- **Obtener pets** de los **eggs** que descubres con el shovel
- **Equipar hasta 3 pets** que te siguen
- **Pets dan bonuses** (ej: +10% coins, +5% luck, x2 poop multiplier)
- **Raridades**: Common, Uncommon, Rare, Epic, Legendary
- **Inventario** de pets ilimitado
- **GUI** para ver, equipar y gestionar pets

---

## 🥚 Integración con el Shovel (Egg Discovery)

### Cómo funcionaría:

1. **Cuando excavas poop**, tienes % de chance de encontrar un **Golden Egg**
2. **El Golden Egg aparece** flotando donde cavaste
3. **Lo recoges** y abre automáticamente
4. **Sale un pet aleatorio** basado en raridades

### Configuración de Eggs:

```lua
local EGGS = {
	{
		name = "Basic Egg",
		icon = "🥚",
		hatchChance = 5, -- 5% chance al excavar poop
		pets = {
			{name = "Dog", rarity = "Common", bonus = {coins = 10}},
			{name = "Cat", rarity = "Common", bonus = {luck = 5}},
			{name = "Rabbit", rarity = "Uncommon", bonus = {speed = 15}},
			{name = "Fox", rarity = "Rare", bonus = {poopMultiplier = 1.5}},
			{name = "Dragon", rarity = "Legendary", bonus = {poopMultiplier = 3}}
		}
	}
}
```

---

## 🐾 Estructura del Sistema de Pets

### 1. **PetManager.luau** (Servidor)
- Guarda qué pets tiene cada jugador
- Equipar/desequipar pets
- Calcular bonuses totales
- Generar pets de eggs

### 2. **PetInventoryGui** (Cliente)
- Mostrar inventario de pets
- Botón para equipar/desequipar
- Ver stats de cada pet
- Ordenar por raridad

### 3. **PetFollowSystem** (Cliente)
- Hacer que los pets sigan al jugador
- Animaciones de movimiento
- Floating/bobbing effect
- Múltiples pets en formación

### 4. **EggHatchSystem** (Ambos)
- Animación de hatching
- Efecto de partículas
- Reveal del pet con raridad
- Guardar en inventario

---

## 🎯 Implementación Recomendada

### Fase 1: Sistema Básico
1. Crear estructura de datos de pets
2. Guardar/cargar pets en DataStore
3. Equipar hasta 3 pets
4. Pets siguen al jugador (básico)

### Fase 2: Eggs y Hatching
5. Chance de encontrar eggs al excavar
6. Animación de hatching
7. Sistema de raridades
8. Efectos visuales

### Fase 3: Bonuses y GUI
9. Calcular bonuses de pets equipados
10. Aplicar bonuses al gameplay
11. GUI de inventario completo
12. Trading de pets (opcional)

---

## 💎 Raridades Sugeridas

```lua
local RARITIES = {
	Common = {
		weight = 60,      -- 60% chance
		color = Color3.fromRGB(200, 200, 200),
		bonusRange = {5, 15}
	},
	Uncommon = {
		weight = 25,      -- 25% chance
		color = Color3.fromRGB(100, 255, 100),
		bonusRange = {15, 30}
	},
	Rare = {
		weight = 10,      -- 10% chance
		color = Color3.fromRGB(100, 150, 255),
		bonusRange = {30, 50}
	},
	Epic = {
		weight = 4,       -- 4% chance
		color = Color3.fromRGB(200, 100, 255),
		bonusRange = {50, 100}
	},
	Legendary = {
		weight = 1,       -- 1% chance
		color = Color3.fromRGB(255, 215, 0),
		bonusRange = {100, 200}
	}
}
```

---

## 🔧 Código Base del Sistema

### PetData Structure:
```lua
PlayerPetData = {
	ownedPets = {
		{id = "pet_001", name = "Dog", rarity = "Common", equipped = true, bonus = {coins = 10}},
		{id = "pet_002", name = "Cat", rarity = "Uncommon", equipped = false, bonus = {luck = 15}},
		...
	},
	equippedPets = {"pet_001", "pet_003", "pet_005"} -- Max 3
}
```

### Follow Algorithm (Simple):
```lua
function followPlayer(pet, player)
	local humanoidRootPart = player.Character.HumanoidRootPart
	local offset = Vector3.new(3, 0, -3) -- Offset from player

	while pet.Parent do
		local targetPos = humanoidRootPart.CFrame * CFrame.new(offset)
		pet.CFrame = pet.CFrame:Lerp(targetPos, 0.1) -- Smooth follow
		task.wait()
	end
end
```

---

## 🎨 Pets Sugeridos

### Common (60%):
- 🐕 Dog - +10% Coins
- 🐈 Cat - +5% Luck
- 🐇 Rabbit - +10% Speed

### Uncommon (25%):
- 🦊 Fox - +20% Coins
- 🐸 Frog - +15% Luck
- 🐢 Turtle - +10% Poop Multiplier

### Rare (10%):
- 🦁 Lion - +30% Coins
- 🦅 Eagle - +25% Luck
- 🦄 Unicorn - +1.5x Poop Multiplier

### Epic (4%):
- 🐉 Dragon - +50% Coins
- 🦖 T-Rex - +2x Poop Multiplier
- 👻 Ghost - +40% Luck

### Legendary (1%):
- 🌟 Star Beast - +100% Coins + +50% Luck
- 💎 Diamond Pet - +3x Poop Multiplier
- 🔥 Phoenix - +75% Coins + +2x Multiplier

---

## 📦 Archivos a Crear

```
src/
├── server/
│   ├── PetManager.luau          (Sistema principal)
│   ├── EggHatchServer.luau      (Lógica de eggs)
│   └── PetBonusCalculator.luau  (Calcular bonuses)
├── client/
│   ├── PetFollowSystem.luau     (Hacer que sigan)
│   ├── PetInventoryGui.luau     (GUI de inventario)
│   └── EggHatchAnimation.luau   (Animaciones)
└── shared/
    └── PetData.luau              (Configuración de pets)
```

---

## 🚀 Próximos Pasos

1. **¿Quieres que implemente el sistema completo de pets?**
   - Sistema de seguimiento
   - Eggs del shovel
   - Inventario GUI
   - Bonuses aplicados

2. **¿O prefieres empezar simple?**
   - Solo 1 pet equipado
   - Eggs básicos
   - Sin GUI compleja

---

## 💡 Ideas Adicionales

- **Pet Trading**: Intercambiar pets con otros jugadores
- **Pet Evolution**: Combinar 3 del mismo para evolucionarlo
- **Pet Abilities**: Habilidades especiales (ej: auto-recoger poops cercanas)
- **Pet Cosmetics**: Hats, colores custom
- **Pet Shiny**: Versión shiny 1/1000 chance (doble bonuses)

---

¿Quieres que empiece a implementar el sistema de pets ahora?
