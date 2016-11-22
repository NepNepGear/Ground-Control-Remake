AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

ENT.captureDistance = 192
ENT.captureAmount = 1
ENT.captureTime = 0.25
ENT.captureSpeedIncrease = 0.25
ENT.maxSpeedIncrease = 0.5
ENT.deCaptureTime = 1
ENT.deCaptureAmount = 1
ENT.roundWinTime = 5 -- seconds until round win if: 1. time has run out + the person was capturing a point and suddenly left the capture range
ENT.roundOverOnCapture = true

function ENT:Initialize()
	self:SetModel("models/error.mdl")
	self:SetNoDraw(true)
	
	self.captureDelay = 0
	self.deCaptureDelay = 0
	self.defenderTeam = nil
	self.winDelay = 0
	
	self:setCaptureDistance(self.captureDistance)
	
	local gametype = GAMEMODE:getGametype()
	gametype:assignPointID(self)
end

function ENT:setCapturerTeam(team) -- the team that has to capture this point
	self.capturerTeam = team
	self.dt.CapturerTeam = team
end

function ENT:setDefenderTeam(team)
	self.defenderTeam = team
end

function ENT:setCaptureDistance(distance)
	self.captureDistance = distance
	self.dt.CaptureDistance = distance
end

function ENT:setCaptureSpeed(speed)
	self.captureAmount = speed
end

function ENT:setCaptureDuration(time) -- we increase CaptureProgress by captureAmount every captureTime
	self.captureTime = time
end

function ENT:setCaptureSpeedInceasePerPlayer(speedIncrease) -- each player makes the capture go this % faster
	self.captureSpeedIncrease = speedIncrease
end

function ENT:setMaxCaptureSpeedIncrease(max)
	self.maxSpeedIncrease = max
end

function ENT:setRoundOverOnCapture(roundOver)
	self.roundOverOnCapture = roundOver
end

local plys, CT

function ENT:Think()
	if GAMEMODE.RoundOver then
		return
	end
	
	if self.roundOverOnCapture then
		if self.dt.CaptureProgress == 100 then
			GAMEMODE:endRound(self.capturerTeam)
			return
		end
	end
	
	local curTime = CurTime()
	local defendingPlayers = 0
	
	local ownPos = self:GetPos()
	
	for key, ply in ipairs(team.GetPlayers(self.defenderTeam)) do
		if ply:Alive() then
			local dist = ply:GetPos():Distance(ownPos)
			
			if dist <= self.captureDistance then
				defendingPlayers = defendingPlayers + 1
			end
		end
	end
	
	local capturingPlayers = 0
	
	if defendingPlayers == 0 then
		for key, ply in ipairs(team.GetPlayers(self.capturerTeam)) do
			if ply:Alive() then
				local dist = ply:GetPos():Distance(ownPos)
				
				if dist <= self.captureDistance then
					capturingPlayers = capturingPlayers + 1
				end
			end
		end
	end
	
	if capturingPlayers > 0 then
		if curTime > self.captureDelay then
			local multiplier = math.max(1 - (capturingPlayers - 1) * self.captureSpeedIncrease, self.maxSpeedIncrease)
			
			self.captureDelay = curTime + self.captureTime * multiplier
			self.deCaptureDelay = curTime + self.deCaptureTime
			self.winDelay = curTime + self.roundWinTime
			self.dt.CaptureProgress = math.Approach(self.dt.CaptureProgress, 100, self.captureAmount)
		end
	else
		if curTime > self.deCaptureDelay then
			self.dt.CaptureProgress = math.Approach(self.dt.CaptureProgress, 0, 1)
			self.deCaptureDelay = curTime + self.deCaptureTime
		end
	end
end

function ENT:Use(activator, caller)
	return false
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end