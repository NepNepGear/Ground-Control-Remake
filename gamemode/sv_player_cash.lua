include("sh_player_cash.lua")

GM.StartingCashAmount = 0

local PLAYER = FindMetaTable("Player")

function PLAYER:saveCash()
	self:SetPData("GroundControlCash", self.cash)
end

function PLAYER:loadCash()
	local cashAmount = self:GetPData("GroundControlCash") or GAMEMODE.StartingCashAmount
	self.cash = tonumber(cashAmount)
end