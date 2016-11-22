CreateClientConVar("gc_primary_weapon", GM.DefaultPrimaryIndex, true, true)
CreateClientConVar("gc_primary_mags", GM.DefaultPrimaryMagCount, true, true)

CreateClientConVar("gc_secondary_weapon", GM.DefaultSecondaryIndex, true, true)
CreateClientConVar("gc_secondary_mags", GM.DefaultSecondaryMagCount, true, true)

CreateClientConVar("gc_tertiary_weapon", GM.DefaultTertiaryIndex, true, true)

CreateClientConVar("gc_spare_ammo", GM.DefaultSpareAmmoCount, true, true)

concommand.Add("gc_loadout_menu", function(ply, com, args)
	GAMEMODE:toggleLoadoutMenu()
end)

GM.loadoutMenuPanel = nil

function GM:BuildImaginaryAttachments(isPrimary)
	local targetTable = nil
	
	if isPrimary then
		GAMEMODE.ImaginaryPrimaryAttachments = {}
		targetTable = GAMEMODE.ImaginaryPrimaryAttachments
	else
		GAMEMODE.ImaginarySecondaryAttachments = {}
		targetTable = GAMEMODE.ImaginarySecondaryAttachments
	end

	local cvarTable = isPrimary and GAMEMODE.PrimaryAttachmentStrings or GAMEMODE.SecondaryAttachmentStrings
	
	for key, cvarName in ipairs(cvarTable) do
		targetTable[GetConVar(cvarName):GetString()] = true
	end
end

function GM:toggleMouse()
	local mouseState = false
	
	for key, value in ipairs(self.AllFrames) do
		if IsValid(value) then -- if at least 1 frame is valid, we don't disable the mouse
			mouseState = true
			break
		end
	end

	gui.EnableScreenClicker(mouseState)
end

function GM:closeLoadoutMenu()
	if IsValid(self.curPanel) then
		self.curPanel:Remove()
		self.curPanel = nil
		return
	end
	
	GAMEMODE:toggleMouse()
end

function GM:toggleLoadoutMenu()
	if LocalPlayer():Team() == TEAM_SPECTATOR then
		self:openTeamSelection()
		return
	end
	
	if IsValid(self.curPanel) then
		self.curPanel:Remove()
		self.curPanel = nil
		return
	end
	
	RunConsoleCommand("gc_request_data")
	
	local panel = vgui.Create("GCFrame")
	panel:SetSize(700, 640)
	panel:Center()
	panel:DisableMouseOnClose(true)
	panel:SetTitle("Loadout")
	panel:SetDraggable(false, false)
	panel:MakePopup()
	panel:SetZPos(100)
	
	panel.OnClose = function()
		RunConsoleCommand("gc_ask_for_loadout")
	end
	
	self.curPanel = panel
	self:toggleMouse()
	
	local elementWidth = 120
	local elementHeight = 60
	
	local primaryWeapon = vgui.Create("GCCurWeaponPanel", panel)
	primaryWeapon:SetPos(5, 30)
	primaryWeapon:SetSize(elementWidth, 65)
	primaryWeapon:SetConVar("gc_primary_weapon", true)
	
	self.PrimaryWeaponDisplay = primaryWeapon
	
	local secondaryWeapon = vgui.Create("GCCurWeaponPanel", panel)
	secondaryWeapon:SetPos(5, 100)
	secondaryWeapon:SetSize(elementWidth, 65)
	secondaryWeapon:SetConVar("gc_secondary_weapon", false)
	secondaryWeapon:setRandomColorOffset(0.75)
	
	self.SecondaryWeaponDisplay = secondaryWeapon
	
	-- armor
	local vestSelection = vgui.Create("GCArmorDisplay", panel)
	vestSelection:SetSize(50, 50)
	vestSelection:SetPos(400, 30)
	vestSelection:SetCategory("vest")
	vestSelection:SetConVar("gc_armor_vest")
	vestSelection:CreateButtons()
	
	local weightBar = vgui.Create("GCWeightBar", panel)
	weightBar:SetPos(5, 170)
	weightBar:SetSize(690, 20)
	
	local bandageText = vgui.Create("DLabel", panel)
	bandageText:SetFont("CW_HUD20")
	bandageText:SetText("Bandages")
	bandageText:SetPos(560, 30)
	bandageText:SetTextColor(self.HUDColors.white)
	bandageText:SizeToContents()
	
	local bandageWang = vgui.Create("GCNumberWang", panel)
	bandageWang:SetPos(640, 30)
	bandageWang:SetSize(50, 20)
	bandageWang:SetMin(self.MinBandages)
	bandageWang:SetMax(self.MaxBandages)
	bandageWang:SetConVar("gc_bandages")
	bandageWang:SetNumeric(true)
	
	local bandageText = vgui.Create("DLabel", panel)
	bandageText:SetFont("CW_HUD20")
	bandageText:SetText("Spare ammo")
	bandageText:SetPos(542, 70)
	bandageText:SetTextColor(self.HUDColors.white)
	bandageText:SizeToContents()
	
	local ammoWang = vgui.Create("GCNumberWang", panel)
	ammoWang:SetPos(640, 70)
	ammoWang:SetSize(50, 20)
	ammoWang:SetMin(self.MinSpareAmmo)
	ammoWang:SetMax(self.MaxSpareAmmo)
	ammoWang:SetConVar("gc_spare_ammo")
	ammoWang:SetNumeric(true)
	
	local mainPanel = vgui.Create("Panel", panel)
	mainPanel:SetPos(5, 200)
	mainPanel:SetSize(690, 435)
	mainPanel.Paint = function(self)
		local w, h = self:GetSize()
		
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawOutlinedRect(0, 0, w, h)
		
		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawRect(1, 1, w - 2, h - 2)
	end
	
	local scrollPanel = vgui.Create("DScrollPanel", mainPanel)
	scrollPanel:SetPos(5, 5)
	scrollPanel:SetSize(680, 425)
	scrollPanel.Paint = function(self) 
	end
	
	scrollPanel.VBar.btnUp.Paint = function()
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(2, 2, scrollPanel.VBar.btnUp:GetWide() - 4, scrollPanel.VBar.btnUp:GetTall() - 4)
	end
	
	scrollPanel.VBar.btnDown.Paint = function()
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(2, 2, scrollPanel.VBar.btnUp:GetWide() - 4, scrollPanel.VBar.btnUp:GetTall() - 4)
	end
	
	scrollPanel.VBar.btnGrip.Paint = function()
		local Wide = scrollPanel.VBar.btnGrip:GetWide()
		local Tall = scrollPanel.VBar.btnGrip:GetTall()
		local R = math.Round(Tall * 0.5)
		
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(2, 0, Wide - 4, Tall)
		
		surface.SetDrawColor(255, 210, 0, 255)
		surface.DrawLine(3, R - 4, Wide - 3, R - 4)
		
		surface.DrawRect(3, R - 1, Wide - 6, 2)
		surface.DrawLine(3, R + 3, Wide - 3, R + 3)
	end
	
	scrollPanel.VBar.Paint = function(self)
		local Wide = self:GetWide()
		local Tall = self:GetTall()
		
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawOutlinedRect(0, 0, Wide, Tall)
		
		surface.SetDrawColor(150, 150, 150, 255)
		surface.DrawRect(1, 1, Wide - 2, Tall - 2)
	end
	
	local basePanel = vgui.Create("Panel", scrollPanel)
	
	local maxH = 0
	local curPos = 0
	local curX = 0
	
	for key, data in ipairs(self.PrimaryWeapons) do
		local modelPanel = vgui.Create("GCWeaponPanel", basePanel)
		modelPanel:SetPos(curX, curPos)
		modelPanel:SetSize(elementWidth, elementHeight)
		modelPanel:SetWeapon(self.PrimaryWeapons, key)
		modelPanel:SetConVar("gc_primary_weapon", true)
		modelPanel:SetDescboxType(1)
		
		curPos = curPos + elementHeight + 5
	end
	
	maxH = math.max(maxH, curPos)
	curX = curX + 130
	curPos = 0
	
	for key, data in ipairs(self.SecondaryWeapons) do
		local modelPanel = vgui.Create("GCWeaponPanel", basePanel)
		modelPanel:SetPos(curX, curPos)
		modelPanel:SetSize(elementWidth, elementHeight)
		modelPanel:SetWeapon(self.SecondaryWeapons, key)
		modelPanel:SetConVar("gc_secondary_weapon", false)
		modelPanel:SetDescboxType(1)
		
		curPos = curPos + elementHeight + 5
	end
	
	maxH = math.max(maxH, curPos)
	curPos = 0
	curX = curX + 130
	
	for key, data in ipairs(self.TertiaryWeapons) do
		local modelPanel = vgui.Create("GCWeaponPanel", basePanel)
		modelPanel:SetPos(curX, curPos)
		modelPanel:SetSize(elementWidth, elementHeight)
		modelPanel:SetWeapon(self.TertiaryWeapons, key)
		modelPanel:SetConVar("gc_tertiary_weapon", nil)
		modelPanel:SetDescboxType(2)
		
		curPos = curPos + elementHeight + 5
	end
	
	maxH = math.max(maxH, curPos)
	curX = curX + elementWidth + 10
	
	for key, convar in ipairs(self.TraitConvars) do
		local category = self.Traits[convar]
		curPos = 0
		
		if category then
			for key, data in ipairs(category) do
				local traitPanel = vgui.Create("GCTraitPanel", basePanel)
				traitPanel:SetPos(curX, curPos)
				traitPanel:SetSize(elementHeight, elementHeight)
				traitPanel:SetConVar(convar)
				traitPanel:SetTrait(data)
				traitPanel:SetTraitID(key)
				curPos = curPos + elementHeight + 5
			end
		end
		
		curX = curX + elementHeight + 10
	end
	
	maxH = math.max(maxH, curPos)
	
	basePanel:SetSize(670, maxH)
	scrollPanel:AddItem(basePanel)
	
	GAMEMODE:BuildImaginaryAttachments(true)
	GAMEMODE:BuildImaginaryAttachments(false)
end

GM.LoadoutToSave = {}
GM.LoadoutToWrite = {}
GM.LoadoutSaveDirectory = GM.MainDataDirectory .. "/loadout/"

if not file.IsDir(GM.LoadoutSaveDirectory, "DATA") then
	file.CreateDir(GM.LoadoutSaveDirectory)
end

function GM:setCurrentWeaponLoadout(weaponObject)
	self.currentWeaponLoadout = weaponObject
end

function GM:loadWeaponLoadout(weaponObject)
	local data = file.Read(self.LoadoutSaveDirectory .. weaponObject.ClassName .. ".txt", "DATA")
	
	if data then -- if we've loaded existing data, we set our current attachment cvars to them
		data = util.JSONToTable(data)
		
		if weaponObject.isPrimaryWeapon then
			targetTable = self.PrimaryAttachmentStrings
		else
			targetTable = self.SecondaryAttachmentStrings
		end
		
		--for cvarName, value in pairs(data) do
		for key, cvarName in ipairs(targetTable) do
			local value = data[cvarName]
			RunConsoleCommand(cvarName, value)
		end
	else -- if we haven't, we just set them to nothing
		local targetTable = nil
		
		if weaponObject.isPrimaryWeapon then
			targetTable = self.PrimaryAttachmentStrings
		else
			targetTable = self.SecondaryAttachmentStrings
		end
		
		for key, cvarName in ipairs(targetTable) do
			RunConsoleCommand(cvarName, "")
		end
	end
	
	timer.Simple(0, function()
		GAMEMODE:BuildImaginaryAttachments(weaponObject.isPrimaryWeapon) -- build em so that we get proper dependencies and shit
	end)
end

function GM:saveWeaponLoadout(weaponObject, isPrimary, cvar)
	weaponObject = weaponObject or self.currentWeaponLoadout
	
	if not weaponObject then
		return
	end
	
	local targetTable, targetWeaponTable = nil, nil
	
	if isPrimary then -- write cvar names based on weapon type
		targetTable = self.PrimaryAttachmentStrings
		targetWeaponTable = self.PrimaryWeapons
	else
		targetTable = self.SecondaryAttachmentStrings
		targetWeaponTable = self.SecondaryWeapons
	end
	
	local weaponData = targetWeaponTable[GetConVarNumber(cvar)]
	
	if weaponData then
		table.clear(self.LoadoutToSave)
		
		for key, cvarName in ipairs(targetTable) do
			local cvarValue = GetConVar(cvarName):GetString()
			self.LoadoutToSave[cvarName] = cvarValue
		end
		
		file.Write(self.LoadoutSaveDirectory .. weaponData.weaponClass .. ".txt", util.TableToJSON(self.LoadoutToSave))
	end
end