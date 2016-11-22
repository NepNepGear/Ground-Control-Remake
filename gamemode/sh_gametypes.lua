AddCSLuaFile()

GM.Gametypes = {}
GM.GametypesByName = {}
GM.curGametype = nil
GM.DefaultGametypeID = 1 -- this is what we default to in case something goes wrong when attempting to switch to another gametype

function GM:registerNewGametype(gametypeData)
	table.insert(self.Gametypes, gametypeData)
	self.GametypesByName[gametypeData.name] = gametypeData
end

function GM:setGametype(gameTypeID)
	self.curGametypeID = gameTypeID
	self.curGametype = self.Gametypes[gameTypeID]
	
	if self.curGametype.prepare then
		self.curGametype:prepare()
	end
	
	if SERVER then -- does not do what the method says it does, please look in sv_gametypes.lua to see what it really does (bad name for the method, I know)
		self:removeCurrentGametype()
	end
end

function GM:setGametypeCVarByPrettyName(targetName)
	local key, data = self:getGametypeFromConVar(targetName)
	
	if key then
		self:changeGametype(key)
		game.ConsoleCommand("gc_gametype " .. key .. "\n")
		
		return true
	end
	
	return false
end

function GM:getGametypeNameData(id)
	return id .. " - " .. self.Gametypes[id].prettyName .. " (" .. self.Gametypes[id].name .. ")"
end

function GM:getGametypeFromConVar(targetValue)
	local cvarValue = targetValue and targetValue or GetConVar("gc_gametype"):GetString()
	local newGID = tonumber(cvarValue)
	
	if not newGID then
		local lowered = string.lower(cvarValue)
		
		for key, gametype in ipairs(self.Gametypes) do
			if string.lower(gametype.prettyName) == lowered or string.lower(gametype.name) == lowered then
				return key, gametype
			end
		end
	else
		if self.Gametypes[newGID] then
			return newGID, self.Gametypes[newGID]
		end
	end
	
	-- in case of failure
	print(self:appendHelpText("[GROUND CONTROL] Error - non-existent gametype ID '" .. targetValue .. "', last gametype in gametype table is '" .. GAMEMODE:getGametypeNameData(#self.Gametypes) .. "', resetting to default gametype"))
	return self.DefaultGametypeID, self.Gametypes[self.DefaultGametypeID]
end

GM.HelpText = "\ntype 'gc_gametypelist' to get a list of all valid gametypes\ntype 'gc_gametype_maplist' to get a list of all supported maps for all available gametypes\n"

function GM:appendHelpText(text)
	return text .. self.HelpText
end

-- changes the gametype for the next map
function GM:changeGametype(newGametypeID)
	if not newGametypeID then
		return
	end
	
	local newGID = tonumber(newGametypeID) -- check if the passed on value is a string
	
	if not newGID then -- if it is, attempt to set a gametype by the string we were passed on
		if self:setGametypeCVarByPrettyName(newGametypeID) then -- if it succeeds, stop here
			return true
		end
	end
	
	if newGID then
		local gameTypeData = self.Gametypes[newGID]
		
		if not gameTypeData then -- non-existant gametype, can't switch
			game.ConsoleCommand("gc_gametype " .. self.DefaultGametypeID .. "\n")
			return
		end
		
		local text = "NEXT MAP GAMETYPE: " .. gameTypeData.prettyName
		print("[GROUND CONTROL] " .. text)
		
		umsg.Start("GC_NOTIFICATION")
			umsg.String(text)
		umsg.End()
		
		return true
	else
		print(self:appendHelpText("[GROUND CONTROL] Invalid gametype '" .. tostring(newGametypeID) .. "'\n"))
		return false
	end
end

function GM:getGametypeByID(id)
	return GAMEMODE.Gametypes[id]
end

function GM:initializeGameTypeEntities(gameType)
	local map = string.lower(game.GetMap())
	local objEnts = gameType.objectives[map]

	if objEnts then
		for key, data in ipairs(objEnts) do
			local objEnt = ents.Create(data.objectiveClass)
			objEnt:SetPos(data.pos)
			objEnt:Spawn()
			
			GAMEMODE.entityInitializer:initEntity(objEnt, gameType, data)
			
			table.insert(gameType.objectiveEnts, objEnt)
		end
	end
end

function GM:addObjectivePositionToGametype(gametypeName, map, pos, objectiveClass, additionalData) 
	local gametypeData = self.GametypesByName[gametypeName]
	
	if gametypeData then
		gametypeData.objectives = gametypeData.objectives or {}
		gametypeData.objectives[map] = gametypeData.objectives[map] or {}
		
		table.insert(gametypeData.objectives[map], {pos = pos, objectiveClass = objectiveClass, data = additionalData})
	end
end

function GM:getGametype()
	return self.curGametype
end

--[[
-- the most barebones gametype, commented out because people kept picking it even though it's the most boring one and they thought it had respawns
-- you can use this as a base if you wish, but if you want to know what other methods gametype tables have, please take a look at other available gametypes

local tdm = {}
tdm.name = "tdm"
tdm.prettyName = "Team Deathmatch"

if SERVER then
	tdm.mapRotation = GM:getMapRotation("one_side_rush")
end

if SERVER then
	function tdm:postPlayerDeath(ply) -- check for round over possibility
		GAMEMODE:checkRoundOverPossibility(ply:Team())
	end
	
	function tdm:playerDisconnected(ply)
		local hisTeam = ply:Team()
		
		timer.Simple(0, function() -- nothing fancy, just skip 1 frame and call postPlayerDeath, since 1 frame later the player won't be anywhere in the player tables
			GAMEMODE:checkRoundOverPossibility(hisTeam, true)
		end)
	end
	
	function tdm:playerJoinTeam(ply, teamId)
		GAMEMODE:checkRoundOverPossibility(nil, true)
	end
end

GM:registerNewGametype(tdm)]]--

local oneSideRush = {} -- one side rush because you only need to cap 1 point as the attacker
oneSideRush.name = "onesiderush"
oneSideRush.prettyName = "Rush"
oneSideRush.objectiveEnts = {}
oneSideRush.attackerTeam = TEAM_BLUE
oneSideRush.defenderTeam = TEAM_RED
oneSideRush.swappedTeams = false
oneSideRush.timeLimit = 195
oneSideRush.stopCountdown = true
oneSideRush.objectiveCounter = 0
oneSideRush.spawnDuringPreparation = true

if SERVER then
	oneSideRush.mapRotation = GM:getMapRotation("one_side_rush")
end

function oneSideRush:assignPointID(point)
	self.objectiveCounter = self.objectiveCounter + 1
	point.dt.PointID = self.objectiveCounter
end

function oneSideRush:prepare()
	if CLIENT then
		RunConsoleCommand("gc_team_selection")
	end
end

function oneSideRush:arePointsFree()
	local curTime = CurTime()
	
	for key, obj in ipairs(self.objectiveEnts) do
		if obj.winDelay > curTime then
			return false
		end
	end
	
	return true
end

function oneSideRush.teamSwapCallback(player)
	umsg.Start("GC_NEW_TEAM", player)
		umsg.Short(player:Team())
	umsg.End()
end

function oneSideRush:roundStart()
	if SERVER then
		if not self.swappedTeams then
			if GAMEMODE.RoundsPlayed >= GAMEMODE.RoundsPerMap * 0.5 then
				GAMEMODE:swapTeams(self.attackerTeam, self.defenderTeam, oneSideRush.teamSwapCallback, oneSideRush.teamSwapCallback)
				self.swappedTeams = true
			end
		end
		
		GAMEMODE:setTimeLimit(self.timeLimit)
		
		self.realAttackerTeam = self.attackerTeam
		self.realDefenderTeam = self.defenderTeam
		table.clear(self.objectiveEnts)
		self.stopCountdown = false
		
		GAMEMODE:initializeGameTypeEntities(self)
	end
end

function oneSideRush:think()
	if not self.stopCountdown then
		if GAMEMODE:hasTimeRunOut() and self:arePointsFree() then
			GAMEMODE:endRound(self.realDefenderTeam)
		end
	end
end

function oneSideRush:onTimeRanOut()
	GAMEMODE:endRound(self.defenderTeam)
end

function oneSideRush:onRoundEnded(winTeam)
	table.clear(self.objectiveEnts)
	self.stopCountdown = true
	self.objectiveCounter = 0
end

function oneSideRush:postPlayerDeath(ply) -- check for round over possibility
	GAMEMODE:checkRoundOverPossibility(ply:Team())
end

function oneSideRush:playerDisconnected(ply)
	local hisTeam = ply:Team()
	
	timer.Simple(0, function() -- nothing fancy, just skip 1 frame and call postPlayerDeath, since 1 frame later the player won't be anywhere in the player tables
		GAMEMODE:checkRoundOverPossibility(hisTeam, true)
	end)
end

function oneSideRush:playerJoinTeam(ply, teamId)
	GAMEMODE:checkRoundOverPossibility(nil, true)
	GAMEMODE:sendTimeLimit(ply)
	ply:reSpectate()
end

GM:registerNewGametype(oneSideRush)

GM:addObjectivePositionToGametype("onesiderush", "de_dust2", Vector(1147.345093, 2437.071045, 96.031250), "gc_capture_point")
GM:addObjectivePositionToGametype("onesiderush", "de_dust2", Vector(-1546.877197, 2657.465332, 1.431068), "gc_capture_point")

GM:addObjectivePositionToGametype("onesiderush", "de_port", Vector(-3131.584473, -2.002135, 640.031250), "gc_capture_point", {captureDistance = 256})
GM:addObjectivePositionToGametype("onesiderush", "de_port", Vector(1712.789551, 347.170563, 690.031250), "gc_capture_point", {captureDistance = 300})

GM:addObjectivePositionToGametype("onesiderush", "cs_compound", Vector(1934.429321, -1240.472046, 0.584229), "gc_capture_point", {captureDistance = 256, capturerTeam = TEAM_RED, defenderTeam = TEAM_BLUE})
GM:addObjectivePositionToGametype("onesiderush", "cs_compound", Vector(1772.234375, 623.238525, 0.031250), "gc_capture_point", {captureDistance = 256, capturerTeam = TEAM_RED, defenderTeam = TEAM_BLUE})

GM:addObjectivePositionToGametype("onesiderush", "cs_havana", Vector(890.551331, 652.600220, 256.031250), "gc_capture_point", {captureDistance = 256, capturerTeam = TEAM_RED, defenderTeam = TEAM_BLUE})
GM:addObjectivePositionToGametype("onesiderush", "cs_havana", Vector(93.409294, 2024.913696, 16.031250), "gc_capture_point", {captureDistance = 256, capturerTeam = TEAM_RED, defenderTeam = TEAM_BLUE})

GM:addObjectivePositionToGametype("onesiderush", "de_aztec", Vector(-290.273560, -1489.696289, -226.568970), "gc_capture_point", {captureDistance = 256})
GM:addObjectivePositionToGametype("onesiderush", "de_aztec", Vector(-1846.402222, 1074.247803, -221.927124), "gc_capture_point", {captureDistance = 256})

GM:addObjectivePositionToGametype("onesiderush", "de_cbble", Vector(-2751.983643, -1788.725342, 48.025673), "gc_capture_point", {captureDistance = 256})
GM:addObjectivePositionToGametype("onesiderush", "de_cbble", Vector(824.860535, -977.904724, -127.968750), "gc_capture_point", {captureDistance = 256})

GM:addObjectivePositionToGametype("onesiderush", "de_chateau", Vector(137.296066, 999.551453, 0.031250), "gc_capture_point", {captureDistance = 256})
GM:addObjectivePositionToGametype("onesiderush", "de_chateau", Vector(2242.166260, 1220.794800, 0.031250), "gc_capture_point", {captureDistance = 256})

GM:addObjectivePositionToGametype("onesiderush", "de_dust", Vector(122.117203, -1576.552856, 64.031250), "gc_capture_point", {captureDistance = 256})
GM:addObjectivePositionToGametype("onesiderush", "de_dust", Vector(1998.848999, 594.460327, 3.472847), "gc_capture_point", {captureDistance = 256})

GM:addObjectivePositionToGametype("onesiderush", "de_inferno", Vector(2088.574707, 445.291107, 160.031250), "gc_capture_point", {captureDistance = 256})
GM:addObjectivePositionToGametype("onesiderush", "de_inferno", Vector(396.628296, 2605.968750, 164.031250), "gc_capture_point", {captureDistance = 256})

GM:addObjectivePositionToGametype("onesiderush", "de_nuke", Vector(706.493347, -963.940552, -415.968750), "gc_capture_point", {captureDistance = 256})
GM:addObjectivePositionToGametype("onesiderush", "de_nuke", Vector(619.076172, -955.975037, -767.968750), "gc_capture_point", {captureDistance = 256})

GM:addObjectivePositionToGametype("onesiderush", "de_piranesi", Vector(-1656.252563, 2382.538818, 224.031250), "gc_capture_point", {captureDistance = 256})
GM:addObjectivePositionToGametype("onesiderush", "de_piranesi", Vector(-258.952271, -692.915649, 96.031250), "gc_capture_point", {captureDistance = 256})

GM:addObjectivePositionToGametype("onesiderush", "de_tides", Vector(-182.13874816895, -425.63604736328, 0.03125), "gc_capture_point", {captureDistance = 230})
GM:addObjectivePositionToGametype("onesiderush", "de_tides", Vector(-1120.269531, -1442.878418, -122.518227), "gc_capture_point", {captureDistance = 230})

GM:addObjectivePositionToGametype("onesiderush", "dm_runoff", Vector(10341.602539, 1974.626709, -255.968750), "gc_capture_point", {captureDistance = 256})

GM:addObjectivePositionToGametype("onesiderush", "de_train", Vector(1322.792725, -250.027832, -215.968750), "gc_capture_point", {captureDistance = 192})
GM:addObjectivePositionToGametype("onesiderush", "de_train", Vector(32.309258, -1397.823120, -351.968750), "gc_capture_point", {captureDistance = 192})

GM:addObjectivePositionToGametype("onesiderush", "cs_assault", Vector(6733.837402, 4496.704590, -861.968750), "gc_capture_point", {captureDistance = 220, capturerTeam = TEAM_RED, defenderTeam = TEAM_BLUE})
GM:addObjectivePositionToGametype("onesiderush", "cs_assault", Vector(6326.040527, 4106.064453, -606.738403), "gc_capture_point", {captureDistance = 220, capturerTeam = TEAM_RED, defenderTeam = TEAM_BLUE})

GM:addObjectivePositionToGametype("onesiderush", "de_prodigy", Vector(408.281616, -492.238770, -207.968750), "gc_capture_point", {captureDistance = 220})
GM:addObjectivePositionToGametype("onesiderush", "de_prodigy", Vector(1978.739258, -277.940277, -415.968750), "gc_capture_point", {captureDistance = 220})

GM:addObjectivePositionToGametype("onesiderush", "de_desert_atrocity_v3", Vector(384.5167, -1567.5787, -2.5376), "gc_capture_point", {captureDistance = 200})
GM:addObjectivePositionToGametype("onesiderush", "de_desert_atrocity_v3", Vector(3832.3855, -2022.0819, 248.0313), "gc_capture_point", {captureDistance = 200})

GM:addObjectivePositionToGametype("onesiderush", "de_secretcamp", Vector(90.6324, 200.1089, -87.9687), "gc_capture_point", {captureDistance = 200})
GM:addObjectivePositionToGametype("onesiderush", "de_secretcamp", Vector(-45.6821, 1882.2468, -119.9687), "gc_capture_point", {captureDistance = 200})

GM:addObjectivePositionToGametype("contendedpoint", "rp_outercanals", Vector(-1029.633667, -22.739532, 0.031250), "gc_contended_point", {captureDistance = 384})

-- ASSAULT GAMETYPE

local assault = {}
assault.name = "assault"
assault.prettyName = "Assault"
assault.attackerTeam = TEAM_RED
assault.defenderTeam = TEAM_BLUE
assault.timeLimit = 315
assault.stopCountdown = true
assault.attackersPerDefenders = 3
assault.objectiveCounter = 0
assault.spawnDuringPreparation = true
assault.objectiveEnts = {}

if SERVER then
	assault.mapRotation = GM:getMapRotation("assault_maps")
	
	GM.StartingPoints.rp_downtown_v2 = {
		[TEAM_BLUE] = {
			assault = {
				{position = Vector(1229.6053, 1217.8403, -195.9687), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(1129.8442, 1216.5354, -203.9687), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(1054.2517, 1215.5464, -203.9687), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(968.0956, 1214.4189, -195.9687), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(930.4415, 1278.582, -195.9687), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(929.465, 1362.9808, -195.9687), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(1027.2296, 1333.2775, -200.7752), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(1123.923, 1334.3507, -203.9687), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(1213.5834, 1335.5228, -195.9687), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(1235.2239, 1416.9071, -195.9687), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(1175.3423, 1454.0934, -195.9687), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(1096.2295, 1453.2295, -203.9687), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(1020.6302, 1452.2424, -199.1253), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(953.8265, 1451.3683, -195.9687), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(927.4063, 1525.8455, -195.9687), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(1008.4684, 1551.7803, -196.1028), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(1087.5789, 1552.8534, -203.9687), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(1166.6895, 1553.8884, -196.2973), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(1232.5876, 1554.7507, -195.9687), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(1257.8757, 1623.142, -195.9687), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(1194.9629, 1657.7408, -195.9687), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(1105.3007, 1656.7305, -203.9687), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(1022.6866, 1655.651, -199.6394), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(931.2745, 1654.4548, -195.9687), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(924.8574, 1733.795, -195.9687), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(999.5837, 1763.2145, -195.9687), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(1083.9647, 1764.38, -203.9687), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(1173.6332, 1765.5533, -195.9687), viewAngles = Angle(1.0781, -89.2518, 0)},
				{position = Vector(1243.9458, 1766.4733, -195.9687), viewAngles = Angle(1.0781, -89.2518, 0)}
			}
		},
		
		[TEAM_RED] = { 
			assault = {
				{position = Vector(-1729.4055, -2125.4785, -195.9687), viewAngles = Angle(3.08, 89.542, 0)},
				{position = Vector(-1641.4254, -2126.1833, -195.9687), viewAngles = Angle(3.08, 89.542, 0)},
				{position = Vector(-1513.0774, -2127.2119, -195.9687), viewAngles = Angle(3.08, 89.542, 0)},
				{position = Vector(-1395.2834, -2128.1558, -195.9687), viewAngles = Angle(3.08, 89.542, 0)},
				{position = Vector(-1282.7672, -2129.0574, -203.9688), viewAngles = Angle(3.08, 89.542, 0)},
				{position = Vector(-1189.568, -2129.8042, -203.9687), viewAngles = Angle(3.08, 89.542, 0)},
				{position = Vector(-1110.4552, -2130.4382, -195.9687), viewAngles = Angle(3.08, 89.542, 0)},
				{position = Vector(-1092.9962, -2224.7693, -195.9687), viewAngles = Angle(3.08, 89.542, 0)},
				{position = Vector(-1165.8156, -2267.3735, -195.9687), viewAngles = Angle(3.08, 89.542, 0)},
				{position = Vector(-1271.885, -2266.6086, -203.9687), viewAngles = Angle(3.08, 89.542, 0)},
				{position = Vector(-1373.8727, -2265.7913, -203.9687), viewAngles = Angle(3.08, 89.542, 0)},
				{position = Vector(-1482.8696, -2264.9177, -203.9687), viewAngles = Angle(3.08, 89.542, 0)},
				{position = Vector(-1591.8787, -2264.0442, -203.9687), viewAngles = Angle(3.08, 89.542, 0)},
				{position = Vector(-1686.8107, -2263.2839, -203.9687), viewAngles = Angle(3.08, 89.542, 0)},
				{position = Vector(-1778.226, -2262.5513, -203.9687), viewAngles = Angle(3.08, 89.542, 0)},
				{position = Vector(-1788.5939, -2359.5466, -195.9687), viewAngles = Angle(3.08, 89.542, 0)},
				{position = Vector(-1714.2246, -2360.1423, -195.9687), viewAngles = Angle(3.08, 89.542, 0)},
				{position = Vector(-1606.9722, -2361.002, -195.9688), viewAngles = Angle(3.08, 89.542, 0)},
				{position = Vector(-1501.4767, -2361.8472, -195.9687), viewAngles = Angle(3.08, 89.542, 0)},
				{position = Vector(-1392.4775, -2362.7207, -195.9688), viewAngles = Angle(3.08, 89.542, 0)},
				{position = Vector(-1294.0206, -2363.5098, -195.9687), viewAngles = Angle(3.08, 89.542, 0)},
				{position = Vector(-1195.5615, -2364.2986, -195.9687), viewAngles = Angle(3.08, 89.542, 0)},
				{position = Vector(-1107.6656, -2365.0027, -195.9687), viewAngles = Angle(3.08, 89.542, 0)}
			}
		}
	}
	
	GM.StartingPoints.gc_depot_b1 = {
		[TEAM_BLUE] = {
			assault = {
				{position = Vector(-1618.8689, 2796.8894, 66.6748), viewAngles = Angle(0.2685, -171.761, 0)},
				{position = Vector(-1618.6715, 2707.21, 73.6909), viewAngles = Angle(0.2685, -171.761, 0)},
				{position = Vector(-1627.6154, 2577.8462, 66.7672), viewAngles = Angle(0.2685, -171.761, 0)},
				{position = Vector(-1750.0087, 2583.9155, 67.2169), viewAngles = Angle(0.2685, -171.761, 0)},
				{position = Vector(-1736.223, 2704.8176, 73.9044), viewAngles = Angle(0.2685, -171.761, 0)},
				{position = Vector(-1720.2286, 2820.3293, 64.8741), viewAngles = Angle(0.2685, -171.761, 0)},
				{position = Vector(-1878.1638, 2814.8813, 65.3227), viewAngles = Angle(0.2685, -171.761, 0)},
				{position = Vector(-1892.5392, 2684.1213, 74.0313), viewAngles = Angle(0.2685, -171.761, 0)},
				{position = Vector(-1896.1056, 2545.5872, 65.8648), viewAngles = Angle(0.2685, -171.761, 0)},
				{position = Vector(-2040.8667, 2554.8818, 64.8845), viewAngles = Angle(0.2685, -171.761, 0)},
				{position = Vector(-2044.1523, 2694.8235, 74.0313), viewAngles = Angle(0.2685, -171.761, 0)},
				{position = Vector(-2058.3352, 2813.9851, 66.8532), viewAngles = Angle(0.2685, -171.761, 0)},
				{position = Vector(-1849.6594, 2887.6018, 64.265), viewAngles = Angle(3.6565, -121.095, 0)},
				{position = Vector(-1857.546, 3027.9277, 64.2491), viewAngles = Angle(2.1165, -94.915, 0)},
				{position = Vector(-1990.9536, 3013.96, 64.1171), viewAngles = Angle(5.8125, -55.183, 0)},
				{position = Vector(-2000.7787, 2898.5366, 64.0855), viewAngles = Angle(2.2705, -20.995, 0)},
				{position = Vector(-1589.6721, 2526.1843, 67.8443), viewAngles = Angle(3.0405, 177.3051, 0)},
				{position = Vector(-1692.2742, 2524.7571, 67.9695), viewAngles = Angle(3.0405, 177.3051, 0)},
				{position = Vector(-1799.2795, 2521.7986, 66.8973), viewAngles = Angle(3.0405, 177.3051, 0)},
				{position = Vector(-1901.7096, 2534.6077, 65.8035), viewAngles = Angle(3.0405, 177.3051, 0)},
				{position = Vector(-1977.3535, 2548.1697, 64.9838), viewAngles = Angle(4.5805, -172.8389, 0)}
			}
		},
		
		[TEAM_RED] = {
			assault = {
				{position = Vector(-8661.4033, 809.8213, 56.0313), viewAngles = Angle(1.1925, 87.5231, 0)},
				{position = Vector(-8730.0781, 812.7924, 56.0313), viewAngles = Angle(1.1925, 87.5231, 0)},
				{position = Vector(-8823.168, 816.8198, 58.5764), viewAngles = Angle(1.1925, 87.5231, 0)},
				{position = Vector(-8911.0098, 820.6203, 57.6216), viewAngles = Angle(1.1925, 87.5231, 0)},
				{position = Vector(-9002.3584, 824.5724, 56.0313), viewAngles = Angle(1.1925, 87.5231, 0)},
				{position = Vector(-9090.2021, 828.3729, 56.0313), viewAngles = Angle(1.1925, 87.5231, 0)},
				{position = Vector(-9181.5332, 832.3242, 56.0313), viewAngles = Angle(1.1925, 87.5231, 0)},
				{position = Vector(-9272.877, 836.2762, 56.0313), viewAngles = Angle(1.1925, 87.5231, 0)},
				{position = Vector(-9350.1572, 839.6197, 56.0313), viewAngles = Angle(1.1925, 87.5231, 0)},
				{position = Vector(-9343.0713, 952.5702, 56.0313), viewAngles = Angle(0.2685, 45.7891, 0)},
				{position = Vector(-9224.6904, 943.3611, 56.0313), viewAngles = Angle(0.8845, 53.4891, 0)},
				{position = Vector(-9072.4326, 938.7414, 56.0313), viewAngles = Angle(2.5785, 60.8811, 0)},
				{position = Vector(-8931.498, 957.9283, 56.0313), viewAngles = Angle(1.0385, 71.1991, 0)},
				{position = Vector(-8776.0117, 960.1288, 56.0313), viewAngles = Angle(1.5005, 77.0511, 0)},
				{position = Vector(-8635.916, 965.4265, 56.0313), viewAngles = Angle(1.3465, 84.4432, 0)},
				{position = Vector(-8499.8955, 989.7739, 64.0313), viewAngles = Angle(1.6545, 90.6033, 0)},
				{position = Vector(-9319.4033, 1007.2581, 56.0313), viewAngles = Angle(2.2705, 43.4792, 0)},
				{position = Vector(-9180.4248, 1025.5707, 56.0313), viewAngles = Angle(2.2705, 43.4792, 0)},
				{position = Vector(-9017.4668, 1001.3421, 56.0313), viewAngles = Angle(1.3465, 59.6492, 0)},
				{position = Vector(-8859.998, 1004.9487, 63.5222), viewAngles = Angle(2.2705, 66.7333, 0)}
			}
		}
	}
end

function assault:assignPointID(point)
	self.objectiveCounter = self.objectiveCounter + 1
	point.dt.PointID = self.objectiveCounter
end

function assault:arePointsFree()
	local curTime = CurTime()
	
	for key, obj in ipairs(self.objectiveEnts) do
		if obj.winDelay and obj.winDelay > curTime then
			return false
		end
	end
	
	return true
end

function assault:prepare()
	if CLIENT then
		RunConsoleCommand("gc_team_selection")
	end
	
	--[[if SERVER then
		local map = string.lower(game.GetMap())
		local startPoints = self.spawnPoints[map]
		
		if startPoints then
			GAMEMODE:setupStartingPoints(TEAM_RED, nil, startPoints[TEAM_RED])
			GAMEMODE:setupStartingPoints(TEAM_BLUE, nil, startPoints[TEAM_BLUE])
		end
	end]]--
end

function assault:think()
	if not self.stopCountdown then
		if GAMEMODE:hasTimeRunOut() and self:arePointsFree() then
			GAMEMODE:endRound(self.defenderTeam)
		end
	end
end

function assault:playerInitialSpawn(ply)
	if GAMEMODE.RoundsPlayed == 0 then
		if #player.GetAll() >= 2 then
			GAMEMODE:endRound(nil)
		end
	end
end

function assault:postPlayerDeath(ply) -- check for round over possibility
	GAMEMODE:checkRoundOverPossibility(ply:Team())
end

function assault:playerDisconnected(ply)
	local hisTeam = ply:Team()
	
	timer.Simple(0, function() -- nothing fancy, just skip 1 frame and call postPlayerDeath, since 1 frame later the player won't be anywhere in the player tables
		GAMEMODE:checkRoundOverPossibility(hisTeam, true)
	end)
end

function assault.teamSwapCallback(player)
	umsg.Start("GC_NEW_TEAM", player)
		umsg.Short(player:Team())
	umsg.End()
end

function assault:roundStart()
	if SERVER then
		GAMEMODE:swapTeams(self.attackerTeam, self.defenderTeam, assault.teamSwapCallback, assault.teamSwapCallback) -- swap teams on every round start
		
		GAMEMODE:setTimeLimit(self.timeLimit)
		
		self.realAttackerTeam = self.attackerTeam
		self.realDefenderTeam = self.defenderTeam
		
		table.clear(self.objectiveEnts)
		self.stopCountdown = false
		
		GAMEMODE:initializeGameTypeEntities(self)
	end
end

function assault:onRoundEnded(winTeam)
	table.clear(self.objectiveEnts)
	self.stopCountdown = true
	self.objectiveCounter = 0
end

function assault:playerJoinTeam(ply, teamId)
	GAMEMODE:checkRoundOverPossibility(nil, true)
	GAMEMODE:sendTimeLimit(ply)
	ply:reSpectate()
end

function assault:deadDraw(w, h)
	if GAMEMODE:getActivePlayerAmount() < 2 then
		draw.ShadowText("This gametype requires at least 2 players, waiting for more people...", "CW_HUD20", w * 0.5, 15, GAMEMODE.HUDColors.white, GAMEMODE.HUDColors.black, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

GM:registerNewGametype(assault)

GM:addObjectivePositionToGametype("assault", "cs_jungle", Vector(560.8469, 334.9528, -127.9688), "gc_capture_point", {captureDistance = 200, capturerTeam = assault.attackerTeam, defenderTeam = assault.defenderTeam})
GM:addObjectivePositionToGametype("assault", "cs_jungle", Vector(1962.2684, 425.7988, -95.9687), "gc_capture_point", {captureDistance = 200, capturerTeam = assault.attackerTeam, defenderTeam = assault.defenderTeam})
GM:addObjectivePositionToGametype("assault", "cs_jungle", Vector(1442.923218, 489.496857, -127.968758), "gc_offlimits_area", {distance = 2048, targetTeam = assault.defenderTeam, inverseFunctioning = true})

GM:addObjectivePositionToGametype("assault", "cs_siege_2010", Vector(3164.2295, -1348.2546, -143.9687), "gc_capture_point", {captureDistance = 200, capturerTeam = assault.attackerTeam, defenderTeam = assault.defenderTeam})
GM:addObjectivePositionToGametype("assault", "cs_siege_2010", Vector(3983.9688, -480.3419, -47.9687), "gc_capture_point", {captureDistance = 200, capturerTeam = assault.attackerTeam, defenderTeam = assault.defenderTeam})
GM:addObjectivePositionToGametype("assault", "cs_siege_2010", Vector(3878.5757, -1108.7665, -143.9687), "gc_offlimits_area", {distance = 2500, targetTeam = assault.defenderTeam, inverseFunctioning = true})

GM:addObjectivePositionToGametype("assault", "gc_outpost", Vector(4718.394, 1762.6437, 0.0313), "gc_capture_point", {captureDistance = 200, capturerTeam = assault.attackerTeam, defenderTeam = assault.defenderTeam})
GM:addObjectivePositionToGametype("assault", "gc_outpost", Vector(3947.8335, 2541.6055, 0.0313), "gc_capture_point", {captureDistance = 200, capturerTeam = assault.attackerTeam, defenderTeam = assault.defenderTeam})
GM:addObjectivePositionToGametype("assault", "gc_outpost", Vector(3147.9561, 1540.1907, -8.068), "gc_offlimits_area", {distance = 2048, targetTeam = assault.defenderTeam, inverseFunctioning = true})

GM:addObjectivePositionToGametype("assault", "rp_downtown_v2", Vector(686.9936, 1363.9843, -195.9687), "gc_capture_point", {captureDistance = 200, capturerTeam = assault.attackerTeam, defenderTeam = assault.defenderTeam})
GM:addObjectivePositionToGametype("assault", "rp_downtown_v2", Vector(-144.8516, 1471.2026, -195.9687), "gc_capture_point", {captureDistance = 200, capturerTeam = assault.attackerTeam, defenderTeam = assault.defenderTeam})
GM:addObjectivePositionToGametype("assault", "rp_downtown_v2", Vector(816.7338, 847.4449, -195.9687), "gc_offlimits_area", {distance = 1400, targetTeam = assault.defenderTeam, inverseFunctioning = true})

GM:addObjectivePositionToGametype("assault", "de_desert_atrocity_v3", Vector(384.5167, -1567.5787, -2.5376), "gc_capture_point", {captureDistance = 200, capturerTeam = assault.defenderTeam, defenderTeam = assault.attackerTeam})
GM:addObjectivePositionToGametype("assault", "de_desert_atrocity_v3", Vector(3832.3855, -2022.0819, 248.0313), "gc_capture_point", {captureDistance = 200, capturerTeam = assault.defenderTeam, defenderTeam = assault.attackerTeam})
GM:addObjectivePositionToGametype("assault", "de_desert_atrocity_v3", Vector(1898.58, -1590.46, 136.0313), "gc_offlimits_area", {distance = 2000, targetTeam = assault.attackerTeam, inverseFunctioning = true})

GM:addObjectivePositionToGametype("assault", "gc_depot_b1", Vector(-5613.4326, 835.7299, 128.0313), "gc_capture_point", {captureDistance = 150, capturerTeam = assault.attackerTeam, defenderTeam = assault.defenderTeam})
GM:addObjectivePositionToGametype("assault", "gc_depot_b1", Vector(-6977.6396, 1933.22, 64.0313), "gc_offlimits_area", {distance = 2000, targetTeam = assault.defenderTeam, inverseFunctioning = true})

local urbanwarfare = {}
urbanwarfare.name = "urbanwarfare"
urbanwarfare.prettyName = "Urban Warfare"
urbanwarfare.timeLimit = 315
urbanwarfare.waveTimeLimit = 135
urbanwarfare.attackersPerDefenders = 3
urbanwarfare.objectiveCounter = 0
urbanwarfare.spawnDuringPreparation = true
urbanwarfare.objectiveEnts = {}
urbanwarfare.startingTickets = 100 -- the amount of tickets that a team starts with
urbanwarfare.ticketsPerPlayer = 2.5 -- amount of tickets to increase per each player on server
urbanwarfare.capturePoint = nil -- the entity responsible for a bulk of the gametype logic, the reference to it is assigned when it is initialized
urbanwarfare.waveWinReward = {cash = 50, exp = 50}

if SERVER then
	urbanwarfare.mapRotation = GM:getMapRotation("urbanwarfare_maps")
	
	GM.StartingPoints.rp_downtown_v4c_v2 = {
		[TEAM_RED] = {
			urbanwarfare = {
				{position = Vector(690.0195, 3803.3743, -203.9687), viewAngles = Angle(13.09, -93.2347, 0)},
				{position = Vector(769.6985, 3802.8523, -203.9687), viewAngles = Angle(3.696, -90.4627, 0)},
				{position = Vector(841.5054, 3802.2739, -203.9687), viewAngles = Angle(3.696, -90.4627, 0)},
				{position = Vector(941.3118, 3801.4734, -203.9687), viewAngles = Angle(3.696, -90.4627, 0)},
				{position = Vector(1057.3527, 3800.5432, -203.9687), viewAngles = Angle(3.696, -90.4627, 0)},
				{position = Vector(1152.2914, 3799.7825, -203.9687), viewAngles = Angle(3.696, -90.4627, 0)},
				{position = Vector(1263.0477, 3798.8953, -203.9687), viewAngles = Angle(3.696, -90.4627, 0)},
				{position = Vector(1372.0547, 3798.0215, -203.9687), viewAngles = Angle(3.696, -90.4627, 0)},
				{position = Vector(1465.8802, 3797.2693, -203.9687), viewAngles = Angle(3.696, -90.4627, 0)},
				{position = Vector(1473.9479, 3876.8828, -203.9687), viewAngles = Angle(3.696, -90.4627, 0)},
				{position = Vector(1400.933, 3877.4688, -203.9687), viewAngles = Angle(3.696, -90.4627, 0)},
				{position = Vector(1297.2017, 3878.3005, -203.9687), viewAngles = Angle(3.696, -90.4627, 0)},
				{position = Vector(1196.9884, 3879.1033, -203.9687), viewAngles = Angle(3.696, -90.4627, 0)},
				{position = Vector(1096.7743, 3879.9063, -203.9687), viewAngles = Angle(3.696, -90.4627, 0)},
				{position = Vector(998.3176, 3880.6951, -203.9687), viewAngles = Angle(3.696, -90.4627, 0)},
				{position = Vector(901.6295, 3881.47, -203.9687), viewAngles = Angle(3.696, -90.4627, 0)},
				{position = Vector(799.6418, 3882.2871, -203.9687), viewAngles = Angle(3.696, -90.4627, 0)}
			}
		},
		
		[TEAM_BLUE] = {
			urbanwarfare = {
				{position = Vector(704.7042, 3883.0476, -203.9687), viewAngles = Angle(3.696, -90.4627, 0)},
				{position = Vector(608.0021, 3883.8225, -203.9687), viewAngles = Angle(3.696, -90.4627, 0)},
				{position = Vector(-670.2028, -4399.5659, -198.9687), viewAngles = Angle(4.004, 90.7955, 0)},
				{position = Vector(-746.2972, -4400.6152, -198.9688), viewAngles = Angle(4.004, 90.7955, 0)},
				{position = Vector(-857.0679, -4402.1406, -198.9687), viewAngles = Angle(4.004, 90.7955, 0)},
				{position = Vector(-951.9993, -4403.4482, -198.9687), viewAngles = Angle(4.004, 90.7955, 0)},
				{position = Vector(-1048.7062, -4404.7803, -198.9687), viewAngles = Angle(4.004, 90.7955, 0)},
				{position = Vector(-1140.1229, -4406.0396, -198.9687), viewAngles = Angle(4.004, 90.7955, 0)},
				{position = Vector(-1235.0531, -4407.3472, -198.9687), viewAngles = Angle(4.004, 90.7955, 0)},
				{position = Vector(-1337.0193, -4408.752, -198.9687), viewAngles = Angle(4.004, 90.7955, 0)},
				{position = Vector(-1433.7092, -4410.0825, -198.9687), viewAngles = Angle(4.004, 90.7955, 0)},
				{position = Vector(-1530.3984, -4411.415, -198.9687), viewAngles = Angle(4.004, 90.7955, 0)},
				{position = Vector(-1621.8171, -4412.6743, -198.9687), viewAngles = Angle(4.004, 90.7955, 0)},
				{position = Vector(-1718.4994, -4414.0054, -198.9687), viewAngles = Angle(4.004, 90.7955, 0)},
				{position = Vector(-1811.6622, -4415.2886, -198.9687), viewAngles = Angle(4.004, 90.7955, 0)},
				{position = Vector(-1906.6072, -4416.5967, -198.9687), viewAngles = Angle(4.004, 90.7955, 0)},
				{position = Vector(-1989.2278, -4417.7344, -198.9687), viewAngles = Angle(4.004, 90.7955, 0)},
				{position = Vector(-2084.1621, -4419.0415, -198.9687), viewAngles = Angle(4.004, 90.7955, 0)},
				{position = Vector(-2179.0879, -4420.3491, -198.9687), viewAngles = Angle(4.004, 90.7955, 0)}
			}
		}
	}
	
	GM.StartingPoints.ph_skyscraper_construct = {
		[TEAM_RED] = {
			urbanwarfare = {
				{position = Vector(774.0888, 983.2716, -127.9687), viewAngles = Angle(10.9339, -89.8191, 0)},
				{position = Vector(774.344, 902.5513, -127.9687), viewAngles = Angle(10.9339, -89.8191, 0)},
				{position = Vector(774.6385, 809.3679, -127.9687), viewAngles = Angle(10.9339, -89.8191, 0)},
				{position = Vector(774.9553, 709.1458, -127.9687), viewAngles = Angle(10.9339, -89.8191, 0)},
				{position = Vector(775.2556, 614.2077, -127.9687), viewAngles = Angle(10.9339, -89.8191, 0)},
				{position = Vector(775.5556, 519.2693, -127.9687), viewAngles = Angle(10.9339, -89.8191, 0)},
				{position = Vector(775.8668, 420.8229, -127.9687), viewAngles = Angle(10.9339, -89.8191, 0)},
				{position = Vector(776.1726, 324.1125, -127.9687), viewAngles = Angle(10.9339, -89.8191, 0)},
				{position = Vector(776.4672, 230.9174, -127.9687), viewAngles = Angle(10.9339, -89.8191, 0)},
				{position = Vector(776.7599, 138.3155, -127.9687), viewAngles = Angle(10.9339, -89.8191, 0)},
				{position = Vector(852.5703, 127.1812, -127.9687), viewAngles = Angle(10.9339, -89.8191, 0)},
				{position = Vector(852.3819, 186.7617, -127.9687), viewAngles = Angle(10.9339, -89.8191, 0)},
				{position = Vector(852.0763, 283.4687, -131.9687), viewAngles = Angle(10.9339, -89.8191, 0)},
				{position = Vector(851.7705, 380.1672, -127.9687), viewAngles = Angle(10.9339, -89.8191, 0)},
				{position = Vector(851.4926, 468.0828, -127.9687), viewAngles = Angle(10.9339, -89.8191, 0)},
				{position = Vector(851.217, 555.2672, -127.9687), viewAngles = Angle(10.9339, -89.8191, 0)},
				{position = Vector(851.1285, 626.7723, -127.9687), viewAngles = Angle(8.3159, 90.0529, 0)},
				{position = Vector(851.0486, 714.6813, -127.9687), viewAngles = Angle(8.3159, 90.0529, 0)},
				{position = Vector(850.9801, 790.283, -127.9687), viewAngles = Angle(8.3159, 90.0529, 0)},
				{position = Vector(850.9099, 867.6542, -127.9687), viewAngles = Angle(8.3159, 90.0529, 0)},
				{position = Vector(850.8647, 917.1987, -127.9687), viewAngles = Angle(8.3159, 90.0529, 0)}
			}
		},
			
		[TEAM_BLUE] = {
			urbanwarfare = {
				{position = Vector(-762.5663, -847.2106, -127.9687), viewAngles = Angle(2.0019, 90.0528, 0)},
				{position = Vector(-762.6284, -779.3649, -127.9687), viewAngles = Angle(2.0019, 90.0528, 0)},
				{position = Vector(-762.7089, -691.1991, -127.9687), viewAngles = Angle(2.0019, 90.0528, 0)},
				{position = Vector(-762.7861, -606.497, -127.9687), viewAngles = Angle(2.0019, 90.0528, 0)},
				{position = Vector(-762.8611, -523.8428, -127.9687), viewAngles = Angle(2.0019, 90.0528, 0)},
				{position = Vector(-762.9329, -444.7097, -127.9687), viewAngles = Angle(2.0019, 90.0528, 0)},
				{position = Vector(-762.9976, -373.6328, -127.9687), viewAngles = Angle(2.0019, 90.0528, 0)},
				{position = Vector(-763.1141, -245.7027, -127.9687), viewAngles = Angle(2.0019, 90.0528, 0)},
				{position = Vector(-763.1843, -168.337, -127.9687), viewAngles = Angle(2.0019, 90.0528, 0)},
				{position = Vector(-763.2594, -85.692, -127.9687), viewAngles = Angle(2.0019, 90.0528, 0)},
				{position = Vector(-823.4547, -44.4427, -127.9687), viewAngles = Angle(2.9259, -88.5871, 0)},
				{position = Vector(-821.9818, -104.148, -127.9687), viewAngles = Angle(2.9259, -88.5871, 0)},
				{position = Vector(-820.1603, -177.9798, -127.9687), viewAngles = Angle(2.9259, -88.5871, 0)},
				{position = Vector(-818.382, -250.0601, -127.9687), viewAngles = Angle(2.9259, -88.5871, 0)},
				{position = Vector(-815.1729, -380.1232, -127.9687), viewAngles = Angle(2.9259, -88.5871, 0)},
				{position = Vector(-813.395, -452.1877, -127.9687), viewAngles = Angle(2.9259, -88.5871, 0)},
				{position = Vector(-811.7037, -520.7379, -127.9687), viewAngles = Angle(2.9259, -88.5871, 0)},
				{position = Vector(-810.0989, -585.7841, -127.9687), viewAngles = Angle(2.9259, -88.5871, 0)},
				{position = Vector(-808.1475, -664.8785, -127.9687), viewAngles = Angle(2.9259, -88.5871, 0)},
				{position = Vector(-806.413, -735.1838, -127.9687), viewAngles = Angle(2.9259, -88.5871, 0)},
				{position = Vector(-804.3742, -817.8115, -127.9687), viewAngles = Angle(2.9259, -88.5871, 0)},
				{position = Vector(-802.6829, -886.3654, -127.9687), viewAngles = Angle(2.9259, -88.5871, 0)}
			}
		}
	}
end

function urbanwarfare:assignPointID(point)
	self.objectiveCounter = self.objectiveCounter + 1
	point.dt.PointID = self.objectiveCounter
end 

function urbanwarfare:endWave(capturer, noTicketDrainForWinners)
	self.waveEnded = true
	
	timer.Simple(0, function()
		for key, ent in ipairs(ents.FindByClass("cw_dropped_weapon")) do
			SafeRemoveEntity(ent)
		end
		
		GAMEMODE:balanceTeams(true)
		
		if capturer then	
			local opposingTeam = GAMEMODE.OpposingTeam[capturer]
			
			if self.capturePoint:getTeamTickets(opposingTeam) == 0 then
				GAMEMODE:endRound(capturer)
			end
		else
			self:checkEndWaveTickets(TEAM_RED)
			self:checkEndWaveTickets(TEAM_BLUE)
		end
		
		self:spawnPlayersNewWave(capturer, TEAM_RED, (capturer and (noTicketDrainForWinners and TEAM_RED == capturer)))
		self:spawnPlayersNewWave(capturer, TEAM_BLUE, (capturer and (noTicketDrainForWinners and TEAM_BLUE == capturer)))
		self.waveEnded = false
	end)
end

function urbanwarfare:checkEndWaveTickets(teamID)
	if self.capturePoint:getTeamTickets(teamID) == 0 then
		GAMEMODE:endRound(GAMEMODE.OpposingTeam[teamID])
	end
end

function urbanwarfare:spawnPlayersNewWave(capturer, teamID, isFree)
	local bypass = false
	local players = team.GetPlayers(teamID)
	
	if capturer and capturer ~= teamID then
		local alive = 0
		
		for key, ply in ipairs(players) do
			if ply:Alive() then
				alive = alive + 1
			end
		end
		
		-- if the enemy team captured the point and noone died on the loser team, then that teams will lose tickets equivalent to the amount of players in their team
		bypass = alive == #players
	end
	
	local lostTickets = 0
	
	for key, ply in ipairs(players) do
		if not isFree or bypass then
			self.capturePoint:drainTicket(teamID)
			lostTickets = lostTickets + 1
		end
			
		if not ply:Alive() then
			ply:Spawn()
		end
		
		if capturer == teamID then
			ply:addCurrency(self.waveWinReward.cash, self.waveWinReward.exp, "WAVE_WON")
		end
	end
	
	for key, ply in ipairs(players) do
		umsg.Start("GC_NEW_WAVE", ply)
			umsg.Short(lostTickets)
		umsg.End()
	end
end

function urbanwarfare:postPlayerDeath(ply) -- check for round over possibility
	self:checkTickets(ply:Team())
end

function urbanwarfare:playerDisconnected(ply)
	local hisTeam = ply:Team()
	
	timer.Simple(0, function() -- nothing fancy, just skip 1 frame and call postPlayerDeath, since 1 frame later the player won't be anywhere in the player tables
		self:checkTickets(hisTeam)
	end)
end

function urbanwarfare:checkTickets(teamID)
	if not IsValid(self.capturePoint) then
		return
	end
	
	if self.capturePoint:getTeamTickets(teamID) == 0 then
		GAMEMODE:checkRoundOverPossibility(teamID)
	else
		self:checkWaveOverPossibility(teamID)
	end
end

function urbanwarfare:checkWaveOverPossibility(teamID)
	local players = team.GetAlivePlayers(teamID)
	
	if players == 0 then
		self.capturePoint:endWave(GAMEMODE.OpposingTeam[teamID], true)
	end
end

function urbanwarfare:prepare()
	if CLIENT then
		RunConsoleCommand("gc_team_selection")
	else
		GAMEMODE.RoundsPerMap = 4
	end
end

function urbanwarfare:onRoundEnded(winTeam)
	self.objectiveCounter = 0
end

function urbanwarfare:playerJoinTeam(ply, teamId)
	GAMEMODE:checkRoundOverPossibility(nil, true)
	GAMEMODE:sendTimeLimit(ply)
	ply:reSpectate()
end

function urbanwarfare:playerInitialSpawn(ply)
	if GAMEMODE.RoundsPlayed == 0 then
		if #player.GetAll() >= 2 then
			GAMEMODE:endRound(nil)
			GAMEMODE.RoundsPlayed = 1
		end
	end
end

function urbanwarfare:roundStart()
	if SERVER then
		GAMEMODE:initializeGameTypeEntities(self)
	end
end

GM:registerNewGametype(urbanwarfare)

GM:addObjectivePositionToGametype("urbanwarfare", "rp_downtown_v4c_v2", Vector(-817.765076, -1202.352417, -195.968750), "gc_urban_warfare_capture_point", {capMin = Vector(-1022.9687, -952.0312, -196), capMax = Vector(-449.0312, -1511.9696, 68.0313)})

GM:addObjectivePositionToGametype("urbanwarfare", "ph_skyscraper_construct", Vector(2.9675, -558.3918, -511.9687), "gc_urban_warfare_capture_point", {capMin = Vector(-159.9687, -991.9687, -515), capMax = Vector(143.6555, -288.0312, -440)})

GM:addObjectivePositionToGametype("urbanwarfare", "de_desert_atrocity_v3", Vector(2424.1348, -920.4495, 120.0313), "gc_urban_warfare_capture_point", {capMin = Vector(2288.031250, -816.031250, 120.031250), capMax = Vector(2598.074951, -1092.377441, 200)})

local ghettoDrugBust = {}
ghettoDrugBust.name = "ghettodrugbust"
ghettoDrugBust.prettyName = "Ghetto Drug Bust"
ghettoDrugBust.preventManualTeamJoining = true
ghettoDrugBust.loadoutTeam = TEAM_RED
ghettoDrugBust.regularTeam = TEAM_BLUE
ghettoDrugBust.timeLimit = 195
ghettoDrugBust.stopCountdown = true
ghettoDrugBust.noTeamBalance = true
ghettoDrugBust.magsToGive = 3
ghettoDrugBust.bandagesToGive = 4
ghettoDrugBust.objectiveEnts = {}
ghettoDrugBust.objectiveCounter = 0
ghettoDrugBust.blueGuyPer = 2.5 -- for every 3rd player, 1 will be a red dude
ghettoDrugBust.voiceOverride = {[ghettoDrugBust.regularTeam] = "ghetto"}
ghettoDrugBust.objectives = {}

ghettoDrugBust.cashPerDrugReturn = 50
ghettoDrugBust.expPerDrugReturn = 50

ghettoDrugBust.cashPerDrugCapture = 100
ghettoDrugBust.expPerDrugCapture = 100

ghettoDrugBust.cashPerDrugCarrierKill = 25
ghettoDrugBust.expPerDrugCarrierKill = 25

ghettoDrugBust.grenadeChance = 20 -- chance that a ghetto team player will receive a grenade upon spawn

ghettoDrugBust.invertedSpawnpoints = {
	de_chateau = true
}
ghettoDrugBust.redTeamWeapons = {
	{weapon = "cw_ak74", chance = 3, mags = 1},
	{weapon = "cw_shorty", chance = 8, mags = 12},
	{weapon = "cw_mac11", chance = 10, mags = 1},
	{weapon = "cw_deagle", chance = 15, mags = 2},
	{weapon = "cw_mr96", chance = 17, mags = 3},
	{weapon = "cw_fiveseven", chance = 35, mags = 2},
	{weapon = "cw_m1911", chance = 40, mags = 4},
	{weapon = "cw_p99", chance = 66, mags = 3},
	{weapon = "cw_makarov", chance = 100, mags = 7}
}

ghettoDrugBust.sidewaysHoldingWeapons = {
	cw_deagle = true,
	cw_mr96 = true,
	cw_fiveseven = true,
	cw_m1911 = true,
	cw_p99 = true,
	cw_makarov = true
}

ghettoDrugBust.sidewaysHoldingBoneOffsets = {
	cw_mr96 = {["Bip01 L UpperArm"] = {target = Vector(0, -30, 0), current = Vector(0, 0, 0)}},
	cw_m1911 = {["arm_controller_01"] = {target = Vector(0, 0, -30), current = Vector(0, 0, 0)}},
	cw_p99 = {["l_forearm"] = {target = Vector(0, 0, 30), current = Vector(0, 0, 0)}},
	cw_fiveseven = {["arm_controller_01"] = {target = Vector(0, 0, -30), current = Vector(0, 0, 0)}},
	cw_makarov = {["Left_U_Arm"] = {target = Vector(30, 0, 0), current = Vector(0, 0, 0)}},
	cw_deagle = {["arm_controller_01"] = {target = Vector(0, 0, -30), current = Vector(0, 0, 0)}},
}

if SERVER then
	ghettoDrugBust.mapRotation = GM:getMapRotation("ghetto_drug_bust_maps")
end

function ghettoDrugBust:skipAttachmentGive(ply)
	return ply:Team() == self.regularTeam
end

function ghettoDrugBust:canHaveAttachments(ply)
	return ply:Team() == self.loadoutTeam
end

function ghettoDrugBust:canReceiveLoadout(ply)
	ply:Give(GAMEMODE.KnifeWeaponClass)
	return ply:Team() == self.loadoutTeam
end

function ghettoDrugBust:pickupDrugs(drugEnt, ply)
	local team = ply:Team()
	
	if team == self.loadoutTeam then
		if not ply.hasDrugs then
			self:giveDrugs(ply)
			return true
		end
	elseif team == self.regularTeam then
		if drugEnt.dt.Dropped and not ply.hasDrugs then
			self:giveDrugs(ply)
			GAMEMODE:startAnnouncement("ghetto", "return_drugs", CurTime(), nil, ply)
			return true
		end
	end
end

function ghettoDrugBust:playerDeath(ply, attacker, dmginfo)
	if ply.hasDrugs then
		if IsValid(attacker) and ply ~= attacker and attacker:IsPlayer() then
			local plyTeam = ply:Team()
			local attackerTeam = attacker:Team()
			
			if plyTeam ~= attackerTeam then -- we grant the killer a cash and exp bonus if they kill the drug carrier of the opposite team
				attacker:addCurrency(self.cashPerDrugCarrierKill, self.expPerDrugCarrierKill, "KILLED_DRUG_CARRIER")
			end
		end
		
		GAMEMODE:startAnnouncement("ghetto", "retrieve_drugs", CurTime(), self.regularTeam)
	
		ghettoDrugBust:dropDrugs(ply)
	end
end

function ghettoDrugBust:giveDrugs(ply)
	if ply:Team() == self.loadoutTeam then
		GAMEMODE:startAnnouncement("ghetto", "drugs_stolen", CurTime(), self.regularTeam)
	end
	
	ply.hasDrugs = true
	SendUserMessage("GC_GOT_DRUGS", ply)
end

function ghettoDrugBust:dropDrugs(ply)
	local pos = ply:GetPos()
	pos.z = pos.z + 20
	
	local ent = ents.Create("gc_drug_package")
	ent:SetPos(pos)
	ent:SetAngles(AngleRand())
	ent:Spawn()
	ent:wakePhysics()
	ent.dt.Dropped = true
	
	ply.hasDrugs = false
end

function ghettoDrugBust:resetRoundData()
	for key, ply in ipairs(player.GetAll()) do
		ply.hasDrugs = false
	end
end

function ghettoDrugBust:removeDrugs(ply)
	ply.hasDrugs = false
	SendUserMessage("GC_DRUGS_REMOVED", ply)
end

function ghettoDrugBust:attemptReturnDrugs(player, host)
	local team = player:Team()
	
	if team == ghettoDrugBust.regularTeam and player.hasDrugs and not host.dt.HasDrugs then
		ghettoDrugBust:removeDrugs(player)
		
		host:createDrugPackageObject()
		player:addCurrency(self.cashPerDrugReturn, self.expPerDrugReturn, "RETURNED_DRUGS")
		GAMEMODE:startAnnouncement("ghetto", "drugs_retrieved", CurTime(), nil, player)
	end
end

function ghettoDrugBust:attemptCaptureDrugs(player, host)
	local team = player:Team()
	
	if team == ghettoDrugBust.loadoutTeam and player.hasDrugs then
		ghettoDrugBust:removeDrugs(player)
		
		player:addCurrency(self.cashPerDrugCapture, self.expPerDrugCapture, "SECURED_DRUGS")
		GAMEMODE:startAnnouncement("ghetto", "drugs_secured", CurTime(), self.regularTeam)
		return true
	end
end

function ghettoDrugBust:playerDisconnected(ply)
	if ply.hasDrugs then
		self:dropDrugs(ply)
	end
	
	local hisTeam = ply:Team()
	
	timer.Simple(0, function() -- nothing fancy, just skip 1 frame and call postPlayerDeath, since 1 frame later the player won't be anywhere in the player tables
		GAMEMODE:checkRoundOverPossibility(hisTeam, true)
	end)
end

function ghettoDrugBust:playerSpawn(ply)
	ply.hasDrugs = false
	
	if ply:Team() ~= self.loadoutTeam then
		CustomizableWeaponry:removeAllAttachments(ply)
		
		ply:StripWeapons()
		ply:RemoveAllAmmo()
		ply:resetGadgetData()
		ply:applyTraits()
	
		ply:resetArmorData()
		ply:sendArmor()
	
		local pickedWeapon = nil
		
		for key, weaponData in ipairs(self.redTeamWeapons) do
			if math.random(1, 100) <= weaponData.chance then
				pickedWeapon = weaponData
				break
			end
		end
		
		-- if for some reason the chance roll failed and no weapon was chosen, we pick one at random
		pickedWeapon = pickedWeapon or self.redTeamWeapons[math.random(1, #self.redTeamWeapons)]
		
		local randIndex = self.redTeamWeapons[math.random(1, #self.redTeamWeapons)]
		local givenWeapon = ply:Give(pickedWeapon.weapon)
		
		ply:GiveAmmo(pickedWeapon.mags * givenWeapon.Primary.ClipSize_Orig, givenWeapon.Primary.Ammo)
		givenWeapon:maxOutWeaponAmmo(givenWeapon.Primary.ClipSize_Orig)
		
		if math.random(1, 100) <= ghettoDrugBust.grenadeChance then
			ply:GiveAmmo(1, "Frag Grenades")
		end
	end
end

function ghettoDrugBust:getDesiredBandageCount(ply)
	if ply:Team() ~= self.loadoutTeam then
		return self.bandagesToGive
	end
	
	return nil
end

function ghettoDrugBust:think()
	if not self.stopCountdown then
		if GAMEMODE:hasTimeRunOut() then
			GAMEMODE:endRound(self.regularTeam)
		end
		
		local curTime = CurTime()
	end
end

function ghettoDrugBust:playerInitialSpawn(ply)
	if GAMEMODE.RoundsPlayed == 0 then
		if #player.GetAll() >= 2 then
			GAMEMODE:endRound(nil)
		end
	end
end

function ghettoDrugBust:postPlayerDeath(ply) -- check for round over possibility
	GAMEMODE:checkRoundOverPossibility(ply:Team())
end

if CLIENT then
	local handsMaterial = Material("models/weapons/v_models/hands/v_hands")
	
	function ghettoDrugBust:adjustHandTexture()
		local ply = LocalPlayer()
		local team = ply:Team()
		
		if team == self.regularTeam then
			ply:setHandTexture("models/weapons/v_models/gc_black_hands/v_hands")
		else
			ply:setHandTexture("models/weapons/v_models/hands/v_hands")
		end
	end
	
	function ghettoDrugBust:think()
		self:adjustHandTexture()
	end
end

function ghettoDrugBust:roundStart()
	if SERVER then
		local players = player.GetAll()
		local gearGuys = math.max(math.floor(#players / self.blueGuyPer), 1) -- aka the dudes who get the cool gear
		GAMEMODE:setTimeLimit(self.timeLimit)
		self.stopCountdown = false
		
		for i = 1, gearGuys do
			local randomIndex = math.random(1, #players)
			local dude = players[randomIndex]
			dude:SetTeam(self.loadoutTeam)
			
			table.remove(players, randomIndex)
		end
		
		for key, ply in ipairs(players) do
			ply:SetTeam(self.regularTeam)
		end
		
		GAMEMODE:initializeGameTypeEntities(self)
	end
end

function ghettoDrugBust:onRoundEnded(winTeam)
	table.clear(self.objectiveEnts)
	self.stopCountdown = true
	self.objectiveCounter = 0
end

function ghettoDrugBust:deadDraw(w, h)
	if GAMEMODE:getActivePlayerAmount() < 2 then
		draw.ShadowText("This gametype requires at least 2 players, waiting for more people...", "CW_HUD20", w * 0.5, 15, GAMEMODE.HUDColors.white, GAMEMODE.HUDColors.black, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

function ghettoDrugBust:adjustSpawnpoint(ply, plyTeam)
	if self.invertedSpawnpoints[GAMEMODE.CurMap] then
		return GAMEMODE.OpposingTeam[plyTeam]
	end
	
	return nil
end

GM:registerNewGametype(ghettoDrugBust)

GM:addObjectivePositionToGametype("ghettodrugbust", "cs_assault", Vector(6794.2886, 3867.2642, -575.0213), "gc_drug_point")
GM:addObjectivePositionToGametype("ghettodrugbust", "cs_assault", Vector(4907.146, 6381.4331, -871.9687), "gc_drug_capture_point")

GM:addObjectivePositionToGametype("ghettodrugbust", "cs_compound", Vector(2303.8857, -710.6038, 31.016), "gc_drug_point")
GM:addObjectivePositionToGametype("ghettodrugbust", "cs_compound", Vector(2053.3057, -1677.0895, 56.0783), "gc_drug_point")
GM:addObjectivePositionToGametype("ghettodrugbust", "cs_compound", Vector(2119.7871, 2032.4009, 8.0313), "gc_drug_capture_point")

GM:addObjectivePositionToGametype("ghettodrugbust", "cs_havana", Vector(415.6184, 1283.9724, 281.7604), "gc_drug_point")
GM:addObjectivePositionToGametype("ghettodrugbust", "cs_havana", Vector(196.039, 807.587, 282.6608), "gc_drug_point")
GM:addObjectivePositionToGametype("ghettodrugbust", "cs_havana", Vector(-255.9446, -774.599, 0.0313), "gc_drug_capture_point")

GM:addObjectivePositionToGametype("ghettodrugbust", "cs_militia", Vector(171.7497, 754.8995, -115.9687), "gc_drug_point")
GM:addObjectivePositionToGametype("ghettodrugbust", "cs_militia", Vector(1287.92, 635.789, -120.620), "gc_drug_point")
GM:addObjectivePositionToGametype("ghettodrugbust", "cs_militia", Vector(489.6373, -2447.677, -169.529), "gc_drug_capture_point")

GM:addObjectivePositionToGametype("ghettodrugbust", "cs_italy", Vector(740.9838, 2303.0881, 168.4486), "gc_drug_point")
GM:addObjectivePositionToGametype("ghettodrugbust", "cs_italy", Vector(-382.8103, 1900.0341, -119.9687), "gc_drug_point")
GM:addObjectivePositionToGametype("ghettodrugbust", "cs_italy", Vector(-697.3092, -1622.7435, -239.9687), "gc_drug_capture_point")

GM:addObjectivePositionToGametype("ghettodrugbust", "de_chateau", Vector(99.3907, 919.5341, 24.0313), "gc_drug_point")
GM:addObjectivePositionToGametype("ghettodrugbust", "de_chateau", Vector(2081.2983, 1444.7068, 36.0313), "gc_drug_point")
GM:addObjectivePositionToGametype("ghettodrugbust", "de_chateau", Vector(1662.7606, -662.5977, -159.9687), "gc_drug_capture_point")

GM:addObjectivePositionToGametype("ghettodrugbust", "de_inferno", Vector(-572.666, -435.3488, 228.9928), "gc_drug_point")
GM:addObjectivePositionToGametype("ghettodrugbust", "de_inferno", Vector(-32.3297, 549.7234, 83.4212), "gc_drug_point")
GM:addObjectivePositionToGametype("ghettodrugbust", "de_inferno", Vector(2377.4863, 2517.3298, 131.9956), "gc_drug_capture_point")

GM:addObjectivePositionToGametype("ghettodrugbust", "de_shanty_v3_fix", Vector(497.7796, -1688.5574, 21.6237), "gc_drug_point")
GM:addObjectivePositionToGametype("ghettodrugbust", "de_shanty_v3_fix", Vector(-203.0704, -1800.5228, 165.4134), "gc_drug_point")
GM:addObjectivePositionToGametype("ghettodrugbust", "de_shanty_v3_fix", Vector(534.512, 19.6704, 6.9165), "gc_drug_capture_point")