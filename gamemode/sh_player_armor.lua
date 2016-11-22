--[[
	you can easily add more armor vests, along with things like helmets and leg armor
	the reason why I did not add helmets and leg armor is because, despite the game focusing a lot on realism/playing slowly, this is garry's mod, and noone plays this slowly
	so naturally I saw no reason to add super extensive armor options
	all you need to do is specify the cvar it should use, create that cvar on the client, specify the hitgroups which the armor should protect, and add some UI elements for the selection of the armor to the loadout menu
]]--

AddCSLuaFile()
AddCSLuaFile("cl_player_armor.lua")

GM.DefaultArmor = 1 -- 1 is dyneema vest by default

if CLIENT then
	include("cl_player_armor.lua")
	CreateClientConVar("gc_armor_vest", GM.DefaultArmor, true, true)
end

GM.Armor = {}
GM.ArmorById = {}

function GM:registerArmor(data)
	self.Armor[data.category] = self.Armor[data.category] or {}
	table.insert(self.Armor[data.category], data)
	
	self.ArmorById[data.category] = self.ArmorById[data.category] or {}
	self.ArmorById[data.category][data.id] = data
	
	if CLIENT then
		local string = data.icon
		data.icon = surface.GetTextureID(data.icon)
	end
end

function GM:getArmorData(armorId, category)
	return self.Armor[category][armorId]
end

function GM:prepareArmorPiece(ply, armorId, category)
	local armorPiece = self.Armor[category]
	
	if not armorPiece then
		return
	end
	
	armorPiece = armorPiece[armorId]
	
	if not armorPiece then
		return
	end
	
	local armorObject = {health = 100, id = armorId, category = category}
	table.insert(ply.armor, armorObject)
end

function GM:getArmorWeight(category, id)
	local data = self.Armor[category][id]
	
	return data and data.weight or 0
end

local dyneemaVest = {}
dyneemaVest.category = "vest"
dyneemaVest.id = "dyneema_vest"
dyneemaVest.displayName = "Dyneema Vest"
dyneemaVest.weight = 1.36 -- in KG
dyneemaVest.protection = 10 -- various-caliber weapons have different penetration values, if a weapon's penetration value exceeds a vest's protection value, then the armor vest is penetrated and the target starts bleeding (9x19mm, .45 and smaller calibers should be <10)
dyneemaVest.protectionAreas = {[HITGROUP_CHEST] = true, [HITGROUP_STOMACH] = true} -- hitgroups to protect
dyneemaVest.protectionDeltaToDamageDecrease = 0.01 -- in the event of no penetration, damage is scaled by additional (penetrationValue (weapon variable set in sh_loadout.lua) - protection) * protectionDeltaToDamageDecrease
-- ie if a weapon's penetration value is 6, and the vest's protection value is 10, then in addition to the 25% damage reduction (damageDecrease variable), an additional 4% ((10 - 6) * 0.01) will be added, totalling at 29%
dyneemaVest.damageDecrease = 0.25 -- percentage of damage to negate, in case of no penetration, (blunt trauma is a thing)
dyneemaVest.damageDecreasePenetration = 0.1 -- percentage of damage to negate, in case of penetration, consider not putting this above 20%
dyneemaVest.icon = "ground_control/hud/armor/aa_dyneema_vest"
dyneemaVest.description = "Provides type II protection against projectiles."

GM:registerArmor(dyneemaVest)

local kevlarVest = {}
kevlarVest.category = "vest"
kevlarVest.id = "kevlar_vest"
kevlarVest.displayName = "Kevlar Vest"
kevlarVest.weight = 2.27
kevlarVest.protection = 15 -- up to .44 magnum
kevlarVest.protectionAreas = {[HITGROUP_CHEST] = true, [HITGROUP_STOMACH] = true}
kevlarVest.damageDecrease = 0.275
kevlarVest.protectionDeltaToDamageDecrease = 0.008
kevlarVest.damageDecreasePenetration = 0.125
kevlarVest.icon = "ground_control/hud/armor/aa_kevlar_vest"
kevlarVest.description = "Provides type IIIA protection against projectiles."

GM:registerArmor(kevlarVest)

local spectraVest = {}
spectraVest.category = "vest"
spectraVest.id = "spectra_vest"
spectraVest.displayName = "SPECTRA Vest"
spectraVest.weight = 4.77
spectraVest.protection = 20 -- up to 7.62x51mm, should not stop a round fired from a L115 (.338 lapua magnum)
spectraVest.protectionAreas = {[HITGROUP_CHEST] = true, [HITGROUP_STOMACH] = true}
spectraVest.damageDecrease = 0.3
spectraVest.protectionDeltaToDamageDecrease = 0.015
spectraVest.damageDecreasePenetration = 0.15
spectraVest.icon = "ground_control/hud/armor/aa_spectra_vest"
spectraVest.description = "Provides type III protection against projectiles."

GM:registerArmor(spectraVest)

local PLAYER = FindMetaTable("Player")

function PLAYER:setArmor(armorData)
	if CLIENT then
		self:resetArmorData()
		
		for key, data in ipairs(armorData) do
			self:setupArmorPiece(data)
		end
	end
	
	self.armor = armorData
end

function PLAYER:resetArmorData()
	self.armor = self.armor or {}
	table.clear(self.armor)
end

function PLAYER:getDesiredVest()
	return tonumber(self:GetInfoNum("gc_armor_vest", 0))
end