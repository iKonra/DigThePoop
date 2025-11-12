-- src/client/MonetizationClient.client.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

-- Lo crea ShopManager o MonetizationManager en el server
-- Wait for the server to create the remote (block until available)
local PromptPassPurchaseEvent = ReplicatedStorage:WaitForChild("PromptPassPurchaseEvent")

-- Abre el prompt de GamePass cuando el server lo pida
if PromptPassPurchaseEvent and PromptPassPurchaseEvent.OnClientEvent then
	PromptPassPurchaseEvent.OnClientEvent:Connect(function(passId)
		if typeof(passId) == "number" then
			MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, passId)
		end
	end)
else
	warn("PromptPassPurchaseEvent not available in ReplicatedStorage")
end

-- (Opcional) Notificar al server cuando el usuario compró
local GamePassPurchasedEvent = ReplicatedStorage:FindFirstChild("GamePassPurchasedEvent")
if GamePassPurchasedEvent then
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if player == Players.LocalPlayer and purchased then
			GamePassPurchasedEvent:FireServer(passId)
		end
	end)
end
