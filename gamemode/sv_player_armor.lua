include("sh_player_armor.lua")

util.AddNetworkString("GC_ARMOR")

local PLAYER = FindMetaTable("Player")

function PLAYER:processArmorDamage(dmgInfo, penetrationValue, hitGroup, allowBleeding)
	if not penetrationValue then
		return
	end
	
	local shouldBleed = true
	
	local removeIndex = 1
	
	for i = 1, #self.armor do
		local armorPiece = self.armor[removeIndex]
		local armorData = GAMEMODE:getArmorData(armorPiece.id, armorPiece.category)
		
		if armorData.protectionAreas[hitGroup] then
			local protectionDelta = armorData.protection - penetrationValue
			local penetratesArmor = protectionDelta < 0
			local damageNegation = nil
			
			if not penetratesArmor then
				shouldBleed = false
				
				damageNegation = armorData.damageDecrease + protectionDelta * armorData.protectionDeltaToDamageDecrease
				local regenAmount = math.floor(dmgInfo:GetDamage() * damageNegation)
				self:addHealthRegen(regenAmount)
				self:delayHealthRegen()
			else
				damageNegation = armorData.damageDecreasePenetration
				self:resetHealthRegenData() -- if our armor gets penetrated, it doesn't matter how much health we had in our regen pool, we still start bleeding
			end
			
			self:takeArmorDamage(armorPiece, dmgInfo)
			dmgInfo:ScaleDamage(1 - damageNegation)
			
			local health = armorPiece.health
			
			if armorPiece.health > 0 then
				removeIndex = removeIndex + 1
			else
				table.remove(self.armor, removeIndex)
				self:calculateWeight()
			end
			
			self:sendArmorPiece(i, health)
		end
	end
	
	if allowBleeding and shouldBleed then
		self:startBleeding()
	end
end

function PLAYER:giveArmor()
	self:resetArmorData()
	
	local desiredVest = self:getDesiredVest()
	
	if desiredVest ~= 0 then
		self:addArmorPart(desiredVest, "vest")
	end
	
	self:sendArmor()
end

function PLAYER:takeArmorDamage(armorData, dmgInfo)
	armorData.health = math.ceil(armorData.health - dmgInfo:GetDamage())
end

function PLAYER:addArmorPart(id, category)
	GAMEMODE:prepareArmorPiece(self, id, category)
end

function PLAYER:sendArmor()
	net.Start("GC_ARMOR")
		net.WriteTable(self.armor)
	net.Send(self)
end

function PLAYER:sendArmorPiece(index, health)
	umsg.Start("GC_ARMOR_PIECE", self)
		umsg.Char(index)
		umsg.Char(health)
	umsg.End()
end