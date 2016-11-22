GM.ColorCorrectionData = {
	["$pp_colour_addr"] = 0,
	["$pp_colour_addg"] = 0,
	["$pp_colour_addb"] = 0,
	["$pp_colour_brightness"] = 0,
	["$pp_colour_contrast"] = 1,
	["$pp_colour_colour"] = 1,
	["$pp_colour_mulr"] = 0,
	["$pp_colour_mulg"] = 0,
	["$pp_colour_mulb"] = 0
}

GM.HurtBlurAddAlphaMin = 1
GM.HurtBlurAddAlphaMax = 0.33
GM.HurtBlurDrawAlpha = 1
GM.HurtBlurDelay = 0

GM.HurtColorCorrection = {
	["$pp_colour_addr"] = 0,
	["$pp_colour_addg"] = 0,
	["$pp_colour_addb"] = 0,
	["$pp_colour_brightness"] = 0,
	["$pp_colour_contrast"] = 1,
	["$pp_colour_colour"] = 1,
	["$pp_colour_mulr"] = 0,
	["$pp_colour_mulg"] = 0,
	["$pp_colour_mulb"] = 0
}

GM.HurtSharpenDistanceMin = 0
GM.HurtSharpenContrastMin = 0

GM.HurtSharpenDistanceMax = 1.7
GM.HurtSharpenContrastMax = 1.5

GM.HurtIntensityMaxDamage = 50 -- if we take this much damage in 1 hit we will have maximum hurt effect intensity
GM.HurtEffectDuration = 0.3 -- how much time the hurt effect will last for

GM.MinHealthBlackAndWhiteStart = 50 -- when our health is lower than this, our screen will begin to turn black&white
GM.MaxColorDesaturation = 0.75 -- we will desaturate this much color when our health is at 0

GM.currentHurtIntensity = 0
GM.currentHurtDuration = 0
GM.currentHurtProgress = 0

GM.minHurtEffectTime = 0.2
GM.maxHurtEffectTime = 3
	
function GM:RenderScreenspaceEffects()
	local ply = LocalPlayer()
	local hp = ply:Health()
	
	if hp <= self.MinHealthBlackAndWhiteStart then
		if self.deadPeriod and CurTime() > self.deadPeriod then
			return
		end
		
		local finalDecrease
		
		if ply:Alive() then
			local curDifference = 1 - hp / self.MinHealthBlackAndWhiteStart
			finalDecrease = self.MaxColorDesaturation * curDifference
		else
			finalDecrease = 1
		end
		
		self.ColorCorrectionData["$pp_colour_colour"] = 1 - finalDecrease
		
		DrawColorModify(self.ColorCorrectionData)
	end
	
	local unpredictedCurTime = UnPredictedCurTime()
	
	if self.currentHurtProgress < self.currentHurtDuration then
		local frameTime = FrameTime()
		local realIntensity = (1 - math.min(1, self.currentHurtProgress / self.currentHurtDuration)) * self.currentHurtIntensity
		
		DrawSharpen(Lerp(realIntensity, self.HurtSharpenContrastMin, self.HurtSharpenContrastMax), Lerp(realIntensity, self.HurtSharpenDistanceMin, self.HurtSharpenDistanceMax))
		DrawMotionBlur(Lerp(realIntensity, self.HurtBlurAddAlphaMin, self.HurtBlurAddAlphaMax), self.HurtBlurDrawAlpha, self.HurtBlurDelay)
		
		self.HurtColorCorrection["$pp_colour_addr"] = Lerp(realIntensity, 0, 100 / 255)
		self.HurtColorCorrection["$pp_colour_colour"] = Lerp(realIntensity, 1, 1.21)
		self.HurtColorCorrection["$pp_colour_contrast"] = Lerp(realIntensity, 1, 1.5)
		
		DrawColorModify(self.HurtColorCorrection)
		
		self.currentHurtProgress = self.currentHurtProgress + frameTime
	end
end

function GM:playHurtEffect(damageTaken)
	local intensity = math.min(damageTaken / self.HurtIntensityMaxDamage, 1)
	
	local pastProgress = 1 - self.currentHurtProgress / self.currentHurtDuration
	local pastIntensity = self.currentHurtIntensity * pastProgress
		
	if intensity >= pastIntensity or pastIntensity ~= pastIntensity then
		self.currentHurtIntensity = intensity
		self.currentHurtDuration = Lerp(intensity, self.minHurtEffectTime, self.maxHurtEffectTime)
		self.currentHurtProgress = 0
	end
end

gameevent.Listen("player_hurt")

hook.Add("player_hurt", "GroundControl.player_hurt", function(data)
	local ply = LocalPlayer()
	local entity = Player(data.userid)

	if ply == entity then
		GAMEMODE:onLocalPlayerHurt(data, ply)
	end
end)