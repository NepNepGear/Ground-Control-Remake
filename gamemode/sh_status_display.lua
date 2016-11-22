-- status effects don't affect the player, these are only used for displaying them on the HUD

AddCSLuaFile()
AddCSLuaFile("cl_status_display.lua")

GM.StatusEffects = {}
GM.ActiveStatusEffects = {}

function GM:registerStatusEffect(data)
	self.StatusEffects[data.id] = data
	
	if CLIENT then
		data.texture = surface.GetTextureID(data.icon)
	end
end

GM:registerStatusEffect({
	id = "bleeding",
	icon = "ground_control/hud/status/bleeding_icon",
	text = "BLEEDING"
})

GM:registerStatusEffect({
	id = "crippled_arm",
	icon = "ground_control/hud/status/crippled_arm",
	text = "CRIPPLED"
})

GM:registerStatusEffect({
	id = "healing",
	icon = "ground_control/hud/status/healing",
	text = "RECOVERY",
	dontSend = true
})

local PLAYER = FindMetaTable("Player")

-- set status effects for display on other players (not yourself), to see what's going on with your friends
function PLAYER:setStatusEffect(statusEffect, state) -- on other players
	-- numeric for rendering (clientside), map for quick checks
	self.statusEffects = self.statusEffects or {numeric = {}, map = {}}
	
	if not state then
		for key, otherStatusEffect in ipairs(self.statusEffects.numeric) do
			if otherStatusEffect == statusEffect then
				table.remove(self.statusEffects.numeric, key)
				break
			end
		end
		
		self.statusEffects.map[statusEffect] = nil
	else
		local present = false
		
		-- make sure this effect is not present yet
		if not self.statusEffects.map[statusEffect] then
			table.insert(self.statusEffects.numeric, statusEffect)
			self.statusEffects.map[statusEffect] = true
		end
	end
	
	if SERVER then
		self:sendStatusEffect(statusEffect, state)
	end
end

function PLAYER:resetStatusEffects() -- on other players
	if not self.statusEffects then
		return
	end
	
	table.Empty(self.statusEffects.numeric)
	table.Empty(self.statusEffects.map)
end

function PLAYER:hasStatusEffect(statusEffect)
	return self.statusEffects and self.statusEffects.map[statusEffect]
end

if SERVER then
	util.AddNetworkString("GC_STATUS_EFFECT_ON_PLAYER")
end