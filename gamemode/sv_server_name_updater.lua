--[[
	this small script can be used for automatically updating your server name based on the circumstances (gametype being played, round number)
]]--

CreateConVar("gc_auto_adjust_server_name", 0, {FCVAR_ARCHIVE, FCVAR_NOTIFY})
CreateConVar("gc_base_server_name", "", {FCVAR_ARCHIVE, FCVAR_NOTIFY})
CreateConVar("gc_insert_to_front", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY})

GM.BaseGameInfoString = "GAMETYPE R[CURRENT_ROUND/MAX_ROUND]"
GM.DefaultServerName = "Ground Control"

function GM:updateServerName()
	if GetConVarNumber("gc_auto_adjust_server_name") > 0 then
		local baseServerName = GetConVar("gc_base_server_name"):GetString()
		baseServerName = baseServerName == "" and self.DefaultServerName or baseServerName -- if the base server name was not defined, we will default to 'Ground Control'
		
		local appendable = string.easyformatbykeys(self.BaseGameInfoString, "GAMETYPE", self.curGametype.prettyName, "CURRENT_ROUND", self.RoundsPlayed, "MAX_ROUND", self.RoundsPerMap)
		local finalString = nil
		
		if GetConVarNumber("gc_insert_to_front") >= 1 then
			finalString = baseServerName .. " - " .. appendable
		else
			finalString = appendable .. " - " .. baseServerName
		end
		
		finalString = "hostname " .. finalString .. "\n"
		
		game.ConsoleCommand(finalString)
	end
end

GM:registerAutoUpdateConVar("gc_auto_adjust_server_name", function(cvarName, oldValue, newValue)	
	if tonumber(newValue) and tonumber(newValue) > 0 then
		GAMEMODE:updateServerName()
	end
end)