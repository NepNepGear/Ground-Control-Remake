AddCSLuaFile()

function team.GetAlivePlayers(teamId)
	local alive = 0
	
	for key, obj in ipairs(team.GetPlayers(teamId)) do
		if obj:Alive() then
			alive = alive + 1
		end
	end
	
	return alive
end