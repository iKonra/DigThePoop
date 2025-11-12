# Cómo Configurar el Starter Pack

El Starter Pack está implementado y listo para usar. Solo necesitas crear el Developer Product en Roblox y configurar el ID.

---

## Paso 1: Crear el Developer Product

1. Ve a https://create.roblox.com/creations
2. Selecciona tu juego
3. Ve a **"Monetization"** > **"Developer Products"**
4. Click en **"CREATE A DEVELOPER PRODUCT"**
5. Configura el producto:
   - **Name:** Starter Pack
   - **Description:** Get 2000 Coins + 5 Levels in all Upgrades!
   - **Price:** 79 Robux
   - **Icon:** (Opcional) Sube una imagen

6. Click **"CREATE DEVELOPER PRODUCT"**
7. **COPIA EL PRODUCT ID** que aparece en la lista

---

## Paso 2: Configurar el Product ID en tu código

1. Abre el archivo: `src/server/StarterPackOffer.luau`

2. En la línea 14, reemplaza el `0` con tu Product ID:

```lua
-- ANTES:
local STARTER_PACK_PRODUCT_ID = 0

-- DESPUÉS (ejemplo con ID 123456789):
local STARTER_PACK_PRODUCT_ID = 123456789
```

3. Guarda el archivo

---

## Paso 3: Publica tu juego

El Starter Pack solo funcionará cuando:
- El juego esté **publicado** en Roblox
- No funciona en Studio (pero mostrará el popup y dará los items gratis para testing)

---

## ✅ Cómo Funciona

### Cuando un jugador entra:
1. **5 segundos después** de unirse, verá el popup del Starter Pack
2. El popup muestra:
   - ⭐ STARTER PACK ⭐
   - 💰 2,000 COINS
   - ⚡ +5 LEVELS ALL UPGRADES
   - Botón "BUY NOW - 79 ROBUX"
   - Botón "Maybe Later"

### Cuando compran:
1. Se abre el prompt de compra de Roblox
2. Si completan la compra, reciben automáticamente:
   - **2000 Coins** agregados a su saldo
   - **+5 niveles** en cada upgrade (Capacity, Speed, Multiplier, Luck)
   - Mensaje de éxito en pantalla

### Solo se puede comprar UNA VEZ por jugador

---

## 🧪 Testing en Studio

En Studio, cuando un jugador hace click en "BUY NOW":
- ⚠️ NO se cobrará dinero (Studio mode)
- ✅ El jugador recibirá los items GRATIS
- ✅ Puedes probar que todo funcione correctamente

---

## 💰 Cuánto ganarás

Con el precio de 79 Robux:
- Roblox se queda con ~30%
- Tú recibes ~55 Robux por venta
- Si 100 jugadores compran = 5,500 Robux

---

## 🛠️ Personalización

Si quieres cambiar las recompensas, edita en `StarterPackOffer.luau` (líneas 17-21):

```lua
local STARTER_PACK_REWARDS = {
	Coins = 2000,              -- Cambia la cantidad de coins
	UpgradeLevels = 5,         -- Cambia los niveles
	Upgrades = {"PoopCapacity", "WalkSpeed", "PoopMultiplier", "Luck"}
}
```

Si quieres cambiar el precio, edita la línea 15:

```lua
local STARTER_PACK_PRICE = 79 -- Cambia el precio en Robux
```

**IMPORTANTE:** Si cambias el precio aquí, también cámbialo en el Developer Product en Roblox.

---

## ❓ Problemas Comunes

**El popup no aparece:**
- Verifica que `StarterPackOffer.Setup()` esté en `init.server.luau`
- Verifica que los RemoteEvents se crearon correctamente

**La compra no funciona:**
- Asegúrate de haber configurado el PRODUCT_ID correcto
- Asegúrate de que el juego esté publicado (no funciona en Studio para compras reales)

**Los items no se entregan:**
- Verifica que el jugador tenga `leaderstats` y `Upgrades` folder
- Revisa la consola del servidor para mensajes de error

---

## 📊 Monitoreo de Ventas

Puedes ver las ventas en:
1. https://create.roblox.com/creations
2. Selecciona tu juego
3. **"Analytics"** > **"Economy"** > **"Developer Products"**

---

**¡Listo!** Tu Starter Pack está configurado y funcionando.
