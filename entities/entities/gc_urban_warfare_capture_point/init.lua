AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

ENT.captureDistance = 192
ENT.captureAmount = 3
ENT.captureSpeedIncrease = 0.25
ENT.maxSpeedIncrease = 0.5
ENT.deCaptureTime = 1
ENT.deCaptureTimeOnCapture = 5 -- time in seconds the de-capture will be delayed when being capped
ENT.deCaptureAmount = 1
ENT.deCaptureSpeedMultiplier = 2.5
ENT.noCaptureDuration = 30
ENT.roundWinTime = 5 -- seconds until round win if: 1. time has run out + the person was capturing a point and suddenly left the capture range
ENT.roundOverOnCapture = true
ENT.captureReward = {cash = 50, exp = 50}

function ENT:Initialize()
	self:SetModel("models/error.mdl")
	self:SetNoDraw(true)
	
	self.defenderTeam = nil
	self.winDelay = 0
	self.noCaptureTime = 0
	self.deCaptureDelay = 0
	self.lastUpdate = 0
	
	self:setCaptureDistance(self.captureDistance)
	
	local gametype = GAMEMODE:getGametype()
	gametype:assignPointID(self)
	
	self:SetCaptureMin(Vector(0, 0, 0))
	self:SetCaptureMax(Vector(0, 0, 0))
end

function ENT:setCapturerTeam(team) -- the team that has to capture this point
	self.capturerTeam = team
	self.dt.CapturerTeam = team
end

function ENT:setCaptureDistance(distance)
	self.captureDistance = distance
	self.dt.CaptureDistance = distance
end

function ENT:setCaptureSpeed(speed)
	self.captureAmount = speed
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

function ENT:getClosePlayers(position, listOfPlayers)
	local total, alive = 0, 0
	
	for key, ply in ipairs(listOfPlayers) do
		if ply:Alive() then
			alive = alive + 1
			
			if self:isWithinCaptureAABB(ply:GetPos()) then
				total = total + 1
			end
		end
	end
	
	return total, alive
end

function ENT:initTickets(startAmount)
	self.dt.RedTicketCount = startAmount
	self.dt.BlueTicketCount = startAmount
	self:SetMaxTickets(startAmount)
	self:setupWaveTime()
end

function ENT:setCaptureAABB(vec1, vec2)
	local vecMin = Vector(math.min(vec1.x, vec2.x), math.min(vec1.y, vec2.y), math.min(vec1.z, vec2.z))
	local vecMax = Vector(math.max(vec1.x, vec2.x), math.max(vec1.y, vec2.y), math.max(vec1.z, vec2.z))
	
	self:SetCaptureMin(vecMin)
	self:SetCaptureMax(vecMax)
end

function ENT:setupWaveTime(timeModifier)
	timeModifier = timeModifier or 0
	
	self.dt.WaveTimeLimit = CurTime() + GAMEMODE.curGametype.waveTimeLimit + timeModifier
end	

function ENT:Think()
	if GAMEMODE.RoundOver then
		return
	end
	
	local curTime = CurTime()
	
	if curTime < self.noCaptureTime then
		self.lastUpdate = curTime
		return
	end
	
	local defendingPlayers = 0
	local ownPos = self:GetPos()
	
	local red, blue = team.GetPlayers(TEAM_RED), team.GetPlayers(TEAM_BLUE)
	local redPlayers, redAlive = self:getClosePlayers(ownPos, red)
	local bluePlayers, blueAlive = self:getClosePlayers(ownPos, blue)
	local capturer, capturerPlayers, capturerAlive = nil, nil, nil
	local loser, loserPlayers = nil, nil
	
	-- if there are equal forces on both teams, then the enemy team will begin capture
	if redPlayers > bluePlayers then
		capturer = TEAM_RED
		capturerPlayers = redPlayers
		capturerAlive = redAlive
		loser = TEAM_BLUE
		loserPlayers = bluePlayers
	elseif bluePlayers > redPlayers then
		capturer = TEAM_BLUE
		capturerPlayers = bluePlayers
		capturerAlive = blueAlive
		loser = TEAM_RED
		loserPlayers = redPlayers
	end
	
	if curTime > self.dt.WaveTimeLimit then
		if self.dt.CaptureProgress ~= 0 then 
			if self.capturerTeam ~= 0 then
				-- make the capturers win, and make them not lose any tickets if no enemies are present on the point
				self:endWave(self.capturerTeam, loserPlayers == 0)
			end
		else
			self:endWave(nil, false)
		end
	end
	
	if capturer then
		local capSpeed = self.captureAmount
		
		if loserPlayers > 0 then -- if there are losing team players on the point, then the capture should be slower depending on how many people are on point
			local delta = math.abs(loserPlayers - capturerPlayers)
			delta = 1 - delta / capturerPlayers
			capSpeed = capSpeed * delta
		else
			capSpeed = capSpeed + (capturerPlayers - 1) * self.captureSpeedIncrease
		end
		
		local capSpeedMult = capturerPlayers / capturerAlive

		self:advanceCapture(capSpeed * capSpeedMult, capturer)
	else
		if curTime > self.deCaptureDelay then
			self.dt.CaptureProgress = math.Approach(self.dt.CaptureProgress, 0, 1)
			self.deCaptureDelay = curTime + self.deCaptureTime
			
			if self.dt.CaptureProgress == 0 then
				self:setCapturerTeam(0)
			end
		end
	end
	
	self.lastUpdate = curTime
end

function ENT:advanceCapture(capSpeed, capturerTeam)
	local delta = CurTime() - self.lastUpdate
	
	if capturerTeam ~= self.capturerTeam and self.dt.CaptureProgress ~= 0 then -- de-throne the previous capturer team in case they were capping it
		self.dt.CaptureProgress = math.Approach(self.dt.CaptureProgress, 0, capSpeed * delta * self.deCaptureSpeedMultiplier)
		
		if self.dt.CaptureProgress == 0 then
			self:setCapturerTeam(capturerTeam) -- update capturer team
		end
	else
		self.dt.CaptureProgress = math.Approach(self.dt.CaptureProgress, 100, capSpeed * delta)

		if self.roundOverOnCapture then
			if self.dt.CaptureProgress == 100 then
				self:endWave(self.capturerTeam, true)
				
				for key, ply in ipairs(team.GetPlayers(self.capturerTeam)) do
					ply:addCurrency(self.captureReward.cash, self.captureReward.exp, "OBJECTIVE_CAPTURED")
				end
				
				return
			end
		end
	end
	
	self.deCaptureDelay = CurTime() + self.deCaptureTimeOnCapture
end

function ENT:endWave(capturerTeam, noTicketDrainForWinner)
	self.noCaptureTime = CurTime() + self.noCaptureDuration -- disable capturing for 10 secs
	self.dt.CaptureProgress = 0 -- reset cap progress
	self:setupWaveTime(-15)
	GAMEMODE.curGametype:endWave(capturerTeam, noTicketDrainForWinner)
end

function ENT:drainTicket(teamID)
	if teamID == TEAM_RED then
		self.dt.RedTicketCount = math.Approach(self.dt.RedTicketCount, 0, 1)
	else
		self.dt.BlueTicketCount = math.Approach(self.dt.BlueTicketCount, 0, 1)
	end
end

function ENT:Use(activator, caller)
	return false
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end