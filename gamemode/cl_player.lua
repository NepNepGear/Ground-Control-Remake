local PLAYER = FindMetaTable("Player")
local handsMaterial = Material("models/weapons/v_models/hands/v_hands")

function PLAYER:setHandTexture(newTexture)
	if self.previousHandTexture ~= newTexture then
		handsMaterial:SetTexture("$basetexture", newTexture)
		self.previousHandTexture = newTexture
	end
end