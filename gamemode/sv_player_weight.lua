include("sh_player_weight.lua")

local PLAYER = FindMetaTable("Player")

CustomizableWeaponry.callbacks:addNew("postFire", "GroundControl_postFire", function(wep)
	wep.Owner:setWeight(wep.Owner:calculateWeight())
end)