AddCSLuaFile()

-- adrenaline and suppression is the same thing in Ground Control
-- gameplay-wise it increases when enemy bullets hit nearby surfaces,
-- it's effects are increased run speed and hip fire accuracy at the expense of a shaking view when taking aim and lower aim accuracy

GM.MaxSpeedIncreaseFromAdrenaline = 0.1 -- max additional units/sec we can achieve from adrenaline
GM.AdrenalineStaminaDrainModifier = 0.5 -- our stamina drain decrease from sprinting will be multiplied by this value depending on our adrenaline level (ie. with this value at 0.5: 100% adrenaline = 50% less stamina drained from sprinting, 0% adrenaline = 0% less stamina drain)
GM.AdrenalineStaminaRegenModifier = 0.1 -- same as with draining, but for regeneration
GM.HipFireAccuracyAdrenalineModifier = -0.3 -- when adrenaline reaches 100%, our hip fire accuracy should increase by this much; this value should be negative to increase hip fire accuracy
GM.AimFireAccuracyAdrenalineModifier = 0.3 -- when adrenaline reaches 100%, our aim accuracy should decrease by this much; this value should be positive to increase aim fire spread

local PLAYER = FindMetaTable("Player")

function PLAYER:setAdrenaline(amount)
	self.adrenaline = math.Clamp(amount, 0, 1)
	
	if SERVER then
		umsg.Start("GC_ADRENALINE", self)
			umsg.Float(self.adrenaline)
		umsg.End()
	end
end

if SERVER then
	umsg.PoolString("GC_ADRENALINE")
end

function PLAYER:canSuppress(suppressedBy)
	return self:Alive() and self:Team() ~= suppressedBy:Team()
end

function PLAYER:resetAdrenalineData()
	if SERVER then
		self:setAdrenaline(0)
		self.adrenalineDuration = 0
		self.adrenalineSpeedHold = 0
		self.adrenalineIncreaseSpeed = 0
		self.adrenalineIncreaseMultiplier = 1
		self.maxAdrenalineDurationMultiplier = 1
	end
	
	self.adrenaline = 0
end

function PLAYER:getRunSpeedAdrenalineModifier()
	return self.adrenaline * GAMEMODE.MaxSpeedIncreaseFromAdrenaline
end

function PLAYER:getStaminaDrainAdrenalineModifier()
	return 1 - self.adrenaline * GAMEMODE.AdrenalineStaminaDrainModifier
end

function PLAYER:getStaminaRegenAdrenalineModifier()
	return 1 + self.adrenaline * GAMEMODE.AdrenalineStaminaRegenModifier
end

function PLAYER:getAdrenalineAccuracyModifiers()
	return 1 + GAMEMODE.HipFireAccuracyAdrenalineModifier * self.adrenaline, 1+ GAMEMODE.AimFireAccuracyAdrenalineModifier
end

AddCSLuaFile("cl_player_adrenaline.lua")