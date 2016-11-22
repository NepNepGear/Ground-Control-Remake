ENT.Base 			= "base_anim"
ENT.Type 			= "anim"
ENT.Spawnable 		= false
ENT.AdminSpawnable 	= false

ENT.distance = 1024
ENT.timeToPenalize = 10

function ENT:SetupDataTables()
	self:DTVar("Bool", 0, "inverseFunctioning") -- whether the entity should function in reverse (too far = get back here)
	self:DTVar("Int", 0, "targetTeam")
	self:DTVar("Int", 1, "distance")
end

function ENT:isInRange(target, ourPos)
	return target:GetPos():Distance(ourPos) <= self.dt.distance
end

function ENT:canPenalizePlayer(ply, ownPos)
	if GAMEMODE.RoundOver then
		return false
	end
	
	if not ply:Alive() then
		return false
	end
	
	if self.dt.targetTeam ~= 0 then
		if self.dt.targetTeam ~= ply:Team() then
			return false
		end
	end
	
	ownPos = ownPos or self:GetPos()
	
	if self.dt.inverseFunctioning then
		return not self:isInRange(ply, ownPos)
	end
	
	return self:isInRange(ply, ownPos)
end

function ENT:setTargetTeam(teamID)
	self.dt.targetTeam = teamID
end