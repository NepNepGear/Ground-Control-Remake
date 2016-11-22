include("shared.lua")

local baseFont = "CW_HUD72"
ENT.RetrieveAndProtect = "Retrieve & protect"
ENT.ProtectText = "Protect"
ENT.AttackAndCapture = "Attack & capture"
ENT.CaptureText = "Capture"
ENT.BasicText = "Drugs"

function ENT:Initialize()
	GAMEMODE:addObjectiveEntity(self)
	surface.SetFont(baseFont)
	self.baseHorSize, self.vertFontSize = surface.GetTextSize(self.BasicText)
	self.baseHorSize = self.baseHorSize < 600 and 600 or self.baseHorSize
	self.baseHorSize = self.baseHorSize + 20
	self.halfBaseHorSize = self.baseHorSize * 0.5
	self.halfVertFontSize = self.vertFontSize * 0.5
end

ENT.displayDistance = 128 -- the distance within which the contents of the box will be displayed

function ENT:Think()
	self.inRange = LocalPlayer():GetPos():Distance(self:GetPos()) <= self.displayDistance
end

local white, black = Color(255, 255, 255, 255), Color(0, 0, 0, 255)

function ENT:Draw()
	self:DrawModel()
	
	local ply = LocalPlayer()
	
	if not self.inRange then
		return
	end
	
	local eyeAng = EyeAngles()
	eyeAng.p = 0
	eyeAng.y = eyeAng.y - 90
	eyeAng.r = 90
	
	local pos = self:GetPos()
	pos.z = pos.z + 30
	
	cam.Start3D2D(pos, eyeAng, 0.05)
		local clrs = CustomizableWeaponry.ITEM_PACKS_TOP_COLOR
		surface.SetDrawColor(clrs.r, clrs.g, clrs.b, clrs.a)
		surface.DrawRect(-self.halfBaseHorSize, 0, self.baseHorSize, self.vertFontSize)
		
		draw.ShadowText("Drugs", baseFont, 0, self.halfVertFontSize, white, black, 2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end

local displayFont = "CW_HUD14"
local horizontalBoundary, verticalBoundary = 75, 75
local point = surface.GetTextureID("ground_control/hud/point_of_interest")

function ENT:drawHUD()
	if not self.inRange then
		local ply = LocalPlayer()
		
		local pos = self:GetPos()
		pos.z = pos.z + 32
		
		local text = nil
		local gametype = GAMEMODE.curGametype
		local team = ply:Team()
		
		local alpha = ply.hasDrugs and 0.4 or 1
			
		if self.dt.Dropped then
			text = team == gametype.loadoutTeam and self.CaptureText or self.RetrieveAndProtect
			alpha = alpha * (0.25 + 0.75 * math.flash(CurTime(), 1.5))
		else
			text = team == gametype.loadoutTeam and self.AttackAndCapture or self.ProtectText
		end

		local screen = pos:ToScreen()
		
		screen.x = math.Clamp(screen.x, horizontalBoundary, ScrW() - horizontalBoundary)
		screen.y = math.Clamp(screen.y, verticalBoundary, ScrH() - 200)
		
		surface.SetTexture(point)
		surface.SetDrawColor(255, 255, 255, 255 * alpha)
		surface.DrawTexturedRect(screen.x - 8, screen.y - 8 - 16, 16, 16)
		
		white.a = 255 * alpha
		black.a = 255 * alpha
		
		draw.ShadowText(text, displayFont, screen.x, screen.y, white, black, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end