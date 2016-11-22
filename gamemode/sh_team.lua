AddCSLuaFile()
AddCSLuaFile("cl_team.lua")

TEAM_RED = 1
TEAM_BLUE = 2

GM.OpposingTeam = {
	[TEAM_RED] = TEAM_BLUE,
	[TEAM_BLUE] = TEAM_RED
}

GM.RegisteredTeamData = {}

GM.TeamRedColor1 = Color(255, 122, 61, 255)
GM.TeamRedColor2 = Color(255, 78, 0, 255)

GM.TeamBlueColor1 = Color(33, 184, 255, 255)
GM.TeamBlueColor2 = Color(58, 120, 255, 255)

team.SetUp(TEAM_RED, "Team Red", Color(255, 109, 144, 255), true)
team.SetUp(TEAM_BLUE, "Team Blue", Color(99, 148, 255, 255), true)

GM.MaxPlayerCountTeamDifference = 1

-- teamBackground is the text displayed in the team selection menu
-- if not defined the text will not be displayed
function GM:registerTeamInfo(teamID, teamName, teamColor, isJoinable, teamBackground, teamTexture, selectionColors)
	team.SetUp(teamID, teamName, teamColor, isJoinable)
	
	local textureID = nil
	
	if CLIENT then
		textureID = surface.GetTextureID(teamTexture)
	end
	
	self.RegisteredTeamData[teamID] = {teamName = teamName, color = teamColor, background = teamBackground, texture = teamTexture, textureID = textureID, selectionColors = selectionColors}
end

GM:registerTeamInfo(TEAM_RED, "Team Red", Color(255, 109, 144, 255), true, "Law enforcement, militia, regular people doing their jobs to keep their cities safe.", "ground_control/hud/team_selection/team_red", {GM.TeamRedColor1, GM.TeamRedColor2})
GM:registerTeamInfo(TEAM_BLUE, "Team Blue", Color(99, 148, 255, 255), true, "Criminals, terrorists, anarchists and regular scum that are always trying to get the upper hand over innocent people.", "ground_control/hud/team_selection/team_blue", {GM.TeamBlueColor1, GM.TeamBlueColor2})

function GM:canJoinTeam(ply, targetTeam)
	if self.curGametype.preventManualTeamJoining then
		return false
	end
	
	if ply:Alive() then
		return -1
	end
	
	local playerTeam = ply:Team()
	
	if playerTeam == targetTeam then
		return -1 -- wtf bro
	end
	
	local oppositeTeam = targetTeam == TEAM_RED and TEAM_BLUE or TEAM_RED
	local difference = team.NumPlayers(targetTeam) - team.NumPlayers(oppositeTeam)
	
	if ply:Team() ~= TEAM_SPECTATOR then -- if we already belong to a team, then we also must take ourselves into account
		difference = difference + 1
	end
	
	if difference > GAMEMODE.MaxPlayerCountTeamDifference then
		return false
	end
	
	return true
end

function GM:attemptJoinTeam(ply, targetTeam)
	if CLIENT then
		RunConsoleCommand("gc_attempt_join_team", targetTeam)
		return
	end
	
	--if not self:canJoinTeam(ply, targetTeam) then
	--	SendUserMessage("GC_RETRYTEAMSELECTION", ply)
	--	return false
	--end
	
	ply:joinTeam(targetTeam)
	
	return true
end

function GM:getAvailableTeam(ply)
	local redAvailable = self:canJoinTeam(ply, TEAM_RED)
	
	if redAvailable == true then
		return TEAM_RED
	end
	
	local blueAvailable = self:canJoinTeam(ply, TEAM_BLUE)
	
	if blueAvailable == true then
		return TEAM_BLUE
	end
	
	return math.random(TEAM_RED, TEAM_BLUE)
end