GM.desiredWeaponToDraw = nil
GM.weaponSelectionAlpha = 0
GM.weaponSelectionTime = 0
GM.weaponSelectionElementWidth = 200
GM.weaponSelectionDesiredElementHeight = 100
GM.weaponSelectionDesiredElementHeightNoAmmoUse = GM.weaponSelectionDesiredElementHeight - 18
GM.weaponSelectionElementHeight = 46
GM.weaponSelectionElementHeightNoAmmoUse = GM.weaponSelectionElementHeight - 18
GM.lastWeaponSelectIndex = 0

surface.CreateFont("GroundControl_SelectIcons", {font = "csd", size = 100, weight = 500, blursize = 0, antialias = true, shadow = false})

local PLAYER = FindMetaTable("Player")

function PLAYER:selectWeaponNicely(weaponObj)
	self.selectWeaponTarget = weaponObj
	GAMEMODE.weaponSelectionTime = 0 -- make it fade out
end

function GM:showWeaponSelection(desiredWeapon)
	local ply = LocalPlayer()
	
	for key, weaponObj in pairs(ply:GetWeapons()) do
		if desiredWeapon == 1 and weaponObj.isPrimaryWeapon then
			self:setDesiredWeaponToDraw(weaponObj, desiredWeapon)
			return true
		elseif desiredWeapon == 2 and not weaponObj.isPrimaryWeapon and not weaponObj.isTertiaryWeapon and not weaponObj.isKnife then
			self:setDesiredWeaponToDraw(weaponObj, desiredWeapon)
			return true
		elseif desiredWeapon == 3 and weaponObj.isTertiaryWeapon then
			self:setDesiredWeaponToDraw(weaponObj, desiredWeapon)
			return true
		elseif desiredWeapon == 4 and weaponObj.isKnife then
			self:setDesiredWeaponToDraw(weaponObj, desiredWeapon)
			return true
		end
	end
	
	return false
end

function GM:cycleWeaponSelection(offset)
	self.lastWeaponSelectIndex = self.lastWeaponSelectIndex + offset
	
	if self.lastWeaponSelectIndex <= 0 then
		self.lastWeaponSelectIndex = 4
	elseif self.lastWeaponSelectIndex >= 5 then
		self.lastWeaponSelectIndex = 1
	end
	
	if self:showWeaponSelection(self.lastWeaponSelectIndex) then
		self:hideRadio()
	end
end

function GM:hideWeaponSelection()
	self.weaponSelectionTime = 0
	self.lastWeaponSelectIndex = 0
end

function GM:setDesiredWeaponToDraw(weaponObj, lastIndex)
	if CurTime() < self.weaponSelectionTime and (IsValid(self.desiredWeaponToDraw) and self.desiredWeaponToDraw == weaponObj) then
		LocalPlayer():selectWeaponNicely(weaponObj)
		return
	end
	
	surface.PlaySound("ground_control/weapon_selection/switch" .. math.random(1, 6) .. ".wav")
	self.desiredWeaponToDraw = weaponObj
	self.weaponSelectionTime = CurTime() + 3
	self.lastWeaponSelectIndex = lastIndex
end

function GM:canSelectDesiredWeapon()
	return IsValid(self.desiredWeaponToDraw) and CurTime() < self.weaponSelectionTime
end

local realWeapons = {}

function GM:drawWeaponSelection(w, h, curTime)
	local ply = LocalPlayer()
	
	if not ply:Alive() then
		self.weaponSelectionTime = 0
		self.weaponSelectionAlpha = 0
	end
	
	if curTime < self.weaponSelectionTime then
		self.weaponSelectionAlpha = math.Approach(self.weaponSelectionAlpha, 1, FrameTime() * 7)
	else
		self.weaponSelectionAlpha = math.Approach(self.weaponSelectionAlpha, 0, FrameTime() * 7)
	end
	
	if self.weaponSelectionAlpha > 0 then
		local totalHeight = 0
		
		local weapons = ply:GetWeapons()
		
		-- because whoever wrote GetWeapons on the client (or maybe the same bug is serverside too), the first index of the weapon table becomes nil when a weapon is removed
		-- to top it all off, it returns a new table each time
		
		-- since the gamemode is designed around 3 weapons max, we're going to assume that players can't have a fourth weapon and assign primary to 1, secondary to 2 and tertiary weapons to 3rd index
		for key, weaponObj in pairs(weapons) do -- get total element height before beginning to draw
			if IsValid(weaponObj) then
				if weaponObj.isPrimaryWeapon then -- primary
					realWeapons[1] = weaponObj
				elseif not weaponObj.isPrimaryWeapon and not weaponObj.isTertiaryWeapon and not weaponObj.isKnife then -- secondary
					realWeapons[2] = weaponObj
				elseif weaponObj.isTertiaryWeapon then -- tertiary
					realWeapons[3] = weaponObj
				elseif weaponObj.isKnife then
					realWeapons[4] = weaponObj
				end
				
				local usesAmmo = weaponObj.Primary.Ammo ~= ""
				
				if weaponObj == self.desiredWeaponToDraw then
					totalHeight = totalHeight + (usesAmmo and self.weaponSelectionDesiredElementHeight or self.weaponSelectionDesiredElementHeightNoAmmoUse)
				else
					totalHeight = totalHeight + (usesAmmo and self.weaponSelectionElementHeight or self.weaponSelectionElementHeightNoAmmoUse)
				end
			end
		end
		
		local startY = h * 0.5 - totalHeight * 0.5
		local startW = 50
		
		local backColor = self.HUDColors.black
		local frontColor = self.HUDColors.white
		backColor.a = 255 * self.weaponSelectionAlpha
		frontColor.a = 255 * self.weaponSelectionAlpha

		for i = 1, 4 do
			local weaponObj = realWeapons[i]
			
			if IsValid(weaponObj) then	
				local isTargetWeapon = weaponObj == self.desiredWeaponToDraw
				local drawY = startY
				local drawH = nil
				
				local usesAmmo = weaponObj.Primary.Ammo ~= ""
				
				if isTargetWeapon then
					local size = usesAmmo and self.weaponSelectionDesiredElementHeight or self.weaponSelectionDesiredElementHeightNoAmmoUse
					startY = startY + size
					drawH = size
					surface.SetDrawColor(0, 0, 0, 200 * self.weaponSelectionAlpha)
				else
					local size = usesAmmo and self.weaponSelectionElementHeight or self.weaponSelectionElementHeightNoAmmoUse
					startY = startY + size
					drawH = size
					surface.SetDrawColor(0, 0, 0, 100 * self.weaponSelectionAlpha)
				end
				
				startY = startY + 5
				surface.DrawRect(startW, drawY, self.weaponSelectionElementWidth, drawH)
				
				local ammoCountColor = self.HUDColors.white
				
				if weaponObj:isLowOnTotalAmmo() then
					ammoCountColor = self.HUDColors.red
				end
				
				if isTargetWeapon then
					draw.ShadowText(weaponObj.PrintName, "CW_HUD20", startW + 5, drawY + 57, self.HUDColors.white, backColor, 1, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
					draw.ShadowText("[" .. i .. "]", "CW_HUD20", self.weaponSelectionElementWidth + startW - 5, drawY + 57, self.HUDColors.white, backColor, 1, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
					
					if weaponObj.IconLetter then
						draw.ShadowText(weaponObj.IconLetter, "GroundControl_SelectIcons", startW + 5, drawY + 5, self.HUDColors.white, backColor, 1, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
					elseif weaponObj.SelectIcon then
						surface.SetDrawColor(0, 0, 0, 255 * self.weaponSelectionAlpha)
						surface.SetTexture(weaponObj.SelectIcon)
						surface.DrawTexturedRect(startW + 5, drawY - 10, 80, 80)
						
						surface.SetDrawColor(255, 255, 255, 255 * self.weaponSelectionAlpha)
						surface.DrawTexturedRect(startW + 4, drawY - 11, 80, 80)
					end
					
					if usesAmmo then
						draw.ShadowText(weaponObj:getMagCapacity() .. " / " .. weaponObj:getReserveAmmoText(), "CW_HUD20", startW + 5, drawY + 77, ammoCountColor, backColor, 1, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
					end
				else
					draw.ShadowText(weaponObj.PrintName, "CW_HUD20", startW + 5, drawY + 3, self.HUDColors.white, backColor, 1, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
					draw.ShadowText("[" .. i .. "]", "CW_HUD20", self.weaponSelectionElementWidth + startW - 5, drawY + 3, self.HUDColors.white, backColor, 1, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
					
					if usesAmmo then
						draw.ShadowText(weaponObj:getMagCapacity() .. " / " .. weaponObj:getReserveAmmoText(), "CW_HUD20", startW + 5, drawY + 23, ammoCountColor, backColor, 1, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
					end
				end
			end
		end
		
		backColor.a = 255
		frontColor.a = 255
	end
end

function GM:StartChat(isTeam)
	self:hideWeaponSelection()
end
