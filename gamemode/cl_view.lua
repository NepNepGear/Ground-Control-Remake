GM.ShakeData = {lastRoll = 0, lastX = 0, lastY = 0, targetAngle = 0, curAngle = 0}
GM.ShakeIntensity = 0.075

local viewData = {}

local zeroVec = Vector(0, 0, 0)
local fullVec = Vector(1, 1, 1)

function GM:CalcView(ply, eyePos, eyeAng, fov, nearZ, farZ)
	-- :Alive lags behind a bit, so assuming that health < 0 and ragdoll ent present = dead is a safe enough assumption
	if ply:Health() <= 0 or not ply:Alive() then
		self.deadPeriod = self.deadPeriod or CurTime() + self.DeadPeriodTime
		local curTime = CurTime()
		
		if curTime > self.deadPeriod + 0.5 then
			if self.DeadState ~= 3 and not IsValid(ply.currentSpectateEntity) then
				RunConsoleCommand("gc_spectate_next")
			end
			
			self.DeadState = 3
		elseif curTime > self.deadPeriod + 0.1 then
			if self.DeadState ~= 2 then
				RunConsoleCommand("gc_spectate_next")
			end
			
			self.DeadState = 2
		elseif curTime > self.deadPeriod - 0.5 then
			self.DeadState = 1
		else
			self.DeadState = 0
		end
		
		local ragdollEnt = ply:GetRagdollEntity()
		
		if IsValid(ragdollEnt) then
			if curTime < self.deadPeriod then
				ragdollEnt:ManipulateBoneScale(ragdollEnt:LookupBone("ValveBiped.Bip01_Head1"), zeroVec)
				
				local eyeId = ragdollEnt:LookupAttachment("eyes") -- lol
				
				if eyeId then
					ply.eyeData = ragdollEnt:GetAttachment(eyeId)
					eyePos = ply.eyeData.Pos
					eyeAng = ply.eyeData.Ang
					nearZ = 0.1
				end
			else
				ragdollEnt:ManipulateBoneScale(ragdollEnt:LookupBone("ValveBiped.Bip01_Head1"), fullVec)
			end
		end
	else
		self.deadPeriod = nil
		self.DeadState = 0
	end

	return self.BaseClass:CalcView(ply, eyePos, eyeAng, fov, nearZ, farZ)
end

function GM:CreateMove(cmd)
	local ply = LocalPlayer()
	
	if ply:Alive() then
		if IsValid(ply.selectWeaponTarget) then
			cmd:SelectWeapon(ply.selectWeaponTarget)
			
			if ply:GetActiveWeapon() == ply.selectWeaponTarget then
				ply.selectWeaponTarget = nil
			end
		else
			ply.selectWeaponTarget = nil
		end
	
		if ply.adrenaline > 0 then
			local wep = ply:GetActiveWeapon()
			
			if IsValid(wep) and wep.CW20Weapon and wep.dt.State == CW_AIMING then
				local curTime = CurTime()
				local shakeData = self.ShakeData
				
				if curTime > shakeData.lastRoll then
					shakeData.lastRoll = curTime + 0.1
					local angle = math.random(0, 360)
					shakeData.targetAngle = math.random(0, 360)
					
					shakeData.lastX = dirX
					shakeData.lastY = dirY
				end
				
				shakeData.curAngle = Lerp(FrameTime() * 10, shakeData.curAngle, shakeData.targetAngle)
				local dirX, dirY = math.sin(shakeData.curAngle), math.cos(shakeData.curAngle)
				
				local ang = cmd:GetViewAngles()
				
				ang.p = ang.p + dirY * self.ShakeIntensity * ply.adrenaline
				ang.y = ang.y + dirX * self.ShakeIntensity * ply.adrenaline
				
				cmd:SetViewAngles(ang)
			end
		end
	else
		ply.selectWeaponTarget = nil
	end
end