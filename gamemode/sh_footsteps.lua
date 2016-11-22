AddCSLuaFile()

GM.FOOTSTEP_LOUDNESS = {
	ULTRA_LOW = 1,
	VERY_LOW = 2,
	LOW = 3,
	MEDIUM = 4,
	HIGH = 5
}

-- the loudness value of our footsteps, used to figure out what sound should be played
GM.LOUDNESS_LEVELS = {
	[GM.FOOTSTEP_LOUDNESS.ULTRA_LOW] = 20, -- sneaking with a really low amount of weight
	[GM.FOOTSTEP_LOUDNESS.VERY_LOW] = 25, -- sneaking with a low amount of weight
	[GM.FOOTSTEP_LOUDNESS.LOW] = 38, -- walking with <10kg
	[GM.FOOTSTEP_LOUDNESS.MEDIUM] = 50, -- running with <15kg
	[GM.FOOTSTEP_LOUDNESS.HIGH] = 58, -- running with >15kg
}

-- the actual volume of the footstep sounds
GM.FOOTSTEP_LOUDNESS_LEVELS = {
	[GM.FOOTSTEP_LOUDNESS.ULTRA_LOW] = 38, -- sneaking with a really low amount of weight
	[GM.FOOTSTEP_LOUDNESS.VERY_LOW] = 45, -- sneaking with a low amount of weight
	[GM.FOOTSTEP_LOUDNESS.LOW] = 53, -- walking with <10kg
	[GM.FOOTSTEP_LOUDNESS.MEDIUM] = 63, -- running with <15kg
	[GM.FOOTSTEP_LOUDNESS.HIGH] = 71 -- running with >15kg
}

GM.FOOTSTEP_VOLUME_LEVELS = {
	[GM.FOOTSTEP_LOUDNESS.ULTRA_LOW] = 0.65, -- sneaking with a really low amount of weight
	[GM.FOOTSTEP_LOUDNESS.VERY_LOW] = 0.675, -- sneaking with a low amount of weight
	[GM.FOOTSTEP_LOUDNESS.LOW] = 0.7, -- walking with <10kg
	[GM.FOOTSTEP_LOUDNESS.MEDIUM] = 0.75, -- running with <15kg
	[GM.FOOTSTEP_LOUDNESS.HIGH] = 0.825 -- running with >15kg
}

MAT_LADDER = -100 -- there is no MAT_LADDER enumeration, and because I'm too lazy to check for enumeration ids that aren't used I will use -100, oh god
MAT_GRAVEL = -101
MAT_CARPET = -102
MAT_WOODPANEL = -103

-- map the default sounds to a material ID, way cheaper than traces, but also hacky as shit
-- whoever wrote the PlayerFootstep hook but thought it's a good idea to not provide the material ID of the surface that the player stepped on is a fucking retard
GM.DEFAULT_FOOTSTEP_TO_MATERIAL = {["player/footsteps/wood1.wav"] = MAT_WOOD,
	["player/footsteps/wood2.wav"] = MAT_WOOD,
	["player/footsteps/wood3.wav"] = MAT_WOOD,
	["player/footsteps/wood4.wav"] = MAT_WOOD,
	["player/footsteps/grass1.wav"] = MAT_GRASS,
	["player/footsteps/grass2.wav"] = MAT_GRASS,
	["player/footsteps/grass3.wav"] = MAT_GRASS,
	["player/footsteps/grass4.wav"] = MAT_GRASS,
	["player/footsteps/dirt1.wav"] = MAT_DIRT,
	["player/footsteps/dirt2.wav"] = MAT_DIRT,
	["player/footsteps/dirt3.wav"] = MAT_DIRT,
	["player/footsteps/dirt4.wav"] = MAT_DIRT,
	["player/footsteps/ladder1.wav"] = MAT_LADDER,
	["player/footsteps/ladder2.wav"] = MAT_LADDER,
	["player/footsteps/ladder3.wav"] = MAT_LADDER,
	["player/footsteps/ladder4.wav"] = MAT_LADDER,
	["player/footsteps/slosh1.wav"] = MAT_SLOSH,
	["player/footsteps/slosh2.wav"] = MAT_SLOSH,
	["player/footsteps/slosh3.wav"] = MAT_SLOSH,
	["player/footsteps/slosh4.wav"] = MAT_SLOSH,
	["player/footsteps/metal1.wav"] = MAT_METAL,
	["player/footsteps/metal2.wav"] = MAT_METAL,
	["player/footsteps/metal3.wav"] = MAT_METAL,
	["player/footsteps/metal4.wav"] = MAT_METAL,
	["player/footsteps/gravel1.wav"] = MAT_GRAVEL,
	["player/footsteps/gravel2.wav"] = MAT_GRAVEL,
	["player/footsteps/gravel3.wav"] = MAT_GRAVEL,
	["player/footsteps/gravel4.wav"] = MAT_GRAVEL,
	["player/footsteps/snow1.wav"] = MAT_SNOW,
	["player/footsteps/snow2.wav"] = MAT_SNOW,
	["player/footsteps/snow3.wav"] = MAT_SNOW,
	["player/footsteps/snow4.wav"] = MAT_SNOW,
	["physics/wood/wood_box_footstep1.wav"] = MAT_WOODPANEL,
	["physics/wood/wood_box_footstep2.wav"] = MAT_WOODPANEL,
	["physics/wood/wood_box_footstep3.wav"] = MAT_WOODPANEL,
	["physics/wood/wood_box_footstep4.wav"] = MAT_WOODPANEL}

GM.FOOTSTEP_LOUNDLESS_LEVEL_ORDER = {}

for key, id in pairs(GM.FOOTSTEP_LOUDNESS) do
	table.insert(GM.FOOTSTEP_LOUNDLESS_LEVEL_ORDER, id)
end

-- sort them from lowest to highest
table.sort(GM.FOOTSTEP_LOUNDLESS_LEVEL_ORDER, function(a, b)
	return GM.FOOTSTEP_LOUDNESS_LEVELS[a] < GM.FOOTSTEP_LOUDNESS_LEVELS[b]
end)

GM.BASE_NOISE_LEVEL = 30
GM.LOUDNESS_PER_VELOCITY = 30 / GM.BaseRunSpeed -- add 20 loudness when we reach full run speed
GM.CROUCH_LOUDNESS_VELOCITY_AFFECTOR = 0.5 -- multiply loudness increase from velocity by this much when crouch-walking
GM.CROUCH_LOUDNESS_OVERALL_AFFECTOR = 0.5 -- overall multiplier for loudness when crouch-walking
GM.SNEAKWALK_LOUDNESS_VELOCITY_AFFECTOR = 0.7 -- multiply loudness increase from velocity by this much when walking (+walk)
GM.SNEAKWALK_LOUDNESS_OVERALL_AFFTER = 0.5 -- overall multiplier for loudness when walking
GM.MAX_LOUDNESS_FROM_VELOCITY = 25 -- max loudness we can get from velocity
GM.NOISE_PER_KILOGRAM = 1.25
GM.SNEAKWALK_VELOCITY_CUTOFF = 105 -- if the player is walking slower than this, he is considered to be sneak-walking

-- key is surface ID, value is table with sounds, filled automatically
GM.SURFACE_FOOTSTEP_SOUNDS = {
}

-- the sounds to play when walking on a surface that does not have a footstep sound registered to it
GM.FALLBACK_FOOTSTEP_SOUNDS = {}

GM.FOOTSTEP_PITCH_START = 95
GM.FOOTSTEP_PITCH_END = 105

function GM:registerWalkSound(materialID, desiredSounds, baseName, channel)
	channel = channel or CHAN_AUTO
	
	local targetList = nil
	
	if materialID then
		self.SURFACE_FOOTSTEP_SOUNDS[materialID] = self.SURFACE_FOOTSTEP_SOUNDS[materialID] or {}
		targetList = self.SURFACE_FOOTSTEP_SOUNDS[materialID]
	else
		targetList = self.FALLBACK_FOOTSTEP_SOUNDS
	end
	
	for soundTypeName, soundTypeID in pairs(self.FOOTSTEP_LOUDNESS) do
		targetList[soundTypeID] = targetList[soundTypeID] or {}
		local soundName = baseName .. soundTypeName
		local soundLevel = self.FOOTSTEP_LOUDNESS_LEVELS[soundTypeID]
		
		sound.Add({
			channel = channel, 
			pitchstart = self.FOOTSTEP_PITCH_START,
			pitchend = self.FOOTSTEP_PITCH_END,
			level = soundLevel,
			name = soundName,
			volume = self.FOOTSTEP_VOLUME_LEVELS[soundTypeID],
			sound = desiredSounds
		})
		
		table.insert(targetList[soundTypeID], soundName)
	end
end

GM:registerWalkSound(nil, {"ground_control/footsteps/concrete1.wav", "ground_control/footsteps/concrete2.wav", "ground_control/footsteps/concrete3.wav", "ground_control/footsteps/concrete4.wav"}, "GC_FALLBACK_WALK_SOUNDS")
GM:registerWalkSound(MAT_WOOD, {"ground_control/footsteps/wood1.wav", "ground_control/footsteps/wood2.wav", "ground_control/footsteps/wood3.wav", "ground_control/footsteps/wood4.wav"}, "GC_WALK_WOOD")
GM:registerWalkSound(MAT_GRASS, {"ground_control/footsteps/grass1.wav", "ground_control/footsteps/grass2.wav", "ground_control/footsteps/grass3.wav", "ground_control/footsteps/grass4.wav"}, "GC_WALK_GRASS")
GM:registerWalkSound(MAT_SLOSH, {"ground_control/footsteps/slosh1.wav", "ground_control/footsteps/slosh2.wav", "ground_control/footsteps/slosh3.wav", "ground_control/footsteps/slosh4.wav"}, "GC_WALK_SLOSH")
GM:registerWalkSound(MAT_METAL, {"ground_control/footsteps/metal1.wav", "ground_control/footsteps/metal2.wav", "ground_control/footsteps/metal3.wav", "ground_control/footsteps/metal4.wav"}, "GC_WALK_METAL")
GM:registerWalkSound(MAT_LADDER, {"ground_control/footsteps/ladder1.wav", "ground_control/footsteps/ladder2.wav", "ground_control/footsteps/ladder3.wav", "ground_control/footsteps/ladder4.wav"}, "GC_WALK_LADDER")
GM:registerWalkSound(MAT_GRAVEL, {"ground_control/footsteps/gravel1.wav", "ground_control/footsteps/gravel2.wav", "ground_control/footsteps/gravel3.wav", "ground_control/footsteps/gravel4.wav"}, "GC_WALK_GRAVEL")
GM:registerWalkSound(MAT_SNOW, {"ground_control/footsteps/snow1.wav", "ground_control/footsteps/snow2.wav", "ground_control/footsteps/snow3.wav", "ground_control/footsteps/snow4.wav"}, "GC_WALK_SNOW")
GM:registerWalkSound(MAT_DIRT, {"ground_control/footsteps/dirt1.wav", "ground_control/footsteps/dirt2.wav", "ground_control/footsteps/dirt3.wav", "ground_control/footsteps/dirt4.wav"}, "GC_WALK_DIRT")
GM:registerWalkSound(MAT_WOODPANEL, {"ground_control/footsteps/woodpanel1.wav", "ground_control/footsteps/woodpanel2.wav", "ground_control/footsteps/woodpanel3.wav", "ground_control/footsteps/woodpanel4.wav"}, "GC_WALK_WOODPANEL")

function GM:getWalkSound(materialID, loudnessLevel)
	local sounds = self.SURFACE_FOOTSTEP_SOUNDS[materialID]
	
	if sounds then
		sounds = sounds[loudnessLevel]
		
		if sounds then
			return sounds[math.random(1, #sounds)]
		end
	end
		
	local targetList = self.FALLBACK_FOOTSTEP_SOUNDS[loudnessLevel]
		
	return targetList[math.random(1, #targetList)]
end

function GM:PlayerFootstep(ply, position, foot, sound, volume, filter)
	if not ply:Alive() then
		return
	end
	
	-- don't try to play the sounds clientside if the person running is not the localplayer
	if CLIENT and ply ~= LocalPlayer() then
		return true
	end
		
	local materialID = self.DEFAULT_FOOTSTEP_TO_MATERIAL[sound]
	local loudnessID, noiseLevel = self:getLoudnessLevel(ply)
	self:playFootstepSound(ply, loudnessID, materialID)
	
	-- suppress default sounds
	return true
end

function GM:playFootstepSound(ply, loudnessID, materialID)
	if CLIENT then
		local sound = self:getWalkSound(materialID, loudnessID)
		
		ply:EmitSound(sound)
	else -- in the case of a server we send a usermessage to everyone to play the sound
		umsg.Start("GC_FOOTSTEP")
			umsg.Entity(ply)
			umsg.Short(loudnessID)
			umsg.Short(materialID)
		umsg.End()
	end
end

-- use usermessages to network the footsteps
if CLIENT then
	usermessage.Hook("GC_FOOTSTEP", function(data)
		local object = data:ReadEntity()
		
		-- if the footstep sound belongs to us, don't play it, because we've already played it on our own
		if not IsValid(object) or object == LocalPlayer() then
			return
		end
		
		local loudnessID = data:ReadShort()
		local materialID = data:ReadShort()		
		
		GAMEMODE:playFootstepSound(object, loudnessID, materialID)
	end)
end

function GM:getLoudnessLevel(ply)
	local noiseLevel = self.BASE_NOISE_LEVEL
	
	if CLIENT then -- on the client we will re-calculate the weight, because it's more accurate that way
		noiseLevel = noiseLevel + ply:calculateWeight() * self.NOISE_PER_KILOGRAM
	else -- on the server we will use the pre-calculated weight value, because the server knows more than the client about his weight values
		noiseLevel = noiseLevel + ply.weight * self.NOISE_PER_KILOGRAM
	end
	
	local crouching = ply:Crouching()
	local velLength = ply:GetVelocity():Length()
	
	local sneakWalking = velLength <= self.SNEAKWALK_VELOCITY_CUTOFF
	
	local overallAffector = 1
	local velocityAffector = 1
	
	if crouching then
		overallAffector = self.CROUCH_LOUDNESS_OVERALL_AFFECTOR
		velocityAffector = self.CROUCH_LOUDNESS_VELOCITY_AFFECTOR
	elseif sneakWalking then
		overallAffector = self.SNEAKWALK_LOUDNESS_OVERALL_AFFTER
		velocityAffector = self.SNEAKWALK_LOUDNESS_VELOCITY_AFFECTOR
	end
	
	noiseLevel = noiseLevel + math.min(velLength * self.LOUDNESS_PER_VELOCITY, self.MAX_LOUDNESS_FROM_VELOCITY) * velocityAffector
	noiseLevel = noiseLevel * overallAffector
	
	local mostValidLoudnessLevel = self.FOOTSTEP_LOUDNESS.ULTRA_LOW
	
	for key, loudnessID in ipairs(self.FOOTSTEP_LOUNDLESS_LEVEL_ORDER) do
		if noiseLevel > self.LOUDNESS_LEVELS[loudnessID] then -- if the loudness value is greater than this one
			mostValidLoudnessLevel = loudnessID
		end
	end
	
	return mostValidLoudnessLevel, noiseLevel
end

local PLAYER = FindMetaTable("Player")

function PLAYER:getWeightFootstepNoiseAffector(weight)
	weight = weight or self.weight or self:calculateWeight()
	
	return weight * GAMEMODE.NOISE_PER_KILOGRAM
end