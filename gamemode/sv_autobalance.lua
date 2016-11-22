function GM:balanceTeams(deadOnly)
	local teamRed, teamBlue = team.GetPlayers(TEAM_RED), team.GetPlayers(TEAM_BLUE)
	local redCount, blueCount = #teamRed, #teamBlue
	
	local countDifference = redCount - blueCount
	local distance = math.abs(countDifference)
	
	if distance > 1 then
		local targetTeam = countDifference > 0 and TEAM_BLUE or TEAM_RED -- team we'll be swapping players into
		local targetPlayers = targetTeam == TEAM_BLUE and teamRed or teamBlue -- team we'll be swapping players out of
		
		self:balanceTeam(targetPlayers, targetTeam, distance, deadOnly)
	end
end

function GM:balanceTeam(playerList, targetTeam, amount, deadOnly)
	local swapAmount = math.floor(amount / 2) -- for every 2 players we switch 1 person to the enemy team
	
	if deadOnly then
		local curIndex = 1
		
		for i = 1, #playerList do
			local ply = playerList[curIndex]
			
			if ply:Alive() then
				table.remove(playerList, curIndex)
			else
				curIndex = curIndex + 1
			end
		end
	end
	
	for i = 1, swapAmount do
		local randomIndex = math.random(1, #playerList)
		local randomPlayer = playerList[randomIndex]
		
		if randomPlayer then
			randomPlayer:autobalancedSwitchTeam(targetTeam)
			table.remove(playerList, randomIndex)
		end
	end
end