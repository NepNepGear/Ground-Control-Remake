AddCSLuaFile()

GM.CashAmount = {cash = nil} -- instead of creating a new table every time we send an "enemy killed" event to the player with the amount of $$$ he got, we instead create one static table
local PLAYER = FindMetaTable("Player")

function PLAYER:addCash(amount, event)
	self.cash = self.cash or 0
	
	self.cash = math.max(self.cash + amount, 0)
	self:sendCash()
	
	if SERVER then
		self:saveCash()
		
		if event then
			GAMEMODE.CashAmount.cash = amount
			GAMEMODE:sendEvent(self, event, GAMEMODE.CashAmount)
		end
	end
end

function PLAYER:removeCash(amount)
	self.cash = self.cash - amount
	self:sendCash()
	
	if SERVER then
		self:saveCash()
	end
end

function PLAYER:setCash(amount)
	self.cash = amount
	self:sendCash()
	
	if SERVER then
		self:saveCash()
	end
end

function PLAYER:sendCash()
	if SERVER then
		umsg.Start("GC_CASH", self)
			umsg.Long(self.cash)
		umsg.End()
	end
end