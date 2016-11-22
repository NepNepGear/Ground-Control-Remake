GM.entityInitializer = {}
GM.entityInitializer.entClassCallbacks = {}

function GM.entityInitializer:initEntity(ent, curGameType, data)
	local class = ent:GetClass()
	
	if self.entClassCallbacks[class] then
		self.entClassCallbacks[class](ent, curGameType, data)
	end
end

function GM.entityInitializer:registerEntityInitializeCallback(entClass, callback)
	self.entClassCallbacks[entClass] = callback
end

GM.entityInitializer:registerEntityInitializeCallback("gc_capture_point", function(entity, curGameType, data)
	if data.data then
		if data.data.captureDistance then
			entity:setCaptureDistance(data.data.captureDistance)
		end

		if data.data.capturerTeam then
			entity:setCapturerTeam(data.data.capturerTeam)
			curGameType.realAttackerTeam = data.data.capturerTeam
		else
			entity:setCapturerTeam(curGameType.attackerTeam)
			curGameType.realAttackerTeam = curGameType.attackerTeam
		end
		
		if data.data.defenderTeam then
			entity:setDefenderTeam(data.data.defenderTeam)
			curGameType.realDefenderTeam = data.data.defenderTeam
		else
			entity:setDefenderTeam(curGameType.defenderTeam)
			curGameType.realDefenderTeam = curGameType.defenderTeam
		end
	else
		entity:setCapturerTeam(curGameType.attackerTeam)
		entity:setDefenderTeam(curGameType.defenderTeam)
	end
end)

GM.entityInitializer:registerEntityInitializeCallback("gc_offlimits_area", function(entity, curGameType, data)
	if data.data then
		if data.data.inverseFunctioning then
			entity.dt.inverseFunctioning = true
		end
		
		if data.data.targetTeam then
			entity.dt.targetTeam = data.data.targetTeam
		end
		
		if data.data.distance then
			entity.dt.distance = data.data.distance
		end
	end
end)

GM.entityInitializer:registerEntityInitializeCallback("gc_urban_warfare_capture_point", function(entity, curGameType, data)
	if data.data then
		if data.data.capMin then
			entity:setCaptureAABB(data.data.capMin, data.data.capMax)
		end
	end
	
	curGameType.capturePoint = entity
	
	local ticketAmount = nil
	
	if curGameType.ticketsPerPlayer then
		ticketAmount = math.Round(#player.GetAll() * curGameType.ticketsPerPlayer)
	else
		ticketAmount = curGameType.startingTickets
	end
	
	entity:initTickets(ticketAmount)
end)


GM.entityInitializer:registerEntityInitializeCallback("gc_drug_point", function(entity, curGameType, data)
	entity:freezeNearbyProps()
	entity:setHasDrugs(true)
end)