AddCSLuaFile()

GM.RegisteredAnnouncers = {}
GM.RegisteredAnnouncersById = {}
GM.RegisteredAnnouncements = {}
GM.RegisteredAnnouncementsById = {}
GM.CachedAnnouncementSounds = {}

if SERVER then
	util.AddNetworkString("GC_ANNOUNCEMENT")
else
	net.Receive("GC_ANNOUNCEMENT", function(len, ply)
		local announcer = net.ReadString()
		local announcement = net.ReadString()
		local seed = net.ReadFloat()
				
		GAMEMODE:startAnnouncement(announcer, announcement, seed)
	end)
end

function GM:registerAnnouncer(id)
	local data = {lines = {}, curSound = nil}
	
	table.insert(self.RegisteredAnnouncers, data)
	self.RegisteredAnnouncersById[id] = data
end

function GM:registerAnnouncement(announcerId, announcementId, sounds, callback)
	local announcerData = self.RegisteredAnnouncersById[announcerId]
	local data = {id = announcementId, sounds = sounds, callback = callback}
	
	table.insert(announcerData.lines, data)
	table.insert(self.RegisteredAnnouncements, data)
	self.RegisteredAnnouncementsById[announcementId] = data
end

function GM:startAnnouncement(announcer, id, seed, targetTeam, player)
	if SERVER then
		if player then
			net.Start("GC_ANNOUNCEMENT")
				net.WriteString(announcer)
				net.WriteString(id)
				net.WriteFloat(seed)
			net.Send(player)
		else
			local players = team.GetPlayers(targetTeam)
			
			for key, ply in ipairs(players) do
				net.Start("GC_ANNOUNCEMENT")
					net.WriteString(announcer)
					net.WriteString(id)
					net.WriteFloat(seed)
				net.Send(ply)
			end
		end
	else
		local announcementData = self.RegisteredAnnouncementsById[id]
		local sound = self:GetAnnouncementSoundFromCache(announcer, id, seed)
		
		if self.currentAnnouncementSound then -- stop any previous played sounds
			self.currentAnnouncementSound:Stop()
		end
				
		sound:Stop()
		sound:PlayEx(1, 100) -- replay the sound
		self.currentAnnouncementSound = sound
		
		if announcementData.callback then
			announcementData:callback()
		end
	end
end

if CLIENT then
	function GM:GetAnnouncementSoundFromCache(announcerId, announcementId, seed)
		local ply = LocalPlayer()
		local announcementData = self.RegisteredAnnouncementsById[announcementId]
		math.randomseed(seed)
		
		local randomSound = announcementData.sounds[math.random(1, #announcementData.sounds)]
		
		if not self.CachedAnnouncementSounds[randomSound] then -- create a new sound object, cache it and return it if it wasn't created yet
			local soundObject = CreateSound(ply, randomSound, CHAN_STATIC)
			soundObject:SetSoundLevel(0) -- audible everywhere
			self.CachedAnnouncementSounds[randomSound] = soundObject
		end
		
		return self.CachedAnnouncementSounds[randomSound]
	end
end

-- GHETTO ANNOUNCER AND HIS ANNOUNCEMENTS

GM:registerAnnouncer("ghetto")

GM:registerAnnouncement("ghetto", "drugs_retrieved", {
	"ground_control/radio/ghetto/drugs_retrieved1.mp3",
	"ground_control/radio/ghetto/drugs_retrieved2.mp3",
	"ground_control/radio/ghetto/drugs_retrieved3.mp3",
	"ground_control/radio/ghetto/drugs_retrieved4.mp3"}, nil)
	
GM:registerAnnouncement("ghetto", "drugs_secured", {
	"ground_control/radio/ghetto/drugs_secured1.mp3",
	"ground_control/radio/ghetto/drugs_secured2.mp3",
	"ground_control/radio/ghetto/drugs_secured3.mp3"}, nil)
	
GM:registerAnnouncement("ghetto", "drugs_stolen", {
	"ground_control/radio/ghetto/drugs_stolen1.mp3",
	"ground_control/radio/ghetto/drugs_stolen2.mp3",
	"ground_control/radio/ghetto/drugs_stolen3.mp3"}, function()
		local popup = vgui.Create("GCGenericPopup")
		
		popup:SetText("The attackers have taken the drugs!", "Stop them and bring the dope back!")
		popup:SetExistTime(7)
		popup:SetSize(310, 50)
		popup:Center()
		
		local x, y = popup:GetPos()
		popup:SetPos(x, y - 140)
	end)
	
GM:registerAnnouncement("ghetto", "retrieve_drugs", {
	"ground_control/radio/ghetto/retrieve_drugs1.mp3",
	"ground_control/radio/ghetto/retrieve_drugs2.mp3",
	"ground_control/radio/ghetto/retrieve_drugs3.mp3"}, nil)
	
GM:registerAnnouncement("ghetto", "return_drugs", {
	"ground_control/radio/ghetto/return_drugs1.mp3",
	"ground_control/radio/ghetto/return_drugs2.mp3",
	"ground_control/radio/ghetto/return_drugs3.mp3"}, nil)