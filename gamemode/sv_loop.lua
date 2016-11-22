function GM:Think()
	if self.curGametype.think then
		self.curGametype:think()
	end
	
	local curTime = CurTime()
	local frameTime = FrameTime()
	local traits = self.Traits
	
	for key, ply in pairs(player.GetAll()) do
		if ply:Alive() and ply:Team() ~= TEAM_SPECTATOR then
			if ply:OnGround() then
				ply.curMaxStamina = ply:getMaxStamina()
				local maxStamina = math.min(ply.curMaxStamina, self.MinStaminaFromSprinting)
				local walkSpeed, velocity = ply:GetWalkSpeed(), ply:GetVelocity()
				
				velocity.z = 0
				local length = velocity:Length()
				
				if ply.stamina > self.MinStaminaFromSprinting and length >= walkSpeed * 1.15 then -- should only drain stamina when our current stamina is lower than our max stamina
					if curTime > ply.staminaDrainTime then
						ply:drainStamina()
					end
				else
					if ply.stamina < 100 then
						if curTime > ply.staminaRegenTime then
							ply:regenStamina()
						end
					end
				end
			end
			
			if ply.bleeding then
				if ply:shouldBleed() then
					ply:bleed()
				end
				
				ply:delayHealthRegen()
				ply:increaseAdrenalineDuration(1, 1)
			else
				if ply.regenPool > 0 then
					if curTime > ply.regenDelay then
						ply:regenHealth()
					end
				end
			end
			
			if ply.adrenalineIncreaseSpeed ~= 1 and curTime > ply.adrenalineSpeedHold then
				ply.adrenalineIncreaseSpeed = math.Approach(ply.adrenalineIncreaseSpeed, 1, self.AdrenalineIncreaseSpeedFadeOutSpeed * frameTime)
			end
			
			self:attemptRestoreMovementSpeed(ply)
			
			ply.adrenalineDuration = math.max(ply.adrenalineDuration - frameTime, 0)
			
			if ply.adrenalineDuration == 0 then
				if ply.adrenaline > 0 then
					ply:setAdrenaline(ply.adrenaline - frameTime * self.AdrenalineFadeOutSpeed)
				end
			else
				ply:setAdrenaline(ply.adrenaline + self.AdrenalineFadeInPerSec * frameTime * ply.adrenalineIncreaseSpeed)
			end
			
			for key, traitConfig in ipairs(ply.currentTraits) do
				local traitData = traits[traitConfig[1]][traitConfig[2]]
				
				if traitData.think then
					traitData:think(ply, curTime)
				end
			end
		end
	end
end