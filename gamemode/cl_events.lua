GM.EventElements = {}

function GM:DisplayEvent(ply, data)
	local id = data.eventId
	local event = {}
	local addData = data.eventData
	
	local eventData = self:getEventById(id)
	event.topText = eventData.display
	event.displayTime = 2
	event.alpha = 0
	event.yOffset = 50
	event.positive = add
	
	if addData then
		if addData.cash then
			self:AddTextToEvent(event, self:GetSign(addData.cash) .. addData.cash .. "$")
			event.positive = addData.cash > 0
		end
		
		if addData.exp and addData.exp ~= 0 then
			self:AddTextToEvent(event, self:GetSign(addData.exp) .. addData.exp .. "EXP")
		end
	end
	
	if eventData.tipId then
		self.tipController:handleEvent(eventData.tipId)
	end
	
	table.insert(self.EventElements, event)
end

function GM:GetSign(value)
	return value > 0 and "+" or ""
end

function GM:AddTextToEvent(eventData, text)
	if eventData.bottomText then
		eventData.bottomText = eventData.bottomText .. " " .. text
	else
		eventData.bottomText = text
	end
	
	eventData.bottomColor = self.HUDColors.green
end

net.Receive("GC_EVENT", function(a, b)
	local ply = LocalPlayer()
	local data = net.ReadTable()
	GAMEMODE:DisplayEvent(ply, data)
end)