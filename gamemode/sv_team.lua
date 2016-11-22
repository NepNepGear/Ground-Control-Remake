AddCSLuaFile("cl_team.lua")
include("sh_team.lua")

GM.TeamModels = {}

concommand.Add("gc_attempt_join_team", function(ply, com, data)
	local team = data[1]
	
	if not team then
		return
	end
	
	team = tonumber(team)
	local join = GAMEMODE:canJoinTeam(ply, team)
	
	if join == true then
		GAMEMODE:attemptJoinTeam(ply, team)
		
		umsg.Start("GC_TEAM_SELECTION_SUCCESS", ply)
			umsg.Char(team)
		umsg.End()
	elseif join == false then
		SendUserMessage("GC_RETRYTEAMSELECTION", ply)
	end
end)

function GM:addTeamModel(teamId, model)
	self.TeamModels[teamId] = self.TeamModels[teamId] or {}
	table.insert(self.TeamModels[teamId], model)
end

function GM:getRandomTeamModel(teamId)
	local models = self.TeamModels[teamId]
	return models[math.random(1, #models)]
end

GM:addTeamModel(TEAM_RED, "models/player/riot.mdl")
GM:addTeamModel(TEAM_RED, "models/player/swat.mdl")
GM:addTeamModel(TEAM_RED, "models/player/urban.mdl")
GM:addTeamModel(TEAM_RED, "models/player/gasmask.mdl")

GM:addTeamModel(TEAM_BLUE, "models/player/leet.mdl")
GM:addTeamModel(TEAM_BLUE, "models/player/guerilla.mdl")
GM:addTeamModel(TEAM_BLUE, "models/player/arctic.mdl")
GM:addTeamModel(TEAM_BLUE, "models/player/phoenix.mdl")

local PLAYER = FindMetaTable("Player")

function PLAYER:joinTeam(teamId)
	self:SetTeam(teamId) -- welp
	
	if GAMEMODE.curGametype.playerJoinTeam then
		GAMEMODE.curGametype:playerJoinTeam(self, teamId)
	end
	
	if GAMEMODE.curGametype.spawnDuringPreparation and GAMEMODE:isPreparationPeriod() then
		self:Spawn()
	end
end

function PLAYER:autobalancedSwitchTeam(teamId)
	self:SetTeam(teamId)
	
	umsg.Start("GC_AUTOBALANCED_TO_TEAM", self)
		umsg.Short(teamId)
	umsg.End()
end