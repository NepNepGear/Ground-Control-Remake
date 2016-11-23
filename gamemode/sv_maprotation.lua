GM.MapRotation = {}

function GM:registerMapRotation(name, maps)
	self.MapRotation[name] = maps
end

function GM:getMapRotation(name)
	return self.MapRotation[name]
end

function GM:filterExistingMaps(list)
	local newList = {}
	
	for key, mapName in ipairs(list) do
		if self:hasMap(mapName) then
			newList[#newList + 1] = mapName
		end
	end
	
	return newList
end

function GM:addMapToMapRotationList(mapRotationList, mapName)
	if not self.MapRotation[mapRotationList] then
		self.MapRotation[mapRotationList] = {}
		print("[GROUND CONTROL] - attempt to add a map to a non-existant map rotation list, creating list")
	end
	
	table.insert(self.MapRotation[mapRotationList], mapName)
end

function GM:hasMap(mapName)
	return file.Exists("maps/" .. mapName .. ".bsp", "GAME")
end

GM:registerMapRotation("one_side_rush", {"de_dust", "de_dust2", "cs_assault", "cs_compound", "cs_havana", "de_cbble", "de_inferno", "de_nuke", "de_port", "de_tides", "de_aztec", "de_chateau", "de_piranesi", "de_prodigy", "de_train", "de_secretcamp"})

GM:registerMapRotation("ghetto_drug_bust_maps", {"cs_assault", "cs_compound", "cs_havana", "cs_militia", "cs_italy", "de_chateau", "de_inferno", "de_shanty_v3_fix"})

GM:registerMapRotation("assault_maps", {"cs_jungle", "cs_siege_2010", "gc_outpost", "de_desert_atrocity_v3"}) -- "rp_downtown_v2" "gc_depot_b1"

GM:registerMapRotation("urbanwarfare_maps", {"ph_skyscraper_construct", "de_desert_atrocity_v3"})