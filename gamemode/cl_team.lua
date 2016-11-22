CreateClientConVar("gc_desired_team", 0, false, false)

concommand.Add("gc_team_selection", function(ply)
	if GAMEMODE.curGametype.preventManualTeamJoining then
		return
	end
	
	GAMEMODE:openTeamSelection()
end)

function GM:openTeamSelection()
	if IsValid(self.curPanel) then
		self.curPanel:Remove()
		self.curPanel = nil
		return
	end
	
	local panel = vgui.Create("GCFrame")
	panel:SetSize(750, 323)
	panel:Center()
	panel:DisableMouseOnClose(true)
	panel:SetTitle("Team selection")
	panel:SetDraggable(false, false)
	
	self.curPanel = panel
	self:toggleMouse()
	
	local blueButton = vgui.Create("GCTeamSelectionButton", panel)
	blueButton:SetPos(5, 25)
	blueButton:SetSize(370, 292)
	blueButton:SetTeam(TEAM_BLUE)
	
	local redButton = vgui.Create("GCTeamSelectionButton", panel)
	redButton:SetPos(blueButton:GetWide() + 7, 25)
	redButton:SetSize(370, 292)
	redButton:SetTeam(TEAM_RED)
end