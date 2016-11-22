GM.StartingPoints = GM.StartingPoints or {}
GM.ValidStartingPoints = GM.ValidStartingPoints or {}
GM.LastPickedStartPoint = {}

GM.TeamRedFallbackSpawnPoints = {"info_player_counterterrorist", "info_player_rebel"}
GM.TeamBlueFallbackSpawnPoints = {"info_player_terrorist", "info_player_combine"}

local zeroAngles = Angle(0, 0, 0)

function GM:registerStartingPoint(map, team, position, viewAngles, gametype)
	self.StartingPoints[map] = self.StartingPoints[map] or {}
	self.StartingPoints[map][team] = self.StartingPoints[map][team] or {}
	
	local pointData = {position = position, viewAngles = viewAngles or zeroAngles}
	local target = self.StartingPoints[map][team]
	
	if gametype == "all" then -- if we're adding this point to all gametypes, then iterate over all gametypes available and insert it
		for name, data in pairs(self.GametypesByName) do
			target[name] = target[name] or {}
			table.insert(target[name], pointData)
		end
	else -- otherwise insert to a single point
		target[gametype] = target[gametype] or {}
		table.insert(target[gametype], pointData)
	end
end

function GM:clearStartingPoints()
	for key, value in pairs(self.ValidStartingPoints) do
		table.clear(value)
	end
end

function GM:resetStartingPoints()
	self:clearStartingPoints()
	self:setupStartingPoints(TEAM_RED, nil, self:getCustomSpawnPoints(TEAM_RED))
	self:setupStartingPoints(TEAM_BLUE, nil, self:getCustomSpawnPoints(TEAM_BLUE))
	
	for key, entClass in ipairs(self.TeamRedFallbackSpawnPoints) do
		self:setupStartingPoints(TEAM_RED, entClass)
	end
	
	for key, entClass in ipairs(self.TeamBlueFallbackSpawnPoints) do
		self:setupStartingPoints(TEAM_BLUE, entClass)
	end
end

function GM:getCustomSpawnPoints(teamID)
	local baseList = self.StartingPoints[self.CurrentMap]

	if baseList then
		baseList = baseList[teamID]

		if baseList then
			if baseList[self.curGametype.name] then
				return baseList[self.curGametype.name]
			else
				return baseList
			end
		end
	end
	
	return nil
end

function GM:setupStartingPoints(targetTeam, entityClass, positionList)
	self.LastPickedStartPoint[targetTeam] = 0
	self.ValidStartingPoints[targetTeam] = self.ValidStartingPoints[targetTeam] or {}
	
	if not positionList then -- if we weren't given a specific position list, get the registered points for this specific map + team
		local list = self.StartingPoints[self.CurrentMap]
		
		if list then
			list = list[team]
			
			if list then
				if list[self.curGametype.name] then
					positionList = list[self.curGametype.name]
				else
					positionList = list
				end
			end
		end
	end
	
	if positionList then -- if we have a specific position list, we set up valid starting points from that
		for key, data in pairs(positionList) do
			table.insert(self.ValidStartingPoints[targetTeam], self:prepareSpawnPointData(data.position, data.viewAngles))
		end
	end

	if entityClass then -- if we don't, we use the fallback starting points
		local targetTable = self.ValidStartingPoints[targetTeam]
		
		for key, obj in ipairs(ents.FindByClass(entityClass)) do
			table.insert(self.ValidStartingPoints[targetTeam], self:prepareSpawnPointData(obj:GetPos(), obj:GetAngles()))
		end
	end
end

function GM:resetStartPointUseState(targetTeam)
	for index, point in ipairs(self.ValidStartingPoints[targetTeam]) do
		point.used = false
	end
end

function GM:prepareSpawnPointData(position, angle)
	angle = angle or zeroAngles
	
	return {pos = position, ang = angle, used = false}
end

function GM:positionPlayerOnMap(ply)
	local pointData = self:pickValidStartingPoint(ply)
	
	if pointData then
		ply:SetPos(pointData.pos)
		ply:SetEyeAngles(pointData.ang)
		ply:setSpawnPoint(pointData.pos)
	end
end

function GM:pickValidStartingPoint(ply)
	local team = ply:Team()
	
	if self.curGametype.adjustSpawnpoint then
		team = self.curGametype:adjustSpawnpoint(ply, team) or team
	end
	
	if self.curGametype.invertSpawnpoints then
		team = GM.OpposingTeam[team]
	end
	
	local pointTable = self.ValidStartingPoints[team]
	
	if #pointTable == 0 then -- no points in starting point table, return nil
		return nil
	end
	
	self.LastPickedStartPoint[team] = self.LastPickedStartPoint[team] + 1
	local point = pointTable[self.LastPickedStartPoint[team]]
	
	if point then -- if a point exists, we return it
		return point
	else -- if it doesn't, we reset the last point we picked and recursively return a new one
		self.LastPickedStartPoint[team] = 0
		return self:pickValidStartingPoint(ply)
	end
	
	-- nothing was returned - means all points are used up, so reset their used up state, and recursively try to pick a valid start point again
	self:resetStartPointUseState(team)
	return self:pickValidStartingPoint(ply)
end