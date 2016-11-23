GM.Version = 1.04

GM.Name 	= "Ground Control " .. GM.Version
GM.Author 	= "N/A"
GM.Email 	= "N/A"
GM.Website 	= "N/A"

GM.MainDataDirectory = "ground_control"

GM.BaseRunSpeed = 280
GM.BaseWalkSpeed = 130
GM.CrouchedWalkSpeed = 0.6
GM.CurrentMap = game.GetMap()
GM.RoundRestartTime = 1.5 -- how much time to restart a round after it has ended
GM.RoundPreparationTime = 15 -- time it takes for the round to start
GM.RoundLoadoutTime = 25 -- for how long can we pick our loadout at the start of a new round
GM.LoadoutDistance = 256 -- max distance within which we can still change our loadout
GM.DeadPeriodTime = 5 -- how much time we will have to spend until we're able to spectate our teammates after dying
GM.PreparationTime = 0
GM.StaminaPerJump = 5
GM.JumpStaminaRegenDelay = 1
GM.DamageMultiplier = 1.55 -- multiplier for the damage when we shot an enemy
GM.MaxHealth = 100
GM.VotePrepTime = 5
GM.VoteTime = GM.VotePrepTime + 30
GM.HeavyLandingVelocity = 500
GM.HeavyLandingVelocityToWeight = 0.03 -- multiply velocity by this much, if the final value exceeds our weight, then it is considered a heavy landing and will make extra noise
GM.CurMap = string.lower(game.GetMap())

include("sh_sounds.lua")

-- configure CW 2.0, please do not change this (unless you know what you're doing)
CustomizableWeaponry.canOpenInteractionMenu = true
CustomizableWeaponry.customizationEnabled = true
CustomizableWeaponry.useAttachmentPossessionSystem = true
CustomizableWeaponry.playSoundsOnInteract = true
CustomizableWeaponry.physicalBulletsEnabled = false -- physical bullets for cw 2.0, unfortunately 
CustomizableWeaponry.suppressOnSpawnAttachments = true
-- CW 2.0 configuration over

GM.KnifeWeaponClass = "cw_extrema_ratio_official"

GM.StandHullMin = Vector(-16, -16, 0)
GM.StandHullMax = Vector(16, 16, 72)

GM.DuckHullMin = Vector(-16, -16, 0)
GM.DuckHullMax = Vector(16, 16, 46)
GM.ViewOffsetDucked = Vector(0, 0, 40)

-- if you wish to force-enable free aim, set this variable to true
-- beware that during playtests I noticed a weird thing - when free aim is forced on, people play much, MUCH slower and in general the gamemode turns into a campfest
GM.FORCE_FREE_AIM = false

-- parity for everyone - force complex telescopics (this could hurt the FPS on a lot of people's systems, but we'll see how this goes, if people complain I will probably disable this)
-- simple telescopics are a lot easier to use gameplay-wise, and they provide an advantage over those that use complex telescopics
-- because they disorient much less than complex telescopics (aiming through PIP is a pain in the ass, especially on close ranges, since it disorients like crazy, on the flip side - it's like that IRL too)
-- so to make things fair, I am forcing complex telescopics
GM.FORCE_COMPLEX_TELESCOPICS = true

GM.SidewaysSprintSpeedAffector = 0.1 -- if we're sprinting sideways + forward, we take a small hit to our movement speed
GM.OnlySidewaysSprintSpeedAffector = 0.25 -- if we're sprinting only sideways (not forward + sideways), then we take a big hit to our movement speed
GM.BackwardsSprintSpeedAffector = 0.25 -- if we're sprinting forwards, we take a big hit to our movement speed

GM.MaxLadderMovementSpeed = 20 -- how fast should the player move when using a ladder

function GM:Initialize()
	self.BaseClass.Initialize(self)
end

if CLIENT then
	CustomizableWeaponry.callbacks:addNew("suppressHUDElements", "GroundControl_suppressHUDElements", function(self)
		return true, true, false -- 3rd argument is whether the weapon interaction menu should be hidden
	end)
end

CustomizableWeaponry.ITEM_PACKS_TOP_COLOR = Color(0, 0, 0, 230)

FULL_INIT = true

CustomizableWeaponry.callbacks:addNew("calculateAccuracy", "GroundControl_calculateAccuracy", function(self)
	local hipMod, aimMod = self.Owner:getAdrenalineAccuracyModifiers()
	local hipMult, aimMult, maxSpread = 1, 1, 1
	
	if not self.Owner:OnGround() then
		hipMult, aimMult, maxSpread = 12, 12, 12 -- if we aren't on the ground, we get a huge spread increase
	end
	
	hipMult = hipMult * hipMod
	aimMult = aimMult * aimMod
	
	return aimMult, hipMult, maxSpread
end)

CustomizableWeaponry.callbacks:addNew("calculateRecoil", "GroundControl_calculateRecoil", function(self, modifier)
	if not self.Owner:OnGround() then
		modifier = modifier * 4 -- if we aren't on the ground, we get a huge recoil increase
	end

	return modifier
end)

CustomizableWeaponry.callbacks:addNew("preFire", "GroundControl_preFire", function(self)
	return CurTime() < GAMEMODE.PreparationTime
end)

CustomizableWeaponry.callbacks:addNew("forceFreeAim", "GroundControl_forceFreeAim", function(self)
	return GAMEMODE.FORCE_FREE_AIM
end)

CustomizableWeaponry.callbacks:addNew("forceComplexTelescopics", "GroundControl_forceComplexTelescopics", function(self)
	return GAMEMODE.FORCE_COMPLEX_TELESCOPICS
end)

CustomizableWeaponry.callbacks:addNew("preventAttachment", "GroundControl_preventAttachment", function(self, attachmentList, currentAttachmentIndex, currentAttachmentCategory, currentAttachment)
	local desiredAttachments = 0
	
	for key, category in pairs(self.Attachments) do
		if category == currentAttachmentCategory then
			if not category.last then
				desiredAttachments = desiredAttachments + 1
			end
		else
			if category.last then
				desiredAttachments = desiredAttachments + 1
			end
		end
	end
	
	return desiredAttachments > self.Owner:getUnlockedAttachmentSlots()
end)

CustomizableWeaponry.callbacks:addNew("disableInteractionMenu", "GroundControl_disableInteractionMenu", function(self)
	if GAMEMODE.curGametype.canHaveAttachments and not GAMEMODE.curGametype:canHaveAttachments(self.Owner) then
		return true
	end
	
	return not GAMEMODE:isPreparationPeriod()
end)

if CLIENT then
	local sidewaysHoldingStates = {
		[0] = true, -- CW_IDLE
		[1] = true, -- CW_RUNNING
		[2] = true, -- CW_AIMING
		[4] = true -- CW_CUSTOMIZE
	}
	
	local zeroVector = Vector(0, 0, 0)
	local downwardsVector = Vector(0, 0, 0)
	local downwardsAngle = Vector(-30, 0, -45)
	
	CustomizableWeaponry.callbacks:addNew("adjustViewmodelPosition", "GroundControl_adjustViewmodelPosition", function(self, targetPos, targetAng)
		local gametype = GAMEMODE.curGametype
		local wepClass = self:GetClass()
		
		if gametype.name == "ghettodrugbust" and gametype.regularTeam == LocalPlayer():Team() and gametype.sidewaysHoldingWeapons[wepClass] then
			if sidewaysHoldingStates[self.dt.State] and not self:isReloading() and not self.isKnife then
				if self.dt.State ~= CW_CUSTOMIZE then
					if self.dt.State ~= CW_RUNNING and self.dt.State ~= CW_AIMING then
						targetAng = targetAng * 1
						targetAng.z = targetAng.z - 90
					end
					
					if self.dt.State == CW_RUNNING then
						targetPos = downwardsVector
						targetAng = downwardsAngle
					elseif self.dt.State ~= CW_AIMING then
						targetPos = targetPos * 1
						targetPos.z = targetPos.z - 3
						targetPos.x = targetPos.x - 4
					end
				end
				
				local vm = self.CW_VM
				local bones = gametype.sidewaysHoldingBoneOffsets[wepClass]
				
				if bones then
					for boneName, offsets in pairs(bones) do
						offsets.current = LerpVectorCW20(FrameTime() * 15, offsets.current, offsets.target)
						local bone = vm:LookupBone(boneName)
						vm:ManipulateBonePosition(bone, offsets.current)
					end
				end
			else
				local bones = gametype.sidewaysHoldingBoneOffsets[wepClass]
				
				if bones then
					local vm = self.CW_VM
					
					for boneName, offsets in pairs(bones) do
						offsets.current = LerpVectorCW20(FrameTime() * 15, offsets.current, zeroVector)
						local bone = vm:LookupBone(boneName)
						vm:ManipulateBonePosition(bone, offsets.current)
					end
				end
			end
		end
		
		return targetPos, targetAng
	end)
	
	GM.attachmentSlotDisplaySize = 60
	GM.attachmentSlotSpacing = 5
	
	CustomizableWeaponry.callbacks:addNew("drawToHUD", "GroundControl_drawToHUD", function(self)
		if self.dt.State == CW_CUSTOMIZE then
			if not self.Owner.unlockedAttachmentSlots then
				RunConsoleCommand("gc_request_data")
			else
				local availableSlots = self.Owner:getUnlockedAttachmentSlots()
				local overallSize = (GAMEMODE.attachmentSlotDisplaySize + GAMEMODE.attachmentSlotSpacing)
				local baseX = ScrW() * 0.5 - overallSize * availableSlots * 0.5
				local baseY = 90
				
				for i = 1, availableSlots do
					local x = baseX + (i - 1) * overallSize
					
					surface.SetDrawColor(0, 0, 0, 150)
					surface.DrawRect(x, baseY, GAMEMODE.attachmentSlotDisplaySize, GAMEMODE.attachmentSlotDisplaySize)
				end
				
				local curPos = 1
				
				for key, category in pairs(self.Attachments) do
					if category.last then
						local x = baseX + (curPos - 1) * overallSize
						
						local curAtt = category.atts[category.last]
						local attData = CustomizableWeaponry.registeredAttachmentsSKey[curAtt]
						
						surface.SetDrawColor(200, 255, 200, 255)
						surface.DrawRect(x, baseY - 5, GAMEMODE.attachmentSlotDisplaySize, 5)
						
						surface.SetDrawColor(255, 255, 255, 255)
						surface.SetTexture(attData.displayIcon)
						surface.DrawTexturedRect(x + 2, baseY + 2, GAMEMODE.attachmentSlotDisplaySize - 4, GAMEMODE.attachmentSlotDisplaySize - 4)
						
						curPos = curPos + 1
					end
				end
				
				for i = 1, availableSlots do
					local x = baseX + (i - 1) * overallSize
					
					draw.ShadowText("Slot " .. i, GAMEMODE.AttachmentSlotDisplayFont, x + GAMEMODE.attachmentSlotDisplaySize - 5, baseY + GAMEMODE.attachmentSlotDisplaySize, self.HUDColors.white, self.HUDColors.black, 1, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
				end
				
				draw.ShadowText("Used slots " .. curPos - 1 .. "/" .. availableSlots , GAMEMODE.AttachmentSlotDisplayFont, ScrW() * 0.5, baseY + GAMEMODE.attachmentSlotDisplaySize + 20, self.HUDColors.white, self.HUDColors.black, 1, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			end
		end
	end)
end

hook.Add("CW20HasAttachment", "GroundControl.CW20HasAttachment", function(ply, attachmentID, attList)
	return ply:hasUnlockedAttachment(attachmentID)
end)

if SERVER then
	CustomizableWeaponry.callbacks:addNew("finalizePhysicalBullet", "GroundControl_finalizePhysicalBullet", function(self, bulletStruct)
		bulletStruct.penetrationValue = self.penetrationValue
	end)
end

local ZeroVector = Vector(0, 0, 0)

function GM:OnPlayerHitGround(ply)
	ply:SetDTFloat(0, math.Clamp(ply:GetDTFloat(0) - 0.25, 0.5, 1))
	ply:SetDTFloat(1, CurTime() + 0.25)
	
	local vel = ply:GetVelocity()
	local len = vel:Length()
	local weightCorrelation = math.max(0, self.MaxWeight - len * self.HeavyLandingVelocityToWeight)
	
	if ply.weight >= weightCorrelation then
		ply:EmitSound("npc/combine_soldier/gear" .. math.random(3, 6) .. ".wav", 70, math.random(95, 105))
	end
end

function GM:attemptRestoreMovementSpeed(ply)
	if CurTime() > ply:GetDTFloat(1) then
		ply:SetDTFloat(0, math.Clamp(ply:GetDTFloat(0) + FrameTime(), 0, 1))			
	end
end

function GM:PlayerStepSoundTime(ply, iType, bWalking)
	local len = ply:GetVelocity():Length()
	ply.StepLen = len
	local steptime =  math.Clamp(450 - len * 0.5, 100, 500)
	
	if ( iType == STEPSOUNDTIME_ON_LADDER ) then
		steptime = 450 
	elseif ( iType == STEPSOUNDTIME_WATER_KNEE ) then
		steptime = 600 
	end

	if ply:Crouching() then
		steptime = steptime + 50
	end
	
	return steptime
end

function GM:isPreparationPeriod()
	return CurTime() < self.PreparationTime
end

function GM:Move(ply, moveData)
	if not ply:Alive() or ply:Team() == TEAM_SPECTATOR then
		return
	end
	
	if CurTime() < self.PreparationTime then
		moveData:SetMaxSpeed(0)
		local velocity = moveData:GetVelocity()
		velocity.x = 0
		velocity.y = 0
		moveData:SetVelocity(velocity)
		moveData:SetMaxClientSpeed(0)
		
		return
	end
	
	if SERVER then
		local jumpDown = ply:GetCurrentCommand():KeyDown(IN_JUMP)
		local onGround = ply:OnGround()
		
		if jumpDown then -- sure way to get whether the player jumped (ply:KeyDown(IN_JUMP) can be bypassed by simply running the command, not by pressing the key bound to the jump key)
			if onGround and ply.hasReleasedJumpKey then
				ply:setStamina(ply.stamina - self.StaminaPerJump) -- fuck your bunnyhopping
				ply:delayStaminaRegen(self.JumpStaminaRegenDelay)
				ply.hasReleasedJumpKey = false
				--ply:EmitSound()
			end
		else
			if onGround then
				ply.hasReleasedJumpKey = true
			end
		end
	end
	
	ws, rs = ply:GetWalkSpeed(), ply:GetRunSpeed()
	local adrenalineModifier = 1 + ply:getRunSpeedAdrenalineModifier() -- for some reason the value returned by GetMaxSpeed is equivalent to player's run speed - 30
	local runSpeed = (self.BaseRunSpeed - ply:getStaminaRunSpeedModifier()) * adrenalineModifier * ply:GetDTFloat(0)
	
	ply:SetRunSpeed(runSpeed)
	
	if ply:KeyDown(IN_SPEED) and not ply:Crouching() then
		local finalMult = 1
		
		if ply:KeyDown(IN_MOVELEFT) or ply:KeyDown(IN_MOVERIGHT) then
			if ply:KeyDown(IN_FORWARD) then
				finalMult = finalMult - self.SidewaysSprintSpeedAffector
			else
				finalMult = finalMult - self.OnlySidewaysSprintSpeedAffector
			end
		end
		
		if ply:KeyDown(IN_BACK) then
			finalMult = finalMult - self.BackwardsSprintSpeedAffector
		end
		
		local finalRunSpeed = math.max(math.min(moveData:GetMaxSpeed(), runSpeed) * finalMult, self.BaseWalkSpeed)
		
		moveData:SetMaxSpeed(finalRunSpeed)
		moveData:SetMaxClientSpeed(finalRunSpeed)
	end
end

local PLAYER = FindMetaTable("Player")

function PLAYER:resetSpawnData()
	self.spawnWait = 0
end

function PLAYER:setSpectateTarget(target)
	self.currentSpectateEntity = target
	
	if SERVER then
		self:Spectate(OBS_MODE_CHASE)
		self:SpectateEntity(target)
		
		umsg.Start("GC_SPECTATE_TARGET", self)
			umsg.Entity(target)
		umsg.End()
	end
end