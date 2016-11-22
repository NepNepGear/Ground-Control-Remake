local PLAYER = FindMetaTable("Player")

function PLAYER:unlockAttachment(attachmentName)
	if not self.ownedAttachments then
		RunConsoleCommand("gc_request_data")
		return
	end
	
	self.ownedAttachments[attachmentName] = true
	
	if IsValid(GAMEMODE.activeAttachmentSelectionHover) then
		GAMEMODE.activeAttachmentSelectionHover:recreateInfoBox()
	end
end

function PLAYER:resetAttachmentData()
	self.ownedAttachments = self.ownedAttachments or {}
	table.clear(self.ownedAttachments)
end

net.Receive("GC_ATTACHMENTS", function(len, ply)
	LocalPlayer().ownedAttachments = net.ReadTable()
end)

usermessage.Hook("GC_UNLOCK_ATTACHMENT", function(data)
	LocalPlayer():unlockAttachment(data:ReadString())
end)