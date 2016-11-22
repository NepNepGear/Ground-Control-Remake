include("sh_events.lua")

function GM:sendEvent(ply, event, additionalData)
	local eventData = self:getEventByName(event)
	self.EventData.eventId = eventData.eventId
	self.EventData.eventData = additionalData or self.EmptyTable
	
	net.Start("GC_EVENT")
		net.WriteTable(self.EventData)
	net.Send(ply)
end