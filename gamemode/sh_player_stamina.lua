AddCSLuaFile()

GM.MaxStamina = 100
GM.InitialStamina = 100
GM.StaminaDrainPerTick = 1 -- how much stamina we lose every stamina drain tick
GM.StaminaDrainTickTime = 0.75 -- how often we lose stamina when sprinting
GM.StaminaRegenTickTime = 0.35 -- how often we regenerate stamina when not sprinting
GM.PostDrainStaminaRegenTickDelay = 1 -- we have to wait this much after our stamina being drained
GM.StaminaRegenAmount = 1 -- how much stamina we regen when we're in idle state
GM.MinStaminaFromSprinting = 50 -- how far our stamina will drop from sprinting
GM.RunSpeedImpactStaminaLevel = 75 -- when our stamina value is lower than this, our run speed becomes impacted
GM.RunSpeedPerStaminaPoint = 1.5 -- we lose this much run speed per each point of stamina below the stamina impact level
GM.StaminaDecreasePerHealthPoint = 80 -- we lose this much max stamina by the time our health reaches 0

local PLAYER = FindMetaTable("Player")

function PLAYER:setStamina(amount, dontSend)
	if SERVER then
		self.stamina = math.Clamp(amount, 0, self:getMaxStamina())
	else
		self.stamina = amount
	end
	
	if SERVER then
		if not dontSend then
			self:sendStamina()
		end
	end
end

function PLAYER:resetStaminaData()
	self:setStamina(GAMEMODE.InitialStamina)
	self.staminaDrainTime = 0
	self.staminaRegenTime = 0
	self.staminaDrainMultiplier = 1
end

function PLAYER:sendStamina()
	umsg.Start("GC_STAMINA", self)
		umsg.Float(self.stamina)
	umsg.End()
end

function PLAYER:getStaminaRunSpeedModifier()
	local difference = GAMEMODE.RunSpeedImpactStaminaLevel - self.stamina
	local runSpeedImpact = math.max(difference, 0)
	
	return runSpeedImpact * GAMEMODE.RunSpeedPerStaminaPoint
end

function PLAYER:getMaxStaminaDecreaseFromHealth()
	return GAMEMODE.StaminaDecreasePerHealthPoint - self:Health() / self:GetMaxHealth() * GAMEMODE.StaminaDecreasePerHealthPoint
end

function PLAYER:getMaxStamina()
	return GAMEMODE.MaxStamina - self:getMaxStaminaDecreaseFromHealth()
end

if SERVER then
	umsg.PoolString("GC_STAMINA")
end