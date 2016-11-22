AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/props_junk/garbage_bag001a.mdl") 
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
end

function ENT:wakePhysics()
	self:SetMoveType(MOVETYPE_VPHYSICS)
	
	local phys = self:GetPhysicsObject()

	if phys and phys:IsValid() then
		phys:Wake()
	end
end

function ENT:Use(activator, caller)
	if GAMEMODE.RoundOver then
		return
	end
	
	local gametype = GAMEMODE.curGametype
	
	if gametype:pickupDrugs(self, activator) then
		self:Remove()
		
		if self.host then
			self.host.dt.HasDrugs = false
		end
	end
end

function ENT:SetHost(host)
	self.host = host
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end