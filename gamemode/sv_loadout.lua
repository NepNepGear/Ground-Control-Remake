include("sh_loadout.lua")

local PLAYER = FindMetaTable("Player")

function PLAYER:attemptGiveLoadoutAmmo(weaponData)
	local wep = self:GetWeapon(weaponData.weaponClass)
	
	if weaponData.startAmmo then
		wep.Owner:SetAmmo(weaponData.startAmmo, wep.Primary.Ammo)
	end
end

function PLAYER:attemptGiveWeapon(givenWeaponData)
	if not givenWeaponData then
		return
	end
	
	if givenWeaponData.weaponClass and not givenWeaponData.skipWeaponGive then
		self:Give(givenWeaponData.weaponClass)
	end
	
	if givenWeaponData.onGive then
		givenWeaponData:onGive(self)
	end
end

function PLAYER:attemptPostGiveWeapon(givenWeaponData)
	if givenWeaponData.postGive then
		givenWeaponData:postGive(self)
	end
end

function PLAYER:giveLoadout(forceGive)
	if not forceGive and GAMEMODE.curGametype.canReceiveLoadout then
		if not GAMEMODE.curGametype:canReceiveLoadout(self) then
			return
		end
	end
	
	self:StripWeapons()
	self:RemoveAllAmmo()
	self:resetGadgetData()
	self:applyTraits()
	
	-- get the weapons we want to spawn with
	local primaryData = self:getDesiredPrimaryWeapon()
	local secondaryData = self:getDesiredSecondaryWeapon()
	local tertiaryData = self:getDesiredTertiaryWeapon()
	
	-- give the weapons
	self:attemptGiveWeapon(primaryData)
	self:attemptGiveWeapon(secondaryData)
	self:attemptGiveWeapon(tertiaryData)
	
	-- get the amount of ammo we want to spawn with
	local primaryMags = self:getDesiredPrimaryMags()
	local secondaryMags = self:getDesiredSecondaryMags()
	
	primaryMags = self:adjustMagCount(primaryData, primaryMags)
	secondaryMags = self:adjustMagCount(secondaryData, secondaryMags)
	
	local plyObj = self
	
	timer.Simple(0.3, function()
		if not IsValid(plyObj) or not plyObj:Alive() then
			return 
		end
		
		if GAMEMODE.curGametype.skipAttachmentGive then
			if not GAMEMODE.curGametype:skipAttachmentGive(self) then
				CustomizableWeaponry.giveAttachments(self, self.ownedAttachmentsNumeric, true, true)
			end
		else
			CustomizableWeaponry.giveAttachments(self, self.ownedAttachmentsNumeric, true, true)
		end
		
		local primaryWepObj, secWepObj = nil, nil
		
		if primaryData then
			primaryWepObj = plyObj:GetWeapon(primaryData.weaponClass)
			plyObj:setupAttachmentLoadTable(primaryWepObj)
			plyObj:equipAttachments(primaryWepObj, GAMEMODE.AttachmentLoadTable)
		end
		
		if secondaryData then
			secWepObj = plyObj:GetWeapon(secondaryData.weaponClass)
			plyObj:setupAttachmentLoadTable(secWepObj)
			plyObj:equipAttachments(secWepObj, GAMEMODE.AttachmentLoadTable)
		end
		
		plyObj:RemoveAllAmmo() -- remove any ammo that may have been added to our reserve
		
		if primaryWepObj then
			plyObj:GiveAmmo(primaryMags * primaryWepObj.Primary.ClipSize_Orig, primaryWepObj.Primary.Ammo) -- set the ammo after we've attached everything, since some attachments may modify mag size
			primaryWepObj:maxOutWeaponAmmo(primaryWepObj.Primary.ClipSize_Orig) -- same for the magazine
		end
		
		if secWepObj then
			plyObj:GiveAmmo(secondaryMags * secWepObj.Primary.ClipSize_Orig, secWepObj.Primary.Ammo)
			secWepObj:maxOutWeaponAmmo(secWepObj.Primary.ClipSize_Orig)
		end
		
		plyObj:GiveAmmo(1, "Frag Grenades")
		
		if primaryData then
			plyObj:attemptGiveLoadoutAmmo(primaryData)
			plyObj:attemptPostGiveWeapon(primaryData)
		end
		
		if secondaryData then
			plyObj:attemptGiveLoadoutAmmo(secondaryData)
			plyObj:attemptPostGiveWeapon(secondaryData)
		end
		
		if tertiaryData then
			plyObj:attemptGiveLoadoutAmmo(tertiaryData)
			plyObj:attemptPostGiveWeapon(tertiaryData)
		end
		
		plyObj:setWeight(plyObj:calculateWeight())
		
		if plyObj.weight >= GAMEMODE.MaxWeight * 0.65 then
			plyObj:sendTip("HIGH_WEIGHT")
		end
	end)
	
	self:giveGadgets()
	self:giveArmor()
	self:Give(GAMEMODE.KnifeWeaponClass)
end

function PLAYER:attemptGiveLoadout()
	if GAMEMODE.LoadoutSelectTime and CurTime() < GAMEMODE.LoadoutSelectTime and (self.spawnPoint and self:GetPos():Distance(self.spawnPoint) <= GAMEMODE.LoadoutDistance) then
		self:giveLoadout()
	end
end

concommand.Add("gc_ask_for_loadout", function(ply)
	if not ply:Alive() then
		return
	end
	
	ply:attemptGiveLoadout()
end)