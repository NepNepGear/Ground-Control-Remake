CreateClientConVar("gc_desired_voice", 0, true, true)

concommand.Add("gc_voice_menu", function(ply)
	GAMEMODE:openVoiceSelection()
end)

function GM:openVoiceSelection()
	if IsValid(self.curPanel) then
		self.curPanel:Remove()
		self.curPanel = nil
		return
	end
	
	local panel = vgui.Create("GCFrame")
	panel:SetSize(200, 120)
	panel:Center()
	panel:DisableMouseOnClose(true)
	panel:SetTitle("Voice selection")
	panel:SetDraggable(false, false)
	
	self.curPanel = panel
	self:toggleMouse()
	
	local us = vgui.Create("GCVoiceSelectionButton", panel)
	us:SetPos(5, 30)
	us:SetSize(190, 22)
	us:SetVoice("us")
	us:SetTextColor(self.HUDColors.white)
	
	local aus = vgui.Create("GCVoiceSelectionButton", panel)
	aus:SetPos(5, 60)
	aus:SetSize(190, 22)
	aus:SetVoice("aus")
	aus:SetTextColor(self.HUDColors.white)
	
	local rus = vgui.Create("GCVoiceSelectionButton", panel)
	rus:SetPos(5, 90)
	rus:SetSize(190, 22)
	rus:SetVoice("rus")
	rus:SetTextColor(self.HUDColors.white)
end