include("sh_player_bleeding.lua")

GM.BleedTime = 5 -- we will lose BleedHealthLose health points this amount of seconds
GM.BleedHealthLose = 1 -- how much health should we lose per bleed tick
GM.BandageTime = 2.3

local PLAYER = FindMetaTable("Player")

function PLAYER:shouldBleed()
	return CurTime() >= self.bleedHealthDrainTime
end

function PLAYER:bleed(silentBleed)
	self:SetHealth(self:Health() - GAMEMODE.BleedHealthLose)
	self:delayBleed()
	self:postBleed()
	
	if not silentBleed then
		self:EmitSound("GC_BLEED")
	end
end

function PLAYER:delayBleed(time)
	time = time or GAMEMODE.BleedTime
	self.bleedHealthDrainTime = CurTime() + time
end

function PLAYER:postBleed()
	if self:Health() <= 0 then -- if we have no health left after bleeding, we die
		self:Kill()
	end
end

function PLAYER:startBleeding(bleedInflictor)
	self:delayBleed()
	
	if bleedInflictor then
		self.bleedInflictor = bleedInflictor -- the person that caused us to bleed
	end
	
	self:setBleeding(true)
end

function PLAYER:sendBleedState()
	umsg.Start("GC_BLEEDSTATE", self)
		umsg.Bool(self.bleeding)
	umsg.End()
end

umsg.PoolString("GC_BLEEDSTATE")

function PLAYER:attemptBandage()
	if not self:Alive() then
		return
	end
	
	local target = self:getBandageTarget()
	
	if self:canBandage(target) then
		target:bandage(self)
	end
end

function PLAYER:useBandage()
	self.bandages = self.bandages - 1
end

function PLAYER:bandage(bandagedBy)
	bandagedBy = bandagedBy or self
	
	bandagedBy:useBandage()
	bandagedBy:EmitSound("GC_BANDAGE")
	bandagedBy:sendBandages()
	bandagedBy:calculateWeight()
	
	local wep = bandagedBy:GetActiveWeapon()
	
	if IsValid(wep) then
		wep:setGlobalDelay(GAMEMODE.BandageTime + 0.3, true, CW_ACTION, GAMEMODE.BandageTime)
	end
	
	self:setBleeding(false)
	
	if bandagedBy ~= self then
		bandagedBy:addCurrency(GAMEMODE.CashPerBandage, GAMEMODE.ExpPerBandage, "TEAMMATE_BANDAGED")
		GAMEMODE:trackRoundMVP(bandagedBy, "bandaging", 1)
	end
	
	self:restoreHealth(bandagedBy.healAmount)
end

function PLAYER:sendBandages()
	umsg.Start("GC_BANDAGES", self)
		umsg.Short(self.bandages)
	umsg.End()
end

umsg.PoolString("GC_BANDAGES")

concommand.Add("gc_bandage", function(ply, com, args)
	ply:attemptBandage()
end)