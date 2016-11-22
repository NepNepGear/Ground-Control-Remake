include('shared.lua')

function ENT:Initialize()
	GAMEMODE:addObjectiveEntity(self)
end

function ENT:Think()
end

ENT.barWidth = 60
ENT.barHeight = 8

ENT.colorByTeam = {[TEAM_RED] = Color(124, 185, 255, 255),
	[TEAM_BLUE] = Color(255, 117, 99, 255)}

function ENT:drawHUD()
	local pos = self:GetPos()
	pos.z = pos.z + 32
	
	local coords = pos:ToScreen()
	
	if coords.visible then
		local ply = LocalPlayer()
		local ourTeam = ply:Team()
		local baseX, baseY = math.ceil(coords.x - self.barWidth * 0.5), math.ceil(coords.y - 8)
		local alpha = math.Clamp(math.Dist(baseX, baseY, ScrW() * 0.5, ScrH() * 0.5), 150, 255) / 255
		
		surface.SetDrawColor(0, 0, 0, 255 * alpha)
		surface.DrawOutlinedRect(baseX, baseY, self.barWidth, self.barHeight)
		
		surface.SetDrawColor(0, 0, 0, 200 * alpha)
		surface.DrawRect(baseX + 1, baseY + 1, self.barWidth - 2, self.barHeight - 2)
		
		local drawColor = self.colorByTeam[self.dt.CurCaptureTeam]
		
		if drawColor then
			drawColor.a = 255 * alpha
			
			surface.SetDrawColor(drawColor)
		
			local percentage = self.dt.CaptureProgress / 100
			surface.DrawRect(baseX + 2, baseY + 2, (self.barWidth - 4) * percentage, self.barHeight - 4)
		end
		
		local white, black = GAMEMODE.HUDColors.white, GAMEMODE.HUDColors.black
		white.a = 255 * alpha
		black.a = 255 * alpha
		draw.ShadowText("Capture", "CW_HUD14", coords.x, coords.y - 16, white, black, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		white.a = 255
		black.a = 255
	end
end