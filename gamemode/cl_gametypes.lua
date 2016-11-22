local function GC_GAMETYPE(um)
	local id = um:ReadShort()
	GAMEMODE:setGametype(id)
end

usermessage.Hook("GC_GAMETYPE", GC_GAMETYPE)