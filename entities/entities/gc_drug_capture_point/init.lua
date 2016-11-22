AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.CaptureRange = 128

function ENT:Initialize()
	self:SetNoDraw(true)
end

function ENT:Think()
	if GAMEMODE.RoundOver then
		return
	end
	
	for key, obj in ipairs(ents.FindInSphere(self:GetPos(), self.CaptureRange)) do
		if obj:IsPlayer() and obj:Alive() and GAMEMODE.curGametype:attemptCaptureDrugs(obj, self) then
			GAMEMODE:endRound(obj:Team())
		end
	end
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end