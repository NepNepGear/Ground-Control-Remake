AddCSLuaFile("cl_player_traits.lua")
include("sh_player_traits.lua")

util.AddNetworkString("GC_TRAITS")

local PLAYER = FindMetaTable("Player")

function PLAYER:applyTraits()
	self:removeTraits()
	
	for key, convar in ipairs(GAMEMODE.TraitConvars) do
		local desiredTrait = self:GetInfoNum(convar, "0")
		
		if desiredTrait then
			desiredTrait = tonumber(desiredTrait)
			
			GAMEMODE:applyTraitToPlayer(self, convar, desiredTrait)
		end
	end
end

function PLAYER:removeTraits()
	local traits = GAMEMODE.Traits
	
	for key, traitConfig in ipairs(self.currentTraits) do
		local traitData = traits[traitConfig[1]][traitConfig[2]]
		
		if traitData.remove then
			traitData:remove(self, self.traits[traitData.id])
		end
		
		self.currentTraits[key] = nil
	end
end

function PLAYER:loadTraits()
	local traitData = self:GetPData("GC_TRAITS")
	
	if traitData then
		traitData = util.JSONToTable(traitData)
	else
		traitData = {}
	end
	
	self.traits = traitData
end

function PLAYER:saveTraits()
	local traitData = util.TableToJSON(self.traits)
	self:SetPData("GC_TRAITS", traitData)
end

function PLAYER:unlockTrait(traitID)
	local traitData = GAMEMODE.TraitsById[traitID]
	
	if not traitData then
		return
	end
	
	local requiredCash = GAMEMODE:getTraitPrice(traitData, 0)
	
	if self.cash < requiredCash then
		return
	end
	
	self:setTraitLevel(traitData.id, 1)
	self:removeCash(requiredCash)
end

function PLAYER:progressTrait(traitID)
	local traitLevel = self.traits[traitID]
	
	if not traitLevel then
		return
	end
	
	local traitData = GAMEMODE.TraitsById[traitID]
	
	if not traitData or traitLevel >= traitData.maxLevel then
		return
	end
	
	local requiredCash = GAMEMODE:getTraitPrice(traitData, traitLevel)

	if self.cash < requiredCash then
		return
	end
	
	self:setTraitLevel(traitData.id, traitLevel + 1)
	self:removeCash(requiredCash)
end

function PLAYER:setTraitLevel(trait, level)
	self.traits[trait] = level
	self:saveTraits()
	self:sendTraits()
end

function PLAYER:sendTraits()
	net.Start("GC_TRAITS")
		net.WriteTable(self.traits)
	net.Send(self)
end

concommand.Add("gc_buy_trait", function(ply, com, args)
	local targetTrait = args[1]
	
	if not targetTrait then
		return
	end
	
	if not ply:hasTrait(targetTrait) then
		ply:unlockTrait(targetTrait)
	else
		ply:progressTrait(targetTrait)
	end
end)