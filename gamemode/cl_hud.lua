local noDraw = {CHudAmmo = true,
	CHudSecondaryAmmo = true,
	CHudHealth = true,
	CHudBattery = true,
	CHudWeaponSelection = true,
	CHudDamageIndicator = true}

-- use a separate hook, since otherwise GM:HUDPaint wouldn't work
local function CW_HUDShouldDraw(n)		
	if noDraw[n] then
		return false
	end
	
	return true
end

hook.Add("HUDShouldDraw", "CW_HUDShouldDraw", CW_HUDShouldDraw)

GM.Markers = {}

function GM:AddMarker(position, text, color, displayTime)
	table.insert(self.Markers, {position = position, text = text, color = color, displayTime = CurTime() + displayTime})
end

GM.HealthDisplayFont = "CW_HUD40"
GM.BandageDisplayFont = "CW_HUD32"
GM.ActionDisplayFont = "CW_HUD24"
GM.GadgetDisplayFont = "CW_HUD14"
GM.AttachmentSlotDisplayFont = "CW_HUD20"

GM.HUDColors = {white = Color(255, 255, 255, 255),
	black = Color(0, 0, 0, 255),
	blue = Color(122, 168, 255, 255),
	lightRed = Color(255, 137, 119, 255),
	red = Color(255, 100, 86, 255),
	green = Color(190, 255, 190, 255),
	limeYellow = Color(220, 255, 165, 255)
}

GM.Vignette = surface.GetTextureID("ground_control/hud/vignette")
GM.MarkerTexture = surface.GetTextureID("ground_control/hud/marker")
GM.LoadoutAvailableTexture = surface.GetTextureID("ground_control/hud/purchase_available")
GM.WholeScreenAlpha = 0
GM.teamMateMarkerDisplayDistance = 256

local traceData = {}
traceData.mask = bit.bor(CONTENTS_SOLID, CONTENTS_OPAQUE, CONTENTS_MOVEABLE, CONTENTS_DEBRIS, CONTENTS_MONSTER, CONTENTS_HITBOX, 402653442, CONTENTS_WATER) -- ignores transparent stuff

GM.BaseHUDX = 50

function GM:HUDPaint()
	local ply = LocalPlayer()
	local wep = ply:GetActiveWeapon()
	local scrW, scrH = ScrW(), ScrH()
	
	local healthText = nil
	local alive = ply:Alive()
	local curTime = CurTime()
	local frameTime = FrameTime()
	
	if self.DeadState ~= 3 then
		local staminaData = self.StaminaData
		local staminaAlphaTarget = alive and 255 * (1 - ply.stamina / 100) or 255
		staminaData.alpha = Lerp(frameTime * staminaData.approachRate, staminaData.alpha, staminaAlphaTarget)
		
		if staminaData.alpha > 0 then
			surface.SetDrawColor(0, 0, 0, staminaData.alpha)
			surface.SetTexture(self.Vignette)
			surface.DrawTexturedRect(0, 0, scrW, scrH)
		end
		
		local bleedData = self.BleedData
		local targetAlpha = 0
		
		if alive then
			if ply.bleeding then
				if curTime > bleedData.lastPulse then
					bleedData.lastPulse = curTime + bleedData.pulseInterval
				else
					if curTime + bleedData.pulseInterval * 0.66 > bleedData.lastPulse then
						targetAlpha = bleedData.targetAlpha
					end
				end
			end
		end
		
		bleedData.alpha = math.Approach(bleedData.alpha, targetAlpha, frameTime * bleedData.approachRate)
		
		if bleedData.alpha > 0 then
			surface.SetDrawColor(255, 0, 0, bleedData.alpha)
			surface.SetTexture(self.Vignette)
			surface.DrawTexturedRect(0, 0, scrW, scrH)
		end
	end
	
	local midX, midY = scrW * 0.5, scrH * 0.5

	if alive then
		healthText = "HEALTH: " .. ply:Health() .. "%"
		
		surface.SetFont(self.HealthDisplayFont)
		local xSize, ySize = surface.GetTextSize(healthText)
		
		surface.SetFont(self.BandageDisplayFont)
		local bandageText = "BANDAGES: x" .. (ply.bandages or 0)
		local bandageX = surface.GetTextSize(bandageText)
		
		xSize = math.max(bandageX, xSize) -- get the biggest text size for the semi-transparent rectangle
		
		local overallTextHeight = ySize - 7 + 32
		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawRect(50, scrH - 100 - overallTextHeight, xSize + 10, ySize - 7 + 32)
		
		draw.ShadowText(healthText, self.HealthDisplayFont, 55, scrH - 82 - overallTextHeight, self.HUDColors.white, self.HUDColors.black, 1, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.ShadowText(bandageText, self.BandageDisplayFont, 55, scrH - 82 + 32 - overallTextHeight, self.HUDColors.white, self.HUDColors.black, 1, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		--draw.ShadowText(ply.stamina, self.BandageDisplayFont, 55, scrH - 200, self.HUDColors.white, self.HUDColors.black, 1, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		
		local offset = 60
		local baseY = scrH - 50
		offset = offset + self:drawArmor(ply, offset, baseY)
		
		for key, data in ipairs(ply.gadgets) do
			local posX, posY = offset, baseY
			data:draw(posX, posY)
			
			offset = offset + key * 60
		end
		
		local removeIndex = 1
		
		for i = 1, #self.Markers do
			local data = self.Markers[removeIndex]
			
			if curTime > data.displayTime then
				table.remove(self.Markers, removeIndex)
			else
				local coords = data.position:ToScreen()
				
				if coords.visible then
					local dist = math.Dist(coords.x, coords.y, midX, midY)
					local alpha = math.Clamp(dist, 30, 255)
					
					surface.SetDrawColor(data.color.r, data.color.g, data.color.b, alpha)
					surface.SetTexture(self.MarkerTexture)
					surface.DrawTexturedRect(coords.x - 6, coords.y - 16, 12, 12)
					
					self.HUDColors.white.a = alpha
					self.HUDColors.black.a = alpha
					draw.ShadowText(data.text, "CW_HUD14", coords.x - 3, coords.y, self.HUDColors.white, self.HUDColors.black, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
				
				removeIndex = removeIndex + 1
			end
		end
		
		self.HUDColors.white.a = 255
		self.HUDColors.black.a = 255
		
		self:drawWeaponSelection(scrW, scrH, curTime)
		self:drawStatusEffects(scrW, scrH)
		self:drawLoadoutAvailability(scrW, scrH)
	end
	
	self.tipController:draw(scrW, scrH)
	
	if not self:drawVotePanel() then
		self:drawRadioDisplay(frameTime)
	end
	
	local firstElement = self.EventElements[1]
	
	if firstElement then
		if not firstElement.displayed then
			surface.PlaySound("ground_control/misc/notify.mp3")
			firstElement.displayed = true
		end
		
		local curAlpha = firstElement.alpha
		
		self.HUDColors.white.a = curAlpha * 255
		self.HUDColors.black.a = curAlpha * 255
		
		draw.ShadowText(firstElement.topText, "CW_HUD20", midX, midY + 100 + firstElement.yOffset, self.HUDColors.white, self.HUDColors.black, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		
		if firstElement.bottomText then
			local targetColor = nil
			
			if firstElement.positive then
				targetColor = self.HUDColors.green
			else
				targetColor = self.HUDColors.red
			end
			
			targetColor.a = curAlpha * 255
			draw.ShadowText(firstElement.bottomText, "CW_HUD16", midX, midY + 120 + firstElement.yOffset, targetColor, self.HUDColors.black, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			targetColor.a = 255
		end
		
		self.HUDColors.white.a = 255
		self.HUDColors.black.a = 255
		
		firstElement.yOffset = Lerp(frameTime * 20, firstElement.yOffset, 0)
		firstElement.displayTime = firstElement.displayTime - frameTime
		
		if firstElement.displayTime <= 0 then
			firstElement.alpha = math.Approach(firstElement.alpha, 0, frameTime * 10)
			
			if firstElement.alpha == 0 then
				table.remove(self.EventElements, 1)
			end
		else
			firstElement.alpha = Lerp(frameTime * 20, firstElement.alpha, 1)
		end
	end
	
	if self.DeadState == 1 then
		self.WholeScreenAlpha = math.Approach(self.WholeScreenAlpha, 1, frameTime * 8)
	elseif self.DeadState == 3 or self.DeadState == 0 then
		self.WholeScreenAlpha = math.Approach(self.WholeScreenAlpha, 0, frameTime * 8)
	end
	
	if self.WholeScreenAlpha > 0 then
		surface.SetDrawColor(0, 0, 0, 255 * self.WholeScreenAlpha)
		surface.DrawRect(0, 0, scrW, scrH)
	end
	
	if self.DeadState == 3 then
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(0, 0, scrW, 50)
		surface.DrawRect(0, scrH - 50, scrW, 50)
		
		if IsValid(ply.currentSpectateEntity) then
			draw.ShadowText("Spectating " .. ply.currentSpectateEntity:Nick(), "CW_HUD20", midX, scrH - 35, self.HUDColors.white, self.HUDColors.black, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		
		draw.ShadowText(self:getKeyBind("+attack") .. " - change spectate target", "CW_HUD24", midX, scrH - 15, self.HUDColors.white, self.HUDColors.black, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		
		--[[draw.ShadowText(self:getKeyBind(self.TeamSelectionKey) .. " - team selection menu", "CW_HUD24", 5, 45, self.HUDColors.white, self.HUDColors.black, 1, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
		draw.ShadowText(self:getKeyBind(self.LoadoutMenuKey) .. " - loadout menu", "CW_HUD24", midX, 45, self.HUDColors.white, self.HUDColors.black, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		draw.ShadowText(self:getKeyBind(self.RadioMenuKey) .. " - voice selection menu", "CW_HUD24", scrW - 5, 45, self.HUDColors.white, self.HUDColors.black, 1, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)]]--
		
	draw.ShadowText(self:getKeyBind(self.TeamSelectionKey) .. " - team selection menu", "CW_HUD24", 5, 55, self.HUDColors.white, self.HUDColors.black, 1, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.ShadowText(self:getKeyBind(self.LoadoutMenuKey) .. " - loadout menu", "CW_HUD24", 5, 80, self.HUDColors.white, self.HUDColors.black, 1, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.ShadowText(self:getKeyBind(self.RadioMenuKey) .. " - voice selection menu", "CW_HUD24", 5, 105, self.HUDColors.white, self.HUDColors.black, 1, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		
		if self.curGametype.deadDraw then
			self.curGametype:deadDraw(scrW, scrH)
		end
	end
	
	local teamMateMarkerDisplayDistance = GAMEMODE.teamMateMarkerDisplayDistance
	
	local ourShootPos = ply:GetShootPos()
	local ourAimVec = ply:GetAimVector()
	
	traceData.start = ourShootPos
	traceData.filter = ply
	
	self.canTraceForBandaging = false
	
	for key, obj in ipairs(team.GetPlayers(ply:Team())) do
		if obj.withinPVS then -- only draw the player if we can see him, GMod has no clientside ways of checking whether the player is in PVS, check cl_render.lua for the second part of this
			if obj ~= ply and obj:Alive() then
				local pos = obj:GetBonePosition(obj:LookupBone("ValveBiped.Bip01_Head1"))
				
				if pos:Distance(ourShootPos) <= teamMateMarkerDisplayDistance then
					self:drawPlayerMarker(pos, obj, midX, midY)
				else
					local direction = (pos - ourShootPos):GetNormal()
					local dotToGeneralDirection = ourAimVec:DotProduct(direction)
					
					if dotToGeneralDirection >= 0.9 then
						traceData.endpos = traceData.start + direction * 4096
						
						local trace = util.TraceLine(traceData)
						local ent = trace.Entity
						
						if IsValid(ent) then
							if ent == obj then
								self:drawPlayerMarker(pos, obj, midX, midY)
							end
						end
					end
				end
			end
			
			obj.withinPVS = false
		end
	end
	
	if alive then
		if ply.bleeding then
			draw.ShadowText(self:getKeyBind(self:getActionKey("bandage")) .. " - apply bandage", self.ActionDisplayFont, scrW * 0.5, scrH * 0.5 + 50, self.HUDColors.white, self.HUDColors.black, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		else
			if self.canTraceForBandaging then -- only trace for bandage validity if we have drawn the marker of another player
				local bandageTarget = ply:getBandageTarget()
				
				if bandageTarget then
					draw.ShadowText(string.easyformatbykeys("KEY - bandage PLAYER", "KEY", self:getKeyBind(self:getActionKey("bandage")), "PLAYER", bandageTarget:Nick()), self.ActionDisplayFont, scrW * 0.5, scrH * 0.5 + 50, self.HUDColors.white, self.HUDColors.black, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
			end
		end
	end
	
	if ply:Team() ~= TEAM_SPECTATOR then
		for key, obj in ipairs(self.ObjectiveEntities) do
			if IsValid(obj) then
				obj:drawHUD()
			end
		end
		
		for key, obj in ipairs(self.DrawEntities) do
			if IsValid(obj) then
				obj:drawHUD()
			end
		end
	end
	
	self:drawTimeLimit()
	
	self.HUDColors.white.a = 255
	self.HUDColors.black.a = 255
end

GM.LoadoutElementSize = 96
GM.LoadoutElementSizeSpacing = 32
GM.LoadoutFadingOutTimeLeft = 5 -- when time left is less than this until loadout period is over we start fading the icon out
GM.LoadoutFlashTime = 0.5

function GM:drawLoadoutAvailability(w, h)
	--self.loadoutPosition = position
	--self.loadoutDuration = maxDuration
		
	local curTime = CurTime()
	
	if self.loadoutPosition and curTime < self.loadoutDuration then
		local pos = LocalPlayer():GetPos()
		
		if pos:Distance(self.loadoutPosition) <= self.LoadoutDistance then
			local delta = self.loadoutDuration - curTime
			local alpha = 1
			
			if delta <= self.LoadoutFadingOutTimeLeft then
				alpha = math.flash(delta, 1 / self.LoadoutFlashTime)
			end
			
			surface.SetDrawColor(255, 255, 255, 255 * alpha)
			surface.SetTexture(self.LoadoutAvailableTexture)
			surface.DrawTexturedRect(w - self.LoadoutElementSize - self.LoadoutElementSizeSpacing, h * 0.5 - self.LoadoutElementSize * 0.5, self.LoadoutElementSize, self.LoadoutElementSize)
			
			self.HUDColors.white.a, self.HUDColors.black.a = 255 * alpha, 255 * alpha
			
			draw.ShadowText(self:getKeyBind(self.LoadoutMenuKey) .. " - LOADOUT", "CW_HUD20", w - self.LoadoutElementSize * 0.5 - self.LoadoutElementSizeSpacing, h * 0.5 + self.LoadoutElementSize * 0.5, self.HUDColors.white, self.HUDColors.black, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.ShadowText(os.date("%M:%S", delta), "CW_HUD20", w - self.LoadoutElementSize * 0.5 - self.LoadoutElementSizeSpacing, h * 0.5 + self.LoadoutElementSize * 0.5 + 20, self.HUDColors.white, self.HUDColors.black, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end
	
	self.HUDColors.white.a, self.HUDColors.black.a = 255, 255
end

function GM:drawPlayerMarker(pos, obj, midX, midY)
	pos.z = pos.z + 8
	
	local coords = pos:ToScreen()
	surface.SetTexture(self.MarkerTexture)
	
	if coords.visible then
		local dist = math.Dist(coords.x, coords.y, midX, midY)
		local alpha = math.Clamp(dist, 30, 255)
		
		self.HUDColors.white.a = alpha
		self.HUDColors.black.a = alpha
		
		draw.ShadowText(obj:Nick(), "CW_HUD14", coords.x + 4, coords.y - 10, self.HUDColors.white, self.HUDColors.black, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		
		local healthColor = 1 - (obj:Health() / 100)
		surface.SetDrawColor(200 + healthColor * 255, 255 - healthColor * 155, 200 - healthColor * 100, alpha)
		surface.DrawTexturedRect(coords.x, coords.y, 8, 8)
		
		if obj.statusEffects then
			local statusEffects = GAMEMODE.StatusEffects
			local xPos = coords.x + 13
			
			for key, statusEffectID in ipairs(obj.statusEffects.numeric) do
				local data = statusEffects[statusEffectID]
				
				surface.SetTexture(data.texture)
				
				surface.SetDrawColor(0, 0, 0, 255)
				surface.DrawTexturedRect(xPos, coords.y, 10, 10)
				
				surface.SetDrawColor(255, 255, 255, 255)
				surface.DrawTexturedRect(xPos - 1, coords.y - 1, 10, 10)
				
				xPos = xPos + 13
			end
			
			if obj.statusEffects.map.bleeding then -- if the target is bleeding and we can draw his coords, we can then run a trace to check whether we can bandage him
				self.canTraceForBandaging = true
			end
		end
	end
end

function GM:createRoundOverDisplay(winTeam)
	local popup = vgui.Create("GCRoundOver")
	
	if winTeam then
		popup:SetWinningTeam(winTeam)
	else
		popup:SetTopText("New match start")
		popup:SetBottomText("Starting a new game in ")
	end
	
	popup:SetRestartTime(GAMEMODE.RoundRestartTime)
	popup:SetSize(310, 50)
	popup:Center()
	
	local x, y = popup:GetPos()
	popup:SetPos(x, y - 200)
	
	self:clearObjectiveEntities()
	self:clearDrawEntities()
	
	self.lastPopup = popup
end

function GM:createRoundPreparationDisplay(winTeam)
	self:resetVisualAdrenaline()
	self:resetVisualStamina()
	
	local result = vgui.Create("GCRoundPreparation")
	result:SetPrepareTime(GAMEMODE.RoundPreparationTime)
	result:SetSize(310, 50)
	result:Center()
	
	local x, y = result:GetPos()
	result:SetPos(x, y - 200)
	
	self.PreparationTime = CurTime() + self.RoundPreparationTime
	self:playMusic(self.RoundStartMusicObjects[math.random(1, #self.RoundStartMusicObjects)], nil, 0.7)
	
	if self.curGametype.roundStart then
		self.curGametype:roundStart()
	end
	
	self.tipController:handleEvent("WEAPON_CUSTOMIZATION")
	
	self.lastPopup = result
end

function GM:createLastManStandingDisplay()
	local popup = vgui.Create("GCGenericPopup")
	popup:SetText("Last man standing", "Good luck")
	popup:SetExistTime(5)
	popup:SetSize(310, 50)
	popup:Center()
	
	local x, y = popup:GetPos()
	popup:SetPos(x, y - 200)
	
	surface.PlaySound("ground_control/misc/last_man_standing.mp3")
	
	self.lastPopup = popup
end