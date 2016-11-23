GM.RoundWonCash = 200
GM.RoundWonExp = 150

GM.RoundsPerMap = 16
GM.RoundsPlayed = 0
GM.MaxMapsPerPick = 9
GM.MaxGameTypesPerPick = 9

GM.TrashDealingMethods = { -- how to deal with trash props (small props with a small weight that the player collides with and then everything goes to fuck)
	REMOVE = 1, -- will remove them
	COLLISION = 2 -- will set the collision group to debris (does not collide with the player)
}

GM.DealWithTrash = GM.TrashDealingMethods.COLLISION
GM.TrashPropMaxWeight = 2 -- max weight of a prop to be considered trash

function GM:trackRoundMVP(player, id, amount)
	self.MVPTracker:trackID(player, id, amount)
end

function GM:dealWithTrashProps()
	if self.DealWithTrash == self.TrashDealingMethods.REMOVE then
		self:removeTrashProps(ents.FindByClass("prop_physics"))
		self:removeTrashProps(ents.FindByClass("prop_physics_multiplayer"))
	elseif self.DealWithTrash == self.TrashDealingMethods.COLLISION then
		self:makeDebrisMovetypeForTrash(ents.FindByClass("prop_physics"))
		self:makeDebrisMovetypeForTrash(ents.FindByClass("prop_physics_multiplayer"))
	end
end

function GM:removeTrashProps(entList)
	for k, v in pairs(entList) do
		local phys = v:GetPhysicsObject()
		
		if phys and phys:GetMass() <= self.TrashPropMaxWeight then
			SafeRemoveEntity(v)
		end
	end
end

function GM:makeDebrisMovetypeForTrash(entList)
	for k, v in pairs(entList) do
		local phys = v:GetPhysicsObject()
		
		if phys and phys:GetMass() <= self.TrashPropMaxWeight then
			v:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		end
	end
end

-- this is the default round over check, for gametypes with no player respawns
function GM:checkRoundOverPossibility(teamId, ignoreDisplay)
	if not self.RoundOver then
		local allPlayers = player.GetAll()
		
		if #allPlayers < 2 then -- don't do anything if we only have 2 players
			if allPlayers == 0 then -- if everyone disconnected, reset rounds played
				self.RoundsPlayed = 0
			end
			
			return
		end
	
		local redMembers = team.GetPlayers(TEAM_RED)
		local blueMembers = team.GetPlayers(TEAM_BLUE)
		
		if #redMembers == 0 or #blueMembers == 0 then -- if neither team has AT LEAST ONE member, we don't restart rounds at all
			return
		end
		
		if self.RoundsPlayed > 0 then
			local winner = nil
			
			if self:countLivingPlayers(TEAM_RED) == 0 then
				winner = TEAM_BLUE
			end
			
			if self:countLivingPlayers(TEAM_BLUE) == 0 then
				winner = TEAM_RED
			end
			
			if winner then
				self:endRound(winner)
			end
		else
			self:endRound(nil)
		end
	end
	
	if teamId then
		if not ignoreDisplay then
			self:createLastManStandingDisplay(teamId)
		end
	end
end

function GM:endRound(winningTeam)
	if self.RoundOver then -- we're already restarting a round wtf
		return
	end
	
	print("[GROUND CONTROL] ROUND HAS ENDED, WINNING TEAM ID: ", winningTeam)
	local lastRound = self.RoundsPlayed >= self.RoundsPerMap
	
	if not winningTeam then
		SendUserMessage("GC_GAME_BEGIN")
	else
		for key, obj in ipairs(team.GetPlayers(winningTeam)) do
			obj:addCurrency(self.RoundWonCash, self.RoundWonExp, "WON_ROUND")
		end
		
		umsg.Start("GC_ROUND_OVER")
			umsg.Char(winningTeam)
		umsg.End()
	end
	
	self.MVPTracker:sendMVPList()
	self.MVPTracker:resetAllTrackedIDs()
	
	if self.curGametype.onRoundEnded then
		self.curGametype:onRoundEnded(winningTeam)
	end
	
	timer.Simple(self.RoundRestartTime, function()
		self:restartRound()
	end)
	
	self.RoundOver = true
	
	if lastRound then -- start a vote for the next map if possible
		self:startVoteMap()
	else
		if self.RoundsPlayed == self.RoundsPerMap - 1 and self:gametypeVotesEnabled() then -- start a vote for next gametype if we're on the second last round
			self:startGameTypeVote()
		end
		
		self.RoundsPlayed = self.RoundsPlayed + 1
		self:saveCurrentGametype()
	end
end

function GM:startVoteMap()
	if self:canStartVote() then
		local id, data = self:getGametypeFromConVar()
		
		self:setupCurrentVote("Vote for the next map", self:filterExistingMaps(data.mapRotation), player.GetAll(), self.MaxMapsPerPick, true, nil, function()
			local highestOption, highestKey = self:getHighestVote()
			
			game.ConsoleCommand("changelevel " .. highestOption.option .. "\n")
		end)
	end
end

GM.PreviousGametypeFile = "previous_gametype.txt"

-- doesn't actually remove the gametype, it just removes any mention of what the previous gametype from the file was, in case you switch maps a lot and want to have all gametypes up for voting
-- bad name for the method though
function GM:removeCurrentGametype() 
	file.Write(self.MainDataDirectory .. "/" .. self.PreviousGametypeFile, "")
end

function GM:saveCurrentGametype()
	file.Write(self.MainDataDirectory .. "/" .. self.PreviousGametypeFile, self.curGametype.name)
end

function GM:getPreviousGametype()
	local data = file.Read(self.MainDataDirectory .. "/" .. self.PreviousGametypeFile)
	
	if data then
		return data
	end
end

function GM:hasAtLeastOneMapForGametype(gametypeData)
	for key, map in ipairs(gametypeData.mapRotation) do
		if self:hasMap(map) then
			return true
		end
	end
	
	return false
end

function GM:startGameTypeVote()
	local possibilities = {}
	local prevGametype = self:getPreviousGametype()
	
	for key, gametype in ipairs(GAMEMODE.Gametypes) do
		if self.RemovePreviousGametype and prevGametype and prevGametype == gametype.name then -- this gametype was already played, so skip it
			continue
		end
		
		if self:hasAtLeastOneMapForGametype(gametype) then -- only insert the gamemode if there is at least 1 map available for it
			table.insert(possibilities, gametype.prettyName)
		end
	end
	
	self:setupCurrentVote("Vote for next game type", possibilities, player.GetAll(), self.MaxGameTypesPerPick, false, nil, function()
		local highestOption, highestKey = self:getHighestVote()
		
		self:setGametypeCVarByPrettyName(highestOption.option)
	end)
end

function GM:restartRound()
	if not self.curGametype.noTeamBalance then
		self:balanceTeams()
	end
	
	self.canSpawn = true
	game.CleanUpMap()
	self:dealWithTrashProps()
	self:autoRemoveEntities()
	self:runMapStartCallback()
	
	if self.curGametype.roundStart then
		self.curGametype:roundStart()
	end
	
	self:setupRoundPreparation()
	
	for key, obj in pairs(player.GetAll()) do
		obj:Spawn()
	end
	
	self.canSpawn = false
	self.RoundOver = false
	self:updateServerName()
	SendUserMessage("GC_NEW_ROUND")
end

function GM:setupLoadoutSelectionTime()
	self.LoadoutSelectTime = CurTime() + self.RoundLoadoutTime
end

function GM:setupRoundPreparation()
	self.PreparationTime = CurTime() + self.RoundPreparationTime
	self:setupLoadoutSelectionTime()
	
	timer.Simple(self.RoundPreparationTime, function()
		self:disableCustomizationMenu()
	end)

	umsg.Start("GC_ROUND_PREPARATION")
		umsg.Float(self.PreparationTime)
	umsg.End()
end

function GM:countLivingPlayers(teamToCheck)
	local alive = 0
	
	for key, obj in pairs(team.GetPlayers(teamToCheck)) do
		if obj:Alive() then
			alive = alive + 1
		end
	end
	
	return alive
end