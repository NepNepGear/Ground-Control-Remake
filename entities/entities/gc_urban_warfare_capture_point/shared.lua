ENT.Base 			= "base_anim"
ENT.Type 			= "anim"
ENT.Spawnable 		= false
ENT.AdminSpawnable 	= false

function ENT:SetupDataTables()
	self:DTVar("Float", 0, "CaptureProgress")
	self:DTVar("Float", 1, "WaveTimeLimit")
	self:DTVar("Int", 1, "CapturerTeam")
	self:DTVar("Int", 2, "PointID")
	self:DTVar("Int", 3, "CaptureDistance")
	
	self:DTVar("Int", 4, "RedTicketCount")
	self:DTVar("Int", 5, "BlueTicketCount")
	
	self:NetworkVar("Vector", 0, "CaptureMin")
	self:NetworkVar("Vector", 1, "CaptureMax")
	self:NetworkVar("Int", 0, "MaxTickets")
end

function ENT:isWithinCaptureAABB(pos)
	local min, max = self:GetCaptureMin(), self:GetCaptureMax()
	pos.z = pos.z + 32

	if pos.x > min.x and pos.y > min.y and pos.z > min.z and pos.x < max.x and pos.y < max.y and pos.z < max.z then
		return true
	end
	
	return false
end

function ENT:getTeamTickets(teamID)
	if teamID == TEAM_RED then
		return self.dt.RedTicketCount
	else
		return self.dt.BlueTicketCount
	end
end