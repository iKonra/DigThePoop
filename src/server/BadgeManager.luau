-- BadgeManager.luau
-- Otorga emblemas a los jugadores

local BadgeService = game:GetService("BadgeService")
local BadgeManager = {}

-- ID del emblema de bienvenida
local FIRST_JOIN_BADGE_ID = 408471200039223

function BadgeManager.AwardFirstJoinBadge(player)
	if not player or not player:IsA("Player") then return end
	local success, hasBadge = pcall(function()
		return BadgeService:UserHasBadgeAsync(player.UserId, FIRST_JOIN_BADGE_ID)
	end)
	if success and not hasBadge then
		pcall(function()
			BadgeService:AwardBadge(player.UserId, FIRST_JOIN_BADGE_ID)
		end)
	end
end

-- ID del emblema de 10k poops
local TEN_K_POOPS_BADGE_ID = 1863324542434900

function BadgeManager.Award10kPoopsBadge(player)
	if not player or not player:IsA("Player") then return end
	local success, hasBadge = pcall(function()
		return BadgeService:UserHasBadgeAsync(player.UserId, TEN_K_POOPS_BADGE_ID)
	end)
	if success and not hasBadge then
		pcall(function()
			BadgeService:AwardBadge(player.UserId, TEN_K_POOPS_BADGE_ID)
		end)
	end
end

return BadgeManager
