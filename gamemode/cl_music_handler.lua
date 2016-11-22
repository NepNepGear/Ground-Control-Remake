-- the gamemode was originally supposed to have a ton of music cues for events like round win, round start, idle music during gameplay
-- but the person who was making the music got busy with life stuff and so the only track there is the one you hear at round start :(

GM.currentMusicObject = nil

GM.RoundStartTracks = GM.RoundStartTracks or {"ground_control/music_cues/round_start_1.mp3"}
GM.RoundStartMusicObjects = GM.RoundStartMusicObjects or {}

GM.RoundEndTracks = GM.RoundEndTracks or {}
GM.RoundEndMusicObjects = GM.RoundEndMusicObjects or {}

GM.LastManStandingTracks = GM.LastManStandingTracks or {}
GM.LastManStandingMusicObjects = GM.LastManStandingMusicObjects or {}

GM.DefaultMusicFadeTime = 3

function GM:createMusicObjects() -- prepares all the music objects necessary for the gamemode
	for key, pathToSound in ipairs(self.RoundStartTracks) do
		self:createMusicObject(pathToSound, self.RoundStartMusicObjects)
	end

	for key, pathToSound in ipairs(self.RoundEndTracks) do
		self:createMusicObject(pathToSound, self.RoundEndMusicObjects)
	end

	for key, pathToSound in ipairs(self.LastManStandingTracks) do
		self:createMusicObject(pathToSound, self.LastManStandingMusicObjects)
	end
end

function GM:createMusicObject(pathToSound, outputTable)
	local soundObject = CreateSound(LocalPlayer(), pathToSound, CHAN_STATIC)
	
	if outputTable then
		outputTable[#outputTable + 1] = soundObject
	end
	
	return soundObject
end

function GM:playMusic(object, shouldFadePrevious, volume)
	if self.currentMusicObject and self.currentMusicObject:IsPlaying() then
		if shouldFadePrevious then
			self:fadeMusicOut(self.currentMusicObject, shouldFadePrevious)
		else
			self.currentMusicObject:Stop()
		end
	end
	
	self.currentMusicObject = object
	self:replayMusic(object, volume)
end

function GM:replayMusic(object, volume)
	object = object or self.currentMusicObject
	volume = volume or 1
	
	object:Stop()
	object:Play(volume, 100)
end

function GM:fadeMusicOut(object, fadeTime)
	fadeTime = type(fadeTime) == "number" and fadeTime or self.DefaultMusicFadeTime
	object:FadeOut(fadeTime)
end

function GM:stopMusic(shouldFade)
	if self.currentMusicObject and self.currentMusicObject:IsPlaying() then
		if shouldFade then
			self:fadeMusicOut(self.currentMusicObject, shouldFadePrevious)
		else
			self.currentMusicObject:Stop()
		end
	end
end