function GM:createLastManStandingDisplay(teamId)
	local living = 0
	local obj = nil
	
	for key, plyObj in ipairs(team.GetPlayers(teamId)) do
		if plyObj:Alive() then
			living = living + 1
			obj = plyObj
		end
	end
	
	if living == 1 and obj then
		SendUserMessage("GC_LAST_MAN_STANDING", obj)
	end
end

function GM:swapPlayerTeams(players, targetTeam, callback)
	for key, ply in ipairs(players) do
		ply:SetTeam(targetTeam)
		
		if callback then
			callback(ply)
		end
	end
end

function GM:swapTeams(teamOne, teamTwo, teamOneCallback, teamTwoCallback)
	local playersOne = team.GetPlayers(teamOne)
	local playersTwo = team.GetPlayers(teamTwo)
	
	self:swapPlayerTeams(playersOne, teamTwo, teamOneCallback)
	self:swapPlayerTeams(playersTwo, teamOne, teamTwoCallback)
end