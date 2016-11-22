-- todo: make the scoreboard a derma element
-- this code in general is pretty bad (locals defined outside of functions), was written back in 2012, needs a rewrite

local clr, rect, orect, stext, lgrad = surface.SetDrawColor, surface.DrawRect, surface.DrawOutlinedRect, draw.ShadowText, draw.LinearGradient
local lp, X, Y, X2, Y2, ply, scale1, scale2, state, statecolor, dtint1, ktext, kcolor, FT, slot, blue, red, f1, f2, n, d1, d2, n1, n2
local PTBL = {}

function GM:SortPlayers(t)
	lp = LocalPlayer()
	ply = team.GetPlayers(t)
	table.Empty(PTBL)
	
	for k, v in pairs(ply) do
		n1, f1, d1 = v:GetNWInt("GC_SCORE"), v:Name(), v:Deaths()
		slot = #ply
		
		for k2, v2 in pairs(ply) do
			if v != v2 then
				n2, f2, d2 = v2:GetNWInt("GC_SCORE"), v2:Name(), v2:Deaths()
				
				if n1 > n2 then
					slot = slot - 1
				elseif n1 == n2 then
					if d1 < d2 then
						slot = slot - 1
					elseif d1 == d2 then
						if f1 < f2 then
							slot = slot - 1
						end
					end
				end
			end
		end
		
		PTBL[slot] = v
	end
	
	return PTBL
end

function GM:ScoreboardShow()
	self.ShowScoreboard = true
end

function GM:ScoreboardHide()
	self.ShowScoreboard = false
end

GM.ScoreboardColors = {
	ColorWhite = Color(255, 255, 255, 255), 
	ColorBlack = Color(0, 0, 0, 255), 
	ColorBlue1 = Color(33, 184, 255, 255), 
	ColorBlue2 = Color(58, 120, 255, 255), 
	ColorRed1 = Color(255, 122, 61, 255), 
	ColorRed2 = Color(255, 0, 0, 255), 
	ColorGray1 = Color(213, 213, 213, 150), 
	ColorGray2 = Color(170, 170, 170, 150)
}

local ttf = team.TotalFrags
local sleft = string.Left

local CW_HUD16 = "CW_HUD16"

function GM:HUDDrawScoreBoard()
	if not self.ShowScoreboard then
		return
	end
	
	lp = LocalPlayer()	
	X = ScrW()
	Y = ScrH()
	
	X2 = X * 0.5
	Y2 = Y * 0.5

	clr(0, 0, 0, 75)
	rect(X2 - 400, Y2 - 250, 800, 500)
	
	local clrs = self.ScoreboardColors
	
	surface.SetDrawColor(clrs.ColorBlue1)
	surface.DrawRect(X2 - 400, Y2 - 250, 400, 20)
	
	lgrad(X2 - 399, Y2 - 250, 398, 20, clrs.ColorBlue1, clrs.ColorBlue2, draw.VERTICAL)
	lgrad(X2 + 1, Y2 - 250, 398, 20, clrs.ColorRed1, clrs.ColorRed2, draw.VERTICAL)
	
	draw.ShadowText("RED", CW_HUD16, X2 + 10, Y2 - 240, clrs.ColorWhite, clrs.ColorBlack, 1, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) 
	draw.ShadowText(ttf(TEAM_RED), CW_HUD16, X2 + 50, Y2 - 240, clrs.ColorWhite, clrs.ColorBlack, 1, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) 
	draw.ShadowText("K", CW_HUD16, X2 + 230, Y2 - 240, clrs.ColorWhite, clrs.ColorBlack, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) 
	draw.ShadowText("D", CW_HUD16, X2 + 260, Y2 - 240, clrs.ColorWhite, clrs.ColorBlack, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) 
	draw.ShadowText("SCORE", CW_HUD16, X2 + 310, Y2 - 240, clrs.ColorWhite, clrs.ColorBlack, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) 
	draw.ShadowText("PING", CW_HUD16, X2 + 370, Y2 - 240, clrs.ColorWhite, clrs.ColorBlack, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) 
	
	draw.ShadowText("BLUE", CW_HUD16, X2 - 390, Y2 - 240, clrs.ColorWhite, clrs.ColorBlack, 1, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) 
	draw.ShadowText(ttf(TEAM_BLUE), CW_HUD16, X2 - 340, Y2 - 240, clrs.ColorWhite, clrs.ColorBlack, 1, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) 
	draw.ShadowText("K", CW_HUD16, X2 - 170, Y2 - 240, clrs.ColorWhite, clrs.ColorBlack, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) 
	draw.ShadowText("D", CW_HUD16, X2 - 140, Y2 - 240, clrs.ColorWhite, clrs.ColorBlack, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) 
	draw.ShadowText("SCORE", CW_HUD16, X2 - 90, Y2 - 240, clrs.ColorWhite, clrs.ColorBlack, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) 
	draw.ShadowText("PING", CW_HUD16, X2 - 30, Y2 - 240, clrs.ColorWhite, clrs.ColorBlack, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) 
	
	local myTeam = lp:Team()
	
	for k, v in pairs(self:SortPlayers(TEAM_RED)) do
		clrs.ColorWhite.r = 255
		clrs.ColorWhite.g = 255
		clrs.ColorWhite.b = 255
		
		n = v:Nick()
		
		if v == lp then
			lgrad(X2 + 1, Y2 + k * 21 - 250, 398, 20, clrs.ColorGray1, clrs.ColorGray2, draw.VERTICAL)
		else
			clr(255, 143, 91, 150)
			rect(X2 + 1, Y2 + k * 21 - 249, 398, 20)
		end
	
		if myTeam == TEAM_RED and not v:Alive() then
			clrs.ColorWhite.r = 150
			clrs.ColorWhite.g = 150
			clrs.ColorWhite.b = 150
		end
		
		draw.ShadowText(k, CW_HUD16, X2 + 10, Y2 - 239 + k * 21, clrs.ColorWhite, clrs.ColorBlack, 1, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) 
		draw.ShadowText(#n <= 21 and n or sleft(n, 21) .. "...", CW_HUD16, X2 + 40, Y2 - 239 + k * 21, clrs.ColorWhite, clrs.ColorBlack, 1, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) 
		draw.ShadowText(v:Frags(), CW_HUD16, X2 + 230, Y2 - 239 + k * 21, clrs.ColorWhite, clrs.ColorBlack, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) 
		draw.ShadowText(v:Deaths(), CW_HUD16, X2 + 260, Y2 - 239 + k * 21, clrs.ColorWhite, clrs.ColorBlack, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) 
		draw.ShadowText(v:GetNWInt("GC_SCORE"), CW_HUD16, X2 + 310, Y2 - 239 + k * 21, clrs.ColorWhite, clrs.ColorBlack, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) 
		draw.ShadowText(v:Ping(), CW_HUD16, X2 + 370, Y2 - 239 + k * 21, clrs.ColorWhite, clrs.ColorBlack, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) 
		
		clrs.ColorWhite.r = 255
		clrs.ColorWhite.g = 255
		clrs.ColorWhite.b = 255
	end
	
	for k, v in pairs(self:SortPlayers(TEAM_BLUE)) do
		clrs.ColorWhite.r = 255
		clrs.ColorWhite.g = 255
		clrs.ColorWhite.b = 255
		
		n = v:Nick()
		
		if v == lp then
			lgrad(X2 + 1 - 400, Y2 + k * 21 - 250, 398, 20, clrs.ColorGray1, clrs.ColorGray2, draw.VERTICAL)
		else
			clr(40, 66, 124, 150)
			rect(X2 + 1 - 400, Y2 + k * 21 - 249, 398, 20)
		end
		
		if myTeam == TEAM_BLUE and not v:Alive() then
			clrs.ColorWhite.r = 150
			clrs.ColorWhite.g = 150
			clrs.ColorWhite.b = 150
		end
		
		draw.ShadowText(k, CW_HUD16, X2 - 390, Y2 - 239 + k * 21, clrs.ColorWhite, clrs.ColorBlack, 1, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) 
		
		draw.ShadowText(#n <= 21 and n or sleft(n, 21) .. "...", CW_HUD16, X2 + 40 - 400, Y2 - 239 + k * 21, clrs.ColorWhite, clrs.ColorBlack, 1, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) 
		draw.ShadowText(v:Frags(), CW_HUD16, X2 - 170, Y2 - 239 + k * 21, clrs.ColorWhite, clrs.ColorBlack, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) 
		draw.ShadowText(v:Deaths(), CW_HUD16, X2 - 140, Y2 - 239 + k * 21, clrs.ColorWhite, clrs.ColorBlack, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) 
		draw.ShadowText(v:GetNWInt("GC_SCORE"), CW_HUD16, X2 - 90, Y2 - 239 + k * 21, clrs.ColorWhite, clrs.ColorBlack, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) 
		draw.ShadowText(v:Ping(), CW_HUD16, X2 - 30, Y2 - 239 + k * 21, clrs.ColorWhite, clrs.ColorBlack, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) 
		
		clrs.ColorWhite.r = 255
		clrs.ColorWhite.g = 255
		clrs.ColorWhite.b = 255
	end
end