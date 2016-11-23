what is up gramer. this readme file is incomplete, it will be filled up over time, but I'm too lazy (and too short on time) to spend time on shit like this
if you would like to [LEARN MORE] - please go through the code and read through the code, comments, etc.

you should pull from the 'develop' branch if you want to download the latest upcoming version that is not yet finished
you should pull from the 'release' branch if you want to download the last stable release version (the same one is also on Workshop)

regarding issues on the gitlab page: the lower the weight - the higher the priority

ON TO THE GAMEMODE DOC:
	GENERAL EDITING GUIDELINE:
		if you're making some kind of edits to the gamemode (doesn't matter what they are), you should probably keep them in cl_config.lua, sh_config.lua and sv_config.lua
		if you're adding new features then those 3 files most likely won't be enough, so in that case go ahead and edit the gamemode files, but beware - merge conflicts will be present when pulling new stuff
		
	ADDING CUSTOM MAP SUPPORT:
		STEP 1 - REGISTERING MAPS FOR MAP ROTATIONS:
			so first you'll need to register a map to an existing map rotation list, here's a list of valid map rotation lists:
				one_side_rush - used for 'Rush'
				ghetto_drug_bust_maps - used for 'Ghetto Drug Bust'
				assault_maps - you get the idea
				urbanwarfare_maps - ditto
				
			in order to register a map to an already existing map rotation list, you will need to call:
				GM:addMapToMapRotationList(mapRotationListName, mapName)
				
			this function call will be best suited in the sv_config.lua file
			
		STEP 2 - REGISTERING ENTITIES:
		the one most important function you will need to use to add objectives to the map is this:
			GM:addObjectivePositionToGametype("gameTypeName", "mapName", entityPosition, "entityClass", {customFlagsWithinTable = "yeas my bro."})
			
		for examples check out sh_gametypes.lua
			
		if you're creating some kind of non-standard Ground Control entity for objectives (AKA one that is not in the base gamemode),
		you should open sh_entity_initializer.lua and take a look there
		
		now let's break down the most commonly called function there:
			GM.entityInitializer:registerEntityInitializeCallback("entityClass", function(entity, curGameType, data)
				if data.data then
					if data.data.customFlagsWithinTable == "yeas my bro." then
						print("hello coon!")
					end
				end
			end)
			
		now the confusing part: see that "data" argument? especially that ugly "data.data"? that's the table that we just provided in the :addObjectivePositionToGametype example above
		NOTE: you obviously DO NOT need to call :registerEntityInitializeCallback for an entity that ALREADY HAS AN INITIALIZE CALLBACK
		
		these 2 function calls will be best suited in the sh_config.lua file