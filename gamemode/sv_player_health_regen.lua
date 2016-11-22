local PLAYER = FindMetaTable("Player")

GM.HealthRegenTickDelay = 5 -- time in seconds between regenerating a single point of health

function PLAYER:resetHealthRegenData()
	self.regenPool = 0
	self.regenDelay = 0
	self.sentHPRegenHint = false
	
	self:setStatusEffect("healing", false)
end

function PLAYER:addHealthRegen(amount)
	self.regenPool = self.regenPool + amount
	self:setStatusEffect("healing", true)
end

function PLAYER:delayHealthRegen()
	self.regenDelay = CurTime() + GAMEMODE.HealthRegenTickDelay
end

function PLAYER:regenHealth()
	if self:Health() >= GAMEMODE.MaxHealth then
		self.regenPool = 0
		self:setStatusEffect("healing", false)
		return
	end
	
	self.regenPool = self.regenPool - 1
	self:SetHealth(self:Health() + 1)
	self:delayHealthRegen()
	
	-- if we run out of the regen pool, then notify the player's status effect display that we're not healing anymore
	if self.regenPool == 0 then
		self:setStatusEffect("healing", false)
	end
	
	if not self.sentHPRegenHint then
		self:sendTip("HEALTH_REGEN")
	end
end