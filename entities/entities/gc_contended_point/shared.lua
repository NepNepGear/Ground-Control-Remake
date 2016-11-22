ENT.Base 			= "base_anim"
ENT.Type 			= "anim"
ENT.Spawnable 		= false
ENT.AdminSpawnable 	= false

function ENT:SetupDataTables()
	self:DTVar("Int", 0, "CaptureProgress")
	self:DTVar("Int", 1, "CurCaptureTeam")
end