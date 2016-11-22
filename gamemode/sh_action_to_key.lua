AddCSLuaFile()

if CLIENT then
	GM.ActionsToKey = {}
	GM.KeysToAction = {}

	-- key - the key we want to bind an action to
	-- actionName - the name of the action
	-- conCommand - the console command the player will issue when this key is pressed
	function GM:assignActionToBind(bind, actionName, conCommand, callback)
		local actionData = {bind = bind, actionName = actionName, conCommand = conCommand, callback = callback}
		self.KeysToAction[bind] = actionData
		self.ActionsToKey[actionName] = actionData
	end

	function GM:performAction(bind)
		local actionData = self.KeysToAction[bind]
		
		if actionData then
			RunConsoleCommand(actionData.conCommand)
			
			if callback then
				callback(ply)
				return true
			end
		end
		
		local ply = LocalPlayer()
		
		for key, data in ipairs(ply.gadgets) do
			if data.useKey == bind then
				RunConsoleCommand("gc_use_gadget", key)
				return true
			end
		end
		
		return false
	end
	
	GM:assignActionToBind("+menu", "bandage", "gc_bandage")
	GM:assignActionToBind("+menu_context", "radio_menu", "gc_radio_menu")
end