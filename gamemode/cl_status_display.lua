include("sh_status_display.lua")

-- displays icons related to the state of the player (crippled arms, bleeding, etc.)

GM.IconSize = 64
GM.IconSpacing = 5
GM.IconScaleStart = 2
GM.SmallScale = 1
GM.BigScaleTime = 0.5
GM.SmallScaleApproachRate = 2

function GM:resetAllStatusEffects() -- on absolutely everyone (ie on round end)
	for key, ply in ipairs(player.GetAll()) do -- on other players
		ply:resetStatusEffects()
	end
	
	self:removeAllStatusEffects() -- on self
end

function GM:showStatusEffect(id) -- on self
	if not LocalPlayer():Alive() then -- should not have status effects added if we're dead
		return
	end
	
	for key, effect in ipairs(self.ActiveStatusEffects) do
		if effect.id == id then
			effect.removed = false
			return
		end
	end
	
	table.insert(self.ActiveStatusEffects, {id = id, scale = self.IconScaleStart, bigScaleTime = CurTime() + self.BigScaleTime})
end

function GM:removeStatusEffect(id) -- on self
	for key, effect in ipairs(self.ActiveStatusEffects) do
		if effect.id == id then
			effect.removed = true
		end
	end
	
	return false
end	

function GM:removeAllStatusEffects() -- on self
	table.clear(self.ActiveStatusEffects)
end

GM.BaseStatusEffectX = GM.BaseHUDX
GM.BaseStatusEffectY = 190

function GM:drawStatusEffects(w, h)
	local xPos = self.BaseStatusEffectX
	local yPos = h - self.BaseStatusEffectY
	local curTime = CurTime()
	local frameTime = FrameTime()
	
	local curIndex = 1
	
	for i = 1, #self.ActiveStatusEffects do
		local effect = self.ActiveStatusEffects[curIndex]
		
		if effect.removed then
			effect.scale = math.Approach(effect.scale, 0, frameTime * self.SmallScaleApproachRate)
			
			if effect.scale == 0 then
				table.remove(self.ActiveStatusEffects, curIndex)
				continue
			end
		else
			if curTime > effect.bigScaleTime then
				effect.scale = math.Approach(effect.scale, self.SmallScale, frameTime * self.SmallScaleApproachRate)
			end
		end
		
		local effectData = self.StatusEffects[effect.id]
		local height = self.IconSize * effect.scale
		
		surface.SetDrawColor(0, 0, 0, 255)
		surface.SetTexture(effectData.texture)
		surface.DrawTexturedRect(xPos + 1, yPos - height + 1, height, height)
		
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawTexturedRect(xPos, yPos - height, height, height)
		
		draw.ShadowText(effectData.text, "CW_HUD16", xPos, yPos + 10, self.HUDColors.white, self.HUDColors.black, 1, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		
		xPos = xPos + height + self.IconSpacing
		curIndex = curIndex + 1
	end
end

-- received status effect on a specific player (not us)
net.Receive("GC_STATUS_EFFECT_ON_PLAYER", function(a, b)
	local playerObject = net.ReadEntity()
	local statusID = net.ReadString()
	local state = net.ReadBool()
		
	if IsValid(playerObject) and playerObject:Alive() then
		playerObject:setStatusEffect(statusID, state)
	end
end)