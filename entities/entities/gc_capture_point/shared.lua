ENT.Base 			= "base_anim"
ENT.Type 			= "anim"
ENT.Spawnable 		= false
ENT.AdminSpawnable 	= false

function ENT:SetupDataTables()
	self:DTVar("Int", 0, "CaptureProgress")
	self:DTVar("Int", 1, "CapturerTeam")
	self:DTVar("Int", 2, "PointID")
	self:DTVar("Int", 3, "CaptureDistance")
end