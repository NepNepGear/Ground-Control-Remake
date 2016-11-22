include('shared.lua')

function ENT:Initialize()
	GAMEMODE:addDrawEntity(self)
end

function ENT:OnRemove()
	GAMEMODE:removeDrawEntity(self)
end

function ENT:Think()
	if self:canPenalizePlayer(LocalPlayer()) then
		if not self.penalizeTime then
			self.penalizeTime = CurTime() + self.timeToPenalize
		end
	else
		self.penalizeTime = nil
	end
end

function ENT:getPenaltyText()
	if self.dt.inverseFunctioning then
		return "You're too far away! You have TIME second(s) to get back to the playing area!"
	end
	
	return "Where are you going? You have TIME second(s) to get back to the playing area!"
end

function ENT:getTimeToDeath()
	return math.abs(math.max(math.ceil(self.penalizeTime - CurTime()), 0))
end

function ENT:drawHUD()
	local w, h = ScrW(), ScrH()
	
	if self.penalizeTime then
		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawRect(0, 0, w, h)
		
		local text = self:getPenaltyText()
		text = string.gsub(text, "TIME", self:getTimeToDeath())
		
		draw.ShadowText(text, "CW_HUD28", w * 0.5, h * 0.5, GAMEMODE.HUDColors.white, GAMEMODE.HUDColors.black, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end