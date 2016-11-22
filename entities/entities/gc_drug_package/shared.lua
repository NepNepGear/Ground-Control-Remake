ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = ""
ENT.Author = "Spy"
ENT.Spawnable = false
ENT.AdminSpawnable = false 
ENT.Model = "models/Items/ammocrate_smg1.mdl" -- what model to use

function ENT:SetupDataTables()
	self:DTVar("Bool", 0, "Dropped")
end