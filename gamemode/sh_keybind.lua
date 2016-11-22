AddCSLuaFile()

local trans = {["MOUSE1"] = "LEFT MOUSE BUTTON",
	["MOUSE2"] = "RIGHT MOUSE BUTTON"}
	
local b, e

function GM:getKeyBind(bind)
	b = input.LookupBinding(bind)
	e = trans[b]
	
	return b and ("[" .. (e and e or string.upper(b)) .. "]") or "[NOT BOUND, " .. bind .. "]"
end

if CLIENT then
	function GM:getActionKey(action)
		return self.ActionsToKey[action].bind
	end
end