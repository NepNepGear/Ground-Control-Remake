AddCSLuaFile()
AddCSLuaFile("cl_events.lua")

if CLIENT then
	include("cl_events.lua")
end

GM.EventsByName = {}
GM.EventsByID = {}
GM.EmptyTable = {}

function GM:registerEvent(eventName, display, tipId)
	local eventId = #self.EventsByID + 1
	local data = {eventName = eventName, eventId = eventId, display = display, tipId = tipId}
	
	self.EventsByName[eventName] = data
	self.EventsByID[eventId] = data
end

GM:registerEvent("ENEMY_KILLED", "Enemy down", "KILLED_ENEMY")
GM:registerEvent("KILL_ASSIST", "Kill assist")
GM:registerEvent("TEAMMATE_RESUPPLIED", "Teammate resupplied")
GM:registerEvent("TEAMMATE_BANDAGED", "Teammate bandaged")
GM:registerEvent("TEAMMATE_SAVED", "Saved teammate")
GM:registerEvent("TEAMMATE_HELPED", "Helped teammate")
GM:registerEvent("CLOSE_CALL", "Close call")
GM:registerEvent("WON_ROUND", "Round won")
GM:registerEvent("HEADSHOT", "Headshot")
GM:registerEvent("SPOT_KILL", "Spot kill")
GM:registerEvent("ONE_MAN_ARMY", "One man army")
GM:registerEvent("REPORT_ENEMY_DEATH", "Reported enemy death")
GM:registerEvent("TEAMKILL", "Teamkill")
GM:registerEvent("OBJECTIVE_CAPTURED", "Objective captured")
GM:registerEvent("WAVE_WON", "Wave won")
GM:registerEvent("RETURNED_DRUGS", "Returned drugs")
GM:registerEvent("KILLED_DRUG_CARRIER", "Killed drug carrier")
GM:registerEvent("SECURED_DRUGS", "Secured drugs")
GM:registerEvent("TOOK_DRUGS", "Took drugs")

if SERVER then
	util.AddNetworkString("GC_EVENT")
end

GM.EventData = {}

function GM:getEventIdFromName(eventName)
	return self.EventsByName[eventName].eventId
end

function GM:getEventById(eventId)
	return self.EventsByID[eventId]
end

function GM:getEventByName(eventName)
	return self.EventsByName[eventName]
end

function GM:getEventId(eventData)
	return eventData.id
end