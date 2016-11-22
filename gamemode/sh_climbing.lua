--[[
	NOTE: this is disabled because I couldn't get the prediction to work properly,
	so I decided to not enable a feature that looks like shit on clients with ping above 50
]]--

AddCSLuaFile()

local PLAYER = FindMetaTable("Player")
PLAYER.MAXIMUM_CLIMB_HEIGHT = 40 -- maximum height of a wall that we can scale
PLAYER.FINISH_CLIMB_SPEED = 140 -- how fast will we be moved forward along the normal between us and the destination position when we're done moving upwards
PLAYER.CLIMB_SPEED = 130 -- how many units we scale in 1 second
PLAYER.DISTANCE_TO_CLIMBABLE = 24 -- how many units apart we can be at most to initiate a climb
PLAYER.TRACE_THROUGH_DISTANCE = 0 -- how far forward should we trace after the initial trace is valid
PLAYER.MAX_XY_VELOCITY_FOR_CLIMBING = 400 -- our horizontal velocity can not exceed this much for us to be able to climb
PLAYER.CLIMB_FINISH_DISTANCE = 10 -- how close we have to be to our target destination to finish the climb
PLAYER.ABORT_DISTANCE = 50 -- if the XY distance is greater than this during a climb it will be auto-aborted (failsafe)
PLAYER.CLIMB_STATE_CLIMB = 1
PLAYER.CLIMB_STATE_FINISH = 2
PLAYER.CLIMB_VELOCITY = Vector(0, 0, PLAYER.CLIMB_SPEED)
PLAYER.WEAPON_CLIMB_DELAY = 20 -- this is an arbitrary number, it's made to ensure that if a climb is super long the player won't end up being able to shoot his gun during the climb
PLAYER.MAX_CLIMB_HEALTH = 50 -- if health is lower than this, the player won't be able to climb

PLAYER.SOLID_CLIMB_MASK = bit.bor(CONTENTS_SOLID)
PLAYER.INVISIBLE_CLIMB_MASK = bit.bor(CONTENTS_EMPTY)

local traceData = {}
traceData.mask = PLAYER.SOLID_CLIMB_MASK
local upVector = Vector(0, 0, PLAYER.MAXIMUM_CLIMB_HEIGHT)

function PLAYER:isObjectValidForClimbing(object)
	if not IsValid(object) then
		return true
	end
	
	local physobj = object:GetPhysicsObject()
	
	if physobj and physobj:IsMoveable() then
		return false
	end
	
	return not object:IsPlayer() and not object:IsNPC()
end

function PLAYER:canClimb()
	local vel = self:GetVelocity()
	
	return not self:Crouching() and self:KeyDown(IN_JUMP) and self:Health() >= PLAYER.MAX_CLIMB_HEALTH and vel.z > 0 and (math.abs(vel.x) + math.abs(vel.x)) < PLAYER.MAX_XY_VELOCITY_FOR_CLIMBING and self:GetMoveType() == MOVETYPE_WALK
end

function PLAYER:getClimbDestination()
	local pos = self:GetShootPos()
	local eyeAng = self:EyeAngles()
	local forward = eyeAng:Forward()
	
	traceData.start = pos
	traceData.endpos = traceData.start + forward * PLAYER.DISTANCE_TO_CLIMBABLE
	traceData.mask = PLAYER.SOLID_CLIMB_MASK
	traceData.filter = self
	
	local trace = util.TraceLine(traceData)
	
	if trace.Hit and self:isObjectValidForClimbing(trace.Entity) then
		traceData.start = trace.HitPos + forward * PLAYER.TRACE_THROUGH_DISTANCE
		traceData.endpos = traceData.start + upVector
		traceData.mask = PLAYER.INVISIBLE_CLIMB_MASK
		
		local upTrace = util.TraceLine(traceData)
		
		if trace.Hit and self:isObjectValidForClimbing(trace.Entity) then
			if self:isClimbAreaUnobstructed(upTrace.HitPos) then
				return upTrace.HitPos
			end
		end
	end
	
	return nil
end

function PLAYER:isClimbAreaUnobstructed(dest)
	dest.z = dest.z + 0.5

	traceData.start = dest
	traceData.endpos = traceData.start
	traceData.filter = self
	traceData.mask = PLAYER.SOLID_CLIMB_MASK
	traceData.mins = GAMEMODE.StandHullMin
	traceData.maxs = GAMEMODE.StandHullMax
	
	dest.z = dest.z - 0.5 -- reset the offset we applied to not constantly increase the destination Z position
	
	local hullTrace = util.TraceHull(traceData)
	
	return not hullTrace.Hit
end

function PLAYER:beginClimb(climbDestination)
	self.climbDestination = climbDestination
	self:SetMoveType(MOVETYPE_FLY)
	self.climbState = PLAYER.CLIMB_STATE_CLIMB
	
	local wep = self:GetActiveWeapon()
	
	if wep and wep.CW20Weapon then
		wep.dt.State = CW_ACTION
		wep:setGlobalDelay(PLAYER.WEAPON_CLIMB_DELAY)
	end
end

function PLAYER:advanceClimb()
	self.climbState = PLAYER.CLIMB_STATE_FINISH
end

function PLAYER:finishClimb()
	self.climbState = nil
	self.climbDestination = nil
	self:SetMoveType(MOVETYPE_WALK)
	
	local wep = self:GetActiveWeapon()
	
	if wep and wep.CW20Weapon then
		wep.dt.State = CW_IDLE
		wep:setGlobalDelay(0)
	end
	
	if SERVER then
		SendUserMessage("GC_FINISH_CLIMB", self)
	end
end

function PLAYER:abortClimb()
	self.climbState = nil
	self.climbDestination = nil
	self:SetMoveType(MOVETYPE_WALK)
	
	local wep = self:GetActiveWeapon()
	
	if wep and wep.CW20Weapon then
		wep.dt.State = CW_IDLE
		wep:setGlobalDelay(0)
	end
	
	if SERVER then
		SendUserMessage("GC_ABORT_CLIMB", self)
	end
end

function PLAYER:reachedClimbDestination()
	return self:GetPos().z - self.climbDestination.z >= 0
end

function PLAYER:suppressPlayerMoveInput(moveData)
	moveData:SetForwardSpeed(0)
	moveData:SetSideSpeed(0)
	moveData:SetUpSpeed(0)
end

function PLAYER:tooFarApartFromClimbDest()
	local pos = self:GetPos()
	
	return math.Dist(pos.x, pos.y, self.climbDestination.x, self.climbDestination.y) > PLAYER.ABORT_DISTANCE
end

function PLAYER:attemptClimb(moveData)
	if not self.climbDestination then
		if self:canClimb() then
			local climbDestination = self:getClimbDestination()
			
			if climbDestination then
				self:beginClimb(climbDestination)
			end
		end
	else
		if self:isClimbAreaUnobstructed(self.climbDestination) then
			if self.climbState == PLAYER.CLIMB_STATE_CLIMB then
				if not self:tooFarApartFromClimbDest() then
					if not self:reachedClimbDestination() then
						self:suppressPlayerMoveInput(moveData)
						moveData:SetVelocity(PLAYER.CLIMB_VELOCITY)
						moveData:SetMaxSpeed(0)
						moveData:SetMaxClientSpeed(0)
					else
						self:advanceClimb()
					end
				else
					self:abortClimb()
				end
			elseif self.climbState == PLAYER.CLIMB_STATE_FINISH then
				local ourPos = self:GetPos()
				
				if ourPos:Distance(self.climbDestination) > PLAYER.CLIMB_FINISH_DISTANCE then
					local normal = (self.climbDestination - ourPos):GetNormal()
					normal.z = 0
					self:suppressPlayerMoveInput(moveData)
					local vel = normal * PLAYER.FINISH_CLIMB_SPEED
					moveData:SetVelocity(vel)
				else
					self:finishClimb()
				end
			end
		else
			self:abortClimb()
		end
	end
end

if CLIENT then
	local function GC_FINISH_CLIMB()
		LocalPlayer():finishClimb()
	end
	
	usermessage.Hook("GC_FINISH_CLIMB", GC_FINISH_CLIMB)
	
	local function GC_ABORT_CLIMB()
		LocalPlayer():abortClimb()
	end
	
	usermessage.Hook("GC_ABORT_CLIMB", GC_ABORT_CLIMB)
end