include("sh_player_gadgets.lua")

local PLAYER = FindMetaTable("Player")

util.AddNetworkString("GC_GADGETS")

function PLAYER:useGadget(gadgetId)
	local gadget = self.gadgets[gadgetId]
	
	if not gadget then
		return
	end
	
	local baseGadget = GAMEMODE.GadgetsById[gadget.id]
	
	if baseGadget:canUse(self, gadget) then
		baseGadget:use(self, gadget)
		
		if baseGadget:shouldRemove(self, gadget) then
			table.remove(self.gadgets, gadgetId)
		end
		
		if not baseGadget.onDemandGadgetNetwork then
			self:sendGadgets()
		end
	end
end

function PLAYER:setSpareAmmo(amount) -- spare ammo is an independent gadget
	amount = amount or self:GetInfoNum("gc_spare_ammo", 0)
	
	if amount == 0 then
		return
	end
	
	amount = math.Clamp(amount, 0, GAMEMODE.MaxSpareAmmo)
	self:addGadget(self:prepareGadget("spareammo", amount))
end

function PLAYER:giveGadgets()
	self:setSpareAmmo()
	self:sendGadgets()
end

function PLAYER:prepareGadget(gadget, ...)
	local baseData = GAMEMODE.GadgetsById[gadget]
	
	if not baseData then
		return nil
	end
	
	local gadgetData = baseData:prepareObject(ply, ...)
	gadgetData.id = baseData.id
	
	return gadgetData
end

function PLAYER:sendGadgets()
	net.Start("GC_GADGETS")
		net.WriteTable(self.gadgets)
	net.Send(self)
end

concommand.Add("gc_use_gadget", function(ply, com, args)
	if not ply:Alive() then
		return
	end
	
	local gadgetId = args[1]
	
	if not gadgetId then
		return
	end
	
	gadgetId = tonumber(gadgetId)
	ply:useGadget(gadgetId)
end)