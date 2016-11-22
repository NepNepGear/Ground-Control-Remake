include("sh_player_adrenaline.lua")

GM.MaxAdrenalineMultiplier = 3
GM.AdrenalineIncreaseSpeedFadeOutSpeed = 0.75 -- speed at which the adrenaline's increase speed fades out
GM.AdrenalineFadeOutSpeed = 0.05 -- how much adrenaline to fade out when not being suppressed every second
GM.AdrenalineFadeInPerSec = 0.2 -- 0.2 is 20%, 1 is max
GM.MinimumSuppressionRange = 100
GM.StartingSuppressionRange = 80
GM.MaximumSuppressionRange = 220
GM.MaximumSuppressionDuration = 3 -- how long suppression can hold on it's own

local PLAYER = FindMetaTable("Player")

function PLAYER:suppress(duration, speedChange)
	local newDuration = CurTime() + duration
	
	self.adrenalineDuration = math.Clamp(self.adrenalineDuration + duration * self.adrenalineIncreaseMultiplier, 0, GAMEMODE.MaximumSuppressionDuration * self.maxAdrenalineDurationMultiplier)
	self.adrenalineSpeedHold = math.max(self.adrenalineDuration, newDuration)
	self.adrenalineIncreaseSpeed = math.Clamp(self.adrenalineSpeedHold + speedChange, 1, GAMEMODE.MaxAdrenalineMultiplier)
end

function PLAYER:increaseAdrenalineDuration(amountBy, max)
	max = max or GAMEMODE.MaximumSuppressionDuration
	max = math.max(max, self.adrenalineDuration)
	
	self.adrenalineDuration = math.Clamp(self.adrenalineDuration, 0, max)
end

if not FULL_INIT then
	if SERVER then
		CustomizableWeaponry.callbacks:addNew("bulletCallback", "GroundControl_bulletCallback", function(wep, ply, traceResult, dmgInfo)
			local rangeInMeters = wep.EffectiveRange / 39.37 -- convert back to meters
			local suppressionRange = math.Clamp(GAMEMODE.StartingSuppressionRange + rangeInMeters * 0.2, GAMEMODE.MinimumSuppressionRange, GAMEMODE.MaximumSuppressionRange)
			local suppressionSpeedChange = rangeInMeters * 0.0002
			local suppressionDuration = 0.1 + rangeInMeters * 0.0005 
			
			for key, object in pairs(ents.FindInSphere(traceResult.HitPos, suppressionRange)) do
				if object:IsPlayer() and object:Alive() and object:canSuppress(ply) then
					object:suppress(suppressionDuration, suppressionSpeedChange)
				end
			end
		end)
	end
end