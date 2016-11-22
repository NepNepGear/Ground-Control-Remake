local function GC_Armor_Piece(data)
	local index = data:ReadChar()
	local health = data:ReadChar()
	LocalPlayer():updateArmorPiece(index, health)
end

usermessage.Hook("GC_ARMOR_PIECE", GC_Armor_Piece)

net.Receive("GC_ARMOR", function(a, b)
	LocalPlayer():resetArmorData()
	LocalPlayer():setArmor(net.ReadTable())
end)

function GM:drawArmor(ply, baseX, baseY)
	local offset = 0
	local spacing = 60
	
	if ply.armor then
		local curTime = CurTime()
		local frameTime = FrameTime()
		local removeIndex = 1
		local white, black = self.HUDColors.white, self.HUDColors.black
		
		for i = 1, #ply.armor do
			local curPos = baseX + offset
			
			local data = ply.armor[removeIndex]
			local colorFade = curTime > data.colorHold
			
			if data.red > 0 then
				if colorFade then
					data.red = math.Approach(data.red, 0, frameTime * 1000)
				end
			end
		
			if data.health <= 0 then
				data.alpha = math.Approach(data.alpha, 0, frameTime)
			
				if data.alpha == 0 then
					table.remove(ply.armor, removeIndex)
					offset = offset - spacing
				else
					removeIndex = removeIndex + 1
				end
			end
			
			if data.alpha > 0 then
				white.a, black.a = white.a * data.alpha, black.a * data.alpha
				
				surface.SetDrawColor(255, 255 - data.red, 255 - data.red, 255 * data.alpha)
				surface.SetTexture(data.armorData.icon)
				surface.DrawTexturedRect(curPos, baseY - 45, 40, 40)
				
				draw.ShadowText(math.max(data.health, 0) .. "%", "CW_HUD14", curPos + spacing * 0.5 - 10, baseY, white, black, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			
			offset = offset + spacing
		end
		
		white.a, black.a = 255, 255
	end
	
	return offset
end

local PLAYER = FindMetaTable("Player")
PLAYER._armorFlashTime = 0.3
PLAYER._armorFlashRedAmount = 255

function PLAYER:updateArmorPiece(index, newHealth)
	local armorData = self.armor[index]
	local oldHealth = armorData.health
	armorData.health = newHealth
	
	if newHealth < oldHealth then
		self:flashArmorPiece(armorData)
	end
end

function PLAYER:flashArmorPiece(armorData)
	armorData.red = self._armorFlashRedAmount
	armorData.colorHold = CurTime() + self._armorFlashTime
end

function PLAYER:setupArmorPiece(data)
	local armorData = GAMEMODE:getArmorData(data.id, data.category)
	
	data.red = 0
	data.colorHold = 0
	data.alpha = 1
	data.armorData = armorData
end