--[[
	if you're looking through code in hopes of finding backdoors/etc - rest assured there are none
	if you find some weird console commands that do weird stuff (like adjust health, or set a team for all players or whatever) please let me know, it's debug code that I have forgotten to remove
	thank you for understanding!
]]--

GM.AutoUpdateConVars = {}

function GM:registerAutoUpdateConVar(cvarName, onChangedCallback)
	self.AutoUpdateConVars[cvarName] = onChangedCallback
	
	cvars.AddChangeCallback(cvarName, onChangedCallback)
end

function GM:performOnChangedCvarCallbacks()
	for cvarName, callback in pairs(self.AutoUpdateConVars) do
		local curValue = GetConVar(cvarName)
		local finalValue = curValue:GetInt() or curValue:GetFloat() or curValue:GetString() -- we don't know whether the callback wants a string or a number, so if we can get a valid number from it, we will use that if we can't, we will use a string value
		
		callback(cvarName, finalValue, finalValue)
	end
end

include("sh_mixins.lua")

include("sv_player_bleeding.lua")
include("sv_player_adrenaline.lua")
include("sv_player_stamina.lua")
include("sv_player_health_regen.lua")
include("sv_general.lua")

include('shared.lua')
include("sv_player.lua")
include("sv_loop.lua")
include("sh_keybind.lua")
include("sh_action_to_key.lua")
include("sh_events.lua")
include("sh_general.lua")
include("sv_player_weight.lua")
include("sv_player_gadgets.lua")
include("sv_player_cash.lua")
include("sv_loadout.lua")
include("sv_attachments.lua")
include("sv_team.lua")
include("sv_starting_points.lua")
include("sv_radio.lua")
include("sv_downloads.lua")
include("sv_events.lua")
include("sv_rounds.lua")
include("sv_spectate.lua")
include("sv_player_armor.lua")
include("sv_voting.lua")
include("sv_maprotation.lua")
include("sv_gametypes.lua")
include("sv_votescramble.lua")
include("sv_player_traits.lua")
include("sv_timelimit.lua")
include("sv_custom_spawn_points.lua")
include("sv_remove_entities.lua")
include("sv_autobalance.lua")
include("sv_autodownload_map.lua")
include("sv_autopunish.lua")
include("sv_map_start_callbacks.lua")
include("sh_tip_controller.lua")
include("sh_entity_initializer.lua")
include("sh_announcer.lua")
include("sh_climbing.lua")
include("sh_footsteps.lua")
include("sh_status_display.lua")
include("sh_mvp_tracking.lua")
include("sh_config.lua")
include("sv_config.lua")
include("sv_server_name_updater.lua")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_player.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_loop.lua")
AddCSLuaFile("cl_view.lua")
AddCSLuaFile("cl_umsgs.lua")
AddCSLuaFile("cl_gui.lua")
AddCSLuaFile("cl_screen.lua")
AddCSLuaFile("cl_scoreboard.lua")
AddCSLuaFile("cl_music_handler.lua")
AddCSLuaFile("cl_render.lua")
AddCSLuaFile("cl_voice_selection.lua")
AddCSLuaFile("cl_weapon_selection_hud.lua")
AddCSLuaFile("cl_player_counting.lua")
AddCSLuaFile("cl_config.lua")

GM.MemeRadio = true -- hehe, set to true for very funny memes
CreateConVar("gc_meme_radio_chance", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY}) -- in 1000
GM.MVPTracker = mvpTracker.new()

CustomizableWeaponry.canDropWeapon = false -- don't let the players be able to drop weapons using the cw_dropweapon console command

function GM:InitPostEntity()
	self:postInitEntity()
	self:setGametype(self:getGametypeFromConVar())
	self:autoRemoveEntities()
	self:runMapStartCallback()
	
	timer.Simple(1, function()
		self:resetStartingPoints()
	end)
	
	self:verifyAutoDownloadMap()
	
	self:performOnChangedCvarCallbacks()
end

function GM:EntityTakeDamage(target, dmgInfo)
	dmgInfo:SetDamageForce(dmgInfo:GetDamageForce() * 0.5)
	
	if target:IsPlayer() and target.currentTraits then
		local traits = GAMEMODE.Traits
		
		for key, traitConfig in ipairs(target.currentTraits) do
			local traitData = traits[traitConfig[1]][traitConfig[2]]
			
			if traitData.onTakeDamage then
				traitData:onTakeDamage(target, dmgInfo)
			end
		end
	end
end

function GM:PlayerDeathSound()
	return true
end