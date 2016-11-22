AddCSLuaFile()

if CLIENT then
	include("cl_player_traits.lua")
end

-- pretty much perks

GM.Traits = {}
GM.TraitsById = {}
GM.TraitConvars = {}

function GM:registerTrait(data)
	self.Traits[data.convar] = self.Traits[data.convar] or {}
	self.TraitsById[data.id] = data
	
	local found = false
	
	for key, value in ipairs(self.TraitConvars) do
		if value == data.convar then
			found = true
			break
		end
	end
	
	if not found then
		self.TraitConvars[#self.TraitConvars + 1] = data.convar
	end
	
	table.insert(self.Traits[data.convar], data)

	if CLIENT then
		if not ConVarExists(data.convar) then
			CreateClientConVar(data.convar, 0, true, true)
		end
		
		local texture = data.texture
				
		if string.find(texture, "*.png") then
			data.material = Material(texture, "unlitgeneric noclamp")
			texture = data.material
		end
		
		data.textureID = surface.GetTextureID(texture)
	end
end

function GM:applyTraitToPlayer(ply, convar, traitID)
	local traitData = self.Traits[convar]
	
	if not traitData then
		return
	end
	
	traitData = traitData[traitID]
	
	if not traitData or not ply:hasTrait(traitData.id) then
		return
	end
	
	if traitData.onSpawn then
		traitData:onSpawn(ply, ply.traits[traitData.id])
	end
	
	table.insert(ply.currentTraits, {convar, traitID})
end

function GM:getTraitPrice(traitData, currentLevel)
	currentLevel = currentLevel or 0 
	return traitData.basePrice + currentLevel * traitData.pricePerLevel
end

local warHardened = {}
warHardened.display = "War hardened"
warHardened.id = "war_hardened"
warHardened.texture = "ground_control/traits/war_hardened"
warHardened.convar = "gc_trait"
warHardened.startLevel = 1
warHardened.maxLevel = 3
warHardened.basePrice = 1000
warHardened.pricePerLevel = 500
warHardened.adrenalinePerLevel = 0.05
warHardened.description = {
	{
		t = "You've undergone extensive training to operate efficiently in high stress situations.", 
		c = GM.HUDColors.white
	},
	{
		t = "Decreases adrenaline duration and increase speed by %s per each level.", 
		c = GM.HUDColors.green, 
		formatFunc = function(textToFormat) return string.format(textToFormat, warHardened.adrenalinePerLevel * 100 .. "%") end
	},
	{
		t = "Current adrenaline duration and increase speed reduction: -CURRENT%",
		c = GM.HUDColors.green,
		formatFunc = function(textToFormat) return string.easyformatbykeys(textToFormat, "CURRENT", math.Round(warHardened.adrenalinePerLevel * 100 * (LocalPlayer().traits[warHardened.id] or 0))) end
	}
}

function warHardened:onSpawn(player, currentLevel)
	local multiplierDecrease = currentLevel * self.adrenalinePerLevel
	player.adrenalineIncreaseMultiplier = 1 - multiplierDecrease
	player.maxAdrenalineDurationMultiplier = 1 - multiplierDecrease
end

function warHardened:remove(player, currentLevel)	
	player.adrenalineIncreaseMultiplier = 1
	player.maxAdrenalineDurationMultiplier = 1
end

GM:registerTrait(warHardened)

local conditioned = {}
conditioned.id = "conditioned"
conditioned.display = "Conditioned"
conditioned.texture = "ground_control/traits/conditioned"
conditioned.convar = "gc_trait"
conditioned.startLevel = 1
conditioned.maxLevel = 5
conditioned.basePrice = 750
conditioned.pricePerLevel = 250
conditioned.staminaDrainPerLevel = 0.05
conditioned.description = {
	{t = "You've undergone extensive physical preparation to become more endurant.", c = GM.HUDColors.white},
	{t = "Decreases stamina drain from sprinting by %s per each level.", c = GM.HUDColors.green, formatFunc = function(textToFormat) return string.format(textToFormat, conditioned.staminaDrainPerLevel * 100 .. "%") end},
	{
		t = "Current sprint stamina drain reduction: -CURRENT%",
		c = GM.HUDColors.green,
		formatFunc = function(textToFormat) return string.easyformatbykeys(textToFormat, "CURRENT", math.Round(conditioned.staminaDrainPerLevel * 100 * (LocalPlayer().traits[conditioned.id] or 0))) end
	}
}

function conditioned:onSpawn(player, currentLevel)
	player.staminaDrainMultiplier = 1 - currentLevel * self.staminaDrainPerLevel
end

function conditioned:remove(player, currentLevel)	
	player.staminaDrainMultiplier = 1
end

GM:registerTrait(conditioned)

local medic = {}
medic.id = "medic"
medic.display = "Medic"
medic.texture = "ground_control/traits/medic"
medic.convar = "gc_trait"
medic.startLevel = 1
medic.maxLevel = 5
medic.basePrice = 1000
medic.pricePerLevel = 500
medic.healthRestorePerLevel = 1
medic.description = {
	{t = "You've undergone extensive medical training to treat wounds efficiently.", c = GM.HUDColors.white},
	{t = "Allows to restore some health when bandaging self or team mates.", c = GM.HUDColors.white},
	{t = "Each level increases health restored by %s point.", c = GM.HUDColors.green, formatFunc = function(textToFormat) return string.format(textToFormat, medic.healthRestorePerLevel) end},
	{
		t = "Current health restore amount: +CURRENT%",
		c = GM.HUDColors.green,
		formatFunc = function(textToFormat) return string.easyformatbykeys(textToFormat, "CURRENT", math.Round(medic.healthRestorePerLevel * (LocalPlayer().traits[medic.id] or 0))) end
	}
}

function medic:onSpawn(player, currentLevel)
	player.healAmount = self.healthRestorePerLevel * currentLevel
end

function medic:remove(player, currentLevel)	
	player.healAmount = 0
end

GM:registerTrait(medic)

local willToLive = {}
willToLive.id = "will_to_live"
willToLive.display = "Will to Live"
willToLive.texture = "ground_control/traits/will_to_live"
willToLive.convar = "gc_trait"
willToLive.startLevel = 1
willToLive.maxLevel = 5
willToLive.basePrice = 1500
willToLive.pricePerLevel = 1500
willToLive.healthRestorePerLevel = 2
willToLive.healthRestoreDelay = 6 -- time in seconds between each HP regen tick
willToLive.healthRestoreDelayOnDamage = 10 -- delay to apply after taking damage
willToLive.description = {
	{t = "Your will to live is unmatched - you overcome pain and shock that would have had killed others.", c = GM.HUDColors.white},
	{t = "Allows to restore a small amount of health passively every %s seconds.", c = GM.HUDColors.green, formatFunc = function(textToFormat) return string.format(textToFormat, willToLive.healthRestoreDelay) end},
	{t = "Each level increases health restored by %s points.", c = GM.HUDColors.green, formatFunc = function(textToFormat) return string.format(textToFormat, willToLive.healthRestorePerLevel) end},
	{
		t = "Current maximum health restored: +CURRENT%",
		c = GM.HUDColors.green,
		formatFunc = function(textToFormat) return string.easyformatbykeys(textToFormat, "CURRENT", math.Round(willToLive.healthRestorePerLevel * (LocalPlayer().traits[willToLive.id] or 0))) end
	}
}

function willToLive:onSpawn(player, currentLevel)
	player.willToLiveHealthRestore = self.healthRestorePerLevel * currentLevel
	player.nextRegenTick = 0
end

function willToLive:remove(player)
	player.willToLiveHealthRestore = nil
	player.nextRegenTick = nil
end

function willToLive:think(player, curTime)
	-- can only regenerate health if there isn't any damage-related health to regenerate
	local hp = player:Health()
	
	if hp < player:GetMaxHealth() and player.regenPool == 0 and player.willToLiveHealthRestore > 0 and curTime > player.nextRegenTick then
		player.willToLiveHealthRestore = player.willToLiveHealthRestore - 1
		player.nextRegenTick = curTime + willToLive.healthRestoreDelay
		player:SetHealth(hp + 1)
	end
end

function willToLive:onTakeDamage(player, dmginfo, hitGroup)
	player.nextRegenTick = CurTime() + willToLive.healthRestoreDelayOnDamage
end

GM:registerTrait(willToLive)

local covertOps = {}
covertOps.id = "covert_ops"
covertOps.display = "Covert Ops"
covertOps.texture = "ground_control/traits/operative"
covertOps.convar = "gc_trait"
covertOps.startLevel = 1
covertOps.maxLevel = 10
covertOps.crouchSpeedPerLevel = 0.015
covertOps.basePrice = 500
covertOps.pricePerLevel = 1000

covertOps.description = {
	{t = "You've undergone extensive stealth training to sneak quicker while maintaining combat readiness.", c = GM.HUDColors.white},
	{t = "Increases crouched movement speed by %s%% per level.", c = GM.HUDColors.green, formatFunc = function(textToFormat) return string.format(textToFormat, math.Round(covertOps.crouchSpeedPerLevel * 100, 1)) end},
	{
		t = "Current crouch-move speed increase: +CURRENT%",
		c = GM.HUDColors.green,
		formatFunc = function(textToFormat) return string.easyformatbykeys(textToFormat, "CURRENT", math.Round(covertOps.crouchSpeedPerLevel * 100 * (LocalPlayer().traits[covertOps.id] or 0), 1)) end
	}
}

function covertOps:onSpawn(player, currentLevel)
	player:SetCrouchedWalkSpeed(GAMEMODE.CrouchedWalkSpeed + covertOps.crouchSpeedPerLevel * currentLevel)
end

GM:registerTrait(covertOps)

local PLAYER = FindMetaTable("Player")

function PLAYER:getTraitLevel(traitID)
	return self.traits[traitID]
end

function PLAYER:hasTrait(traitID)
	return self.traits[traitID] ~= nil
end

function PLAYER:resetTraitData()
	self.traits = {}
end