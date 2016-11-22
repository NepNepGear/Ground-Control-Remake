AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.ReturnRange = 64

local freezeEnts = {
	prop_physics = true,
	prop_physics_multiplayer = true
}

function ENT:Initialize() 
	self:PhysicsInit(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self:SetNoDraw(true)
end

function ENT:Think()
	for key, obj in ipairs(ents.FindInSphere(self:GetPos(), self.ReturnRange)) do
		if obj:IsPlayer() and obj:Alive() and GAMEMODE.curGametype:attemptReturnDrugs(obj, self) then
			self:setHasDrugs(true)
		end
	end
end

function ENT:setHasDrugs(has)
	self.dt.HasDrugs = has
	
	if has then
		self:createDrugPackageObject()
	end
end

function ENT:freezeNearbyProps()
	for key, obj in ipairs(ents.FindInSphere(self:GetPos(), self.ReturnRange)) do
		if freezeEnts[obj:GetClass()] then
			obj:SetMoveType(MOVETYPE_NONE) -- freeze em
			obj:SetHealth(9999999) -- give nearby props a shitton of health (in case it's a wooden table or something)
		end
	end
end

function ENT:createDrugPackageObject()
	local randAngle = AngleRand()
	
	local pos = self:GetPos()
	pos.z = pos.z + 6
	
	local ent = ents.Create("gc_drug_package")
	ent:SetPos(pos)
	ent:SetAngles(Angle(0, randAngle.y, randAngle.r))
	ent:Spawn()
	ent:SetHost(self)
	
	self.dt.HasDrugs = true
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end