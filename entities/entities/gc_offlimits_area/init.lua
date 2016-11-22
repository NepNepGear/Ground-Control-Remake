AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/error.mdl")
	self:SetNoDraw(true)
	self.dt.distance = self.distance
end

local plys, CT

function ENT:Think()
	if GAMEMODE.RoundOver then
		return
	end
	
	local curTime = CurTime()
	local defendingPlayers = 0
	
	local ownPos = self:GetPos()
	local targets = nil
	
	if self.dt.targetTeam == 0 then
		targets = player.GetAll()
	else
		targets = team.GetPlayers(self.dt.targetTeam)
	end
	
	for key, ply in ipairs(targets) do
		if self:canPenalizePlayer(ply, ownPos) then
			if not ply.penalizeTime then
				ply.penalizeTime = curTime + self.timeToPenalize
			else
				if curTime >= ply.penalizeTime then
					ply:Kill()
				end
			end
		else
			ply.penalizeTime = nil
		end
	end
end

function ENT:Use(activator, caller)
	return false
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end