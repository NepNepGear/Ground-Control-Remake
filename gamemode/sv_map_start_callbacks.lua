-- allows you to register callbacks on a per-map basis that get called when the map is loaded or a round is restarted
GM.MapStartCallbacks = {}

function GM:registerMapStartCallback(map, callback)
	self.MapStartCallbacks[map] = callback
end

function GM:runMapStartCallback()
	local map = string.lower(game.GetMap())
	
	if self.MapStartCallbacks[map] then
		self.MapStartCallbacks[map]()
	end
end

local excludeUnlock = {
	[627] = true,
	[695] = true, 
	[710] = true,
	[626] = true
}

GM:registerMapStartCallback("rp_downtown_v2", function()
	local maxPlayers = game.MaxPlayers()
	
	for k, v in pairs(ents.FindByClass("prop_door_rotating")) do -- unlock all building doors
		local entIndex = v:EntIndex() - maxPlayers
		
		if not excludeUnlock[entIndex] then
			v:Fire("unlock")
		end
	end
end)

GM:registerMapStartCallback("rp_downtown_v4c_v2", function()
	local maxPlayers = game.MaxPlayers()
	
	for k, v in pairs(ents.FindByClass("prop_door_rotating")) do -- unlock all building doors
		local entIndex = v:EntIndex() - maxPlayers
		
		v:Fire("unlock")
	end
end)

GM:registerMapStartCallback("ph_skyscraper_construct", function()
	local maxPlayers = game.MaxPlayers()
	
	for k, v in pairs(ents.FindByClass("prop_physics")) do -- freeze all entities on this map
		v:SetMoveType(MOVETYPE_NONE)
		
		local phys = v:GetPhysicsObject()
		
		if phys then
			phys:EnableMotion(false)
		end
	end
	
	for k, v in pairs(ents.FindByClass("prop_physics_multiplayer")) do -- freeze all entities on this map
		v:SetMoveType(MOVETYPE_NONE)
		
		local phys = v:GetPhysicsObject()
		
		if phys then
			phys:EnableMotion(false)
		end
	end
end)