-- autopunish module, automatically starts a punish vote against people that TK way too frequently

GM.TKsForPunishVote = 5 -- how many people this player has to kill for a punish vote to begin
GM.AutoPunishEnabled = true
GM.LowerPunishLevelTime = 86400 * 7 -- 7 weeks to lower punish level

GM.PunishLevels = { -- punish level time is in minutes
	{ban = nil}, -- first time is a kick
	{ban = 60}, -- hour
	{ban = 60 * 24}, -- day
	{ban = 60 * 24 * 7}, -- week
	{ban = 60 * 24 * 7 * 4}, -- month,
	{ban = 60 * 24 * 7 * 4 * 2}, -- 2 months
	{ban = 60 * 24 * 7 * 4 * 6}, -- 6 months
	{ban = 60 * 24 * 7 * 4 * 12} -- a year (wtf, how and why would anyone TK this much)
}

GM.PunishLevelString = "GC_PunishLevel"
GM.TKCounterString = "GC_TKCounter"
GM.BanDurationString = "GC_BanDuration"
GM.PunishVoteOptions = {"Yes", "No"}

function GM:startPunishVote(target)
	if target.inPunishVote then -- target already being vote-punished
		return
	end
	
	target.inPunishVote = true
	
	local targetTeam = target:Team()
	local targetSteamID = target:SteamID()
	local text = nil
	
	local banDuration = target:GetPData(self.BanDurationString)
	
	if banDuration then -- check if this player was banned before
		local delta = banDuration - os.time() -- if he was, figure out how many punishment levels have gone by then
		local levels = math.floor(delta / self.LowerPunishLevelTime)
		
		if levels > 0 then -- if there is at least one, decrease it to a minimum of 1 (kick)
			target:setPunishLevel(math.max(target:getPunishLevel() - levels, 1))
		end
	end
	
	local punishData = self.PunishLevels[target:getPunishLevel()]
	
	if not punishData then -- refer to the harshest possible punishment if the player has gone overboard
		punishData = self.PunishLevels[#self.PunishLevels]
	end
		
	if punishData.ban then
		text = "Ban " .. target:Nick() .. " for " .. punishData.ban .. " minute(s)? (excessive TK)"
	else
		text = "Kick " .. target:Nick() .. " for excessive TK?"
	end
	
	local votePlayers = table.Exclude(team.GetPlayers(targetTeam), target) -- get the team members of the person we're votekicking, but exclude him from there
	
	self:setupCurrentVote(text, self.PunishVoteOptions, votePlayers, 2, false, nil, function()
		local highestOption, highestKey = self:getHighestVote()
		local affectedPlayer = player.GetBySteamID(targetSteamID)
		local playerValid = IsValid(affectedPlayer)
		
		if highestOption.option == "Yes" and highestOption.votes > 0 then -- if the majority thinks he should be banned
			if punishData.ban then
				util.SetPData(targetSteamID, self.BanDurationString, os.time() + punishData.ban * 60) -- ban the player
			end
			
			util.SetPData(self.PunishLevelString, (util.GetPData(targetSteamID, self.PunishLevelString) or 1) + 1) -- increase the punish level
			
			if playerValid then
				self:verifyPunishment(affectedPlayer, true)
			end
		end
		
		if playerValid then
			affectedPlayer.inPunishVote = false
		end
		
		util.SetPData(targetSteamID, self.TKCounterString, 0) -- either way we reset the target's team kill counter
	end)
end

function GM:updateTKCount(target)
	if not self.RoundOver then
		target:increaseTeamKillCounter()
		
		if target:getTeamKillCounter() >= GAMEMODE.TKsForPunishVote then
			self:startPunishVote(target)
		end
	end
end

function GM:verifyPunishment(target, freshBan)
	local banDuration = target:GetPData(self.BanDurationString)
	local curTime = os.time()
	
	if banDuration and curTime < banDuration then
		local baseText = freshBan and "You've been banned for excessive teamkilling. Ban duration: " or "You're still banned for teamkilling. Ban time left: "
		target:Kick(baseText .. math.ceil((banDuration - curTime) / 60) .. " hour(s)")
	else
		if freshBan then
			target:Kick("You were kicked for excessive TK.")
		end
	end
end

local PLAYER = FindMetaTable("Player")

function PLAYER:getTeamKillCounter()
	return tonumber((self:GetPData(GAMEMODE.TKCounterString) or 0))
end

function PLAYER:getPunishLevel()
	return tonumber((self:GetPData(GAMEMODE.PunishLevelString) or 1))
end

function PLAYER:increasePunishLevel()
	self:SetPData(GAMEMODE.PunishLevelString, self:getPunishLevel() + 1)
end

function PLAYER:setPunishLevel(lev)
	self:SetPData(GAMEMODE.PunishLevelString, lev)
end

function PLAYER:increaseTeamKillCounter()
	self:SetPData(GAMEMODE.TKCounterString, self:getTeamKillCounter() + 1)
end