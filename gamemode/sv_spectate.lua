local PLAYER = FindMetaTable("Player")

GM.SpectateablePlayers = {}

function PLAYER:resetSpectateData()
	self.spectatedPlayers = self.spectatedPlayers or {}
	self.spectateDelay = 0
	self.currentSpectateEntity = nil
	
	table.clear(self.spectatedPlayers)
end

function PLAYER:spectateNext()
	local wasFound = false
	local alivePlayers = 0
	local teamPlayers = nil 
	
	local myTeam = self:Team()
	
	if myTeam == TEAM_SPECTATOR then
		teamPlayers = player.GetAll()
	else
		teamPlayers = team.GetPlayers(self:Team())
	end
	
	local teamPlayerCount = #teamPlayers
	
	for key, ply in ipairs(teamPlayers) do
		if ply:Alive() then
			if not self.spectatedPlayers[ply] then
				self.spectatedPlayers[ply] = true
				self:setSpectateTarget(ply)
				wasFound = true
				
				break
			end
			
			alivePlayers = alivePlayers + 1
		end
	end
	
	if not wasFound and alivePlayers > 0 then
		self:resetSpectateData()
		self:spectateNext()
	end
end

function PLAYER:reSpectate()
	self:resetSpectateData()
	self:spectateNext()
end

function PLAYER:isSpectateTargetValid()
	return IsValid(self.currentSpectateEntity)
end

function PLAYER:delaySpectate(time)
	self.spectateDelay = CurTime() + time
end

function PLAYER:attemptSpectate()
	if self:Alive() or CurTime() < self.spectateDelay then
		return
	end
	
	self:spectateNext()
end

concommand.Add("gc_spectate_next", function(ply, com, args)
	ply:attemptSpectate()
end)