AddCSLuaFile()

GM.MaxAttachments = 6 -- maximum attachments per weapon
GM.DefaultAttachmentPrice = 2000
GM.PrimaryAttachmentString = "gc_primary_attachment_"
GM.SecondaryAttachmentString = "gc_secondary_attachment_"

GM.LockedAttachmentSlots = 3 -- amount of locked slots
GM.BaseLockedSlotPrice = 3000 -- base price of any locked slot (in experience, not cash)
GM.PriceIncreasePerSlot = 1000 -- how much it's price increases per slot (ie. at 1000 first slot will cost 4000, second will cost 5000, third 6000)

GM.PrimaryAttachmentStrings = {}
GM.SecondaryAttachmentStrings = {}

--[[ here's how I decided to price attachments:

	SIGHTS, SHARED ATTACHMENTS and SUPPRESSORS are the least expensive, but their price depends on the magnification level they provide as well as their downsides (no downsides = more expensive)
	AMMO is in the middle in terms of price
	WEAPON-SPECIFIC MODS are most expensive, unless their role is not significant (ie. stocks)
	
]]--

GM.attachmentPrices = {bg_ak74_rpkbarrel = 2500,
	bg_ak74_ubarrel = false, -- free, since it's a variant of the AK-74
	bg_ak74foldablestock = 1000,
	bg_ak74heavystock = 1250,
	bg_ak74rpkmag = 1500,
	bg_ar15sturdystock = 1000,
	bg_ar15heavystock = 1250,
	bg_ar1560rndmag = 2000,
	bg_bipod = 1500,
	bg_deagle_compensator = 1000,
	bg_deagle_extendedbarrel = 1000,
	bg_longbarrel = false, -- free, since it's a variant of the AR-15
	bg_longris = 1500,
	bg_magpulhandguard = 1000,
	bg_longbarrelmr96 = 1000,
	bg_mp5_kbarrel = false, -- free, since it's a variant of the MP5
	bg_mp5_sdbarrel = 1500,
	bg_mp530rndmag = false,
	bg_nostock = false, -- free, since it's a variant of the MP5
	bg_regularbarrel = 1000,
	bg_retractablestock = 1000,
	bg_ris = 1250,
	bg_sg1scope = 1500,
	bg_asval_20rnd = 1000,
	bg_asval = false, -- free, since it's a variant of the VSS Vintorez
	bg_mac11_extended_barrel = 1000,
	bg_mac11_unfolded_stock = false, -- free, since you can unfold it on your own (unlike payday 2 lmao)
	md_acog = 1500, -- pretty big jump in price due to: 1. 4x magnification 2. back up sights, effectively making it a 2-in-1
	md_schmidt_shortdot = 1250,
	md_aimpoint = 1000, -- as expensive as a micro T1 due to it providing a bigger FOV zoom
	md_anpeq15 = 1500,
	md_cobram2 = 1000,
	md_eotech = 800,
	md_microt1 = 1000, -- "eotech is cheaper than a micro t1? what gives?", the Micro T1 has no mobility decrease, that's why
	md_foregrip = 1500,
	md_kobra = 800,
	md_m203 = 2000,
	md_pbs1 = 1500,
	md_pso1 = 1250,
	md_saker = 1500,
	md_bipod = 1000,
	md_tundra9mm = 1000,
	am_flechetterounds = 1500,
	am_magnum = 1500,
	am_matchgrade = 1500,
	am_slugrounds = 1500,
	bg_makarov_extmag = 1000,
	bg_makarov_pb6p9 = false, -- free, a variant of the PM
	bg_makarov_pb_suppressor = false, -- free, part of PB
	bg_makarov_pm_suppressor = 1000, -- not free, optional part of PM
	am_sp7 = 1000, -- not free, optional part of PM
	md_insight_x2 = 1500,
	md_rmr = 1000
}

for i = 1, GM.MaxAttachments do
	CreateClientConVar(GM.PrimaryAttachmentString .. i, "0", true, true)
	table.insert(GM.PrimaryAttachmentStrings, GM.PrimaryAttachmentString .. i)
	
	CreateClientConVar(GM.SecondaryAttachmentString .. i, "0", true, true)
	table.insert(GM.SecondaryAttachmentStrings, GM.SecondaryAttachmentString .. i)
end

function GM:getFreeSlotCount()
	return self.MaxAttachments - self.LockedAttachmentSlots
end

function GM:registerAttachment(data)
	local attData = CustomizableWeaponry.registeredAttachmentsSKey[data.attachmentName]
	attData.price = data.price
	attData.unlockedByDefault = data.unlockedByDefault
end

function GM:setAttachmentPrice(attachmentName, desiredPrice)
	CustomizableWeaponry.registeredAttachmentsSKey[data.attachmentName].price = desiredPrice
end

local foldSight = {}
foldSight.price = false
foldSight.attachmentName = "bg_foldsight"

GM:registerAttachment(foldSight)

local bigMagMP5 = {}
bigMagMP5.price = false
bigMagMP5.attachmentName = "bg_mp530rndmag"

GM:registerAttachment(bigMagMP5)

for key, value in pairs(CustomizableWeaponry.registeredAttachmentsSKey) do -- iterate over the attachments
	if value.price == nil then -- check which ones don't have a price set on them, and set the default price (specifically a nil check, since if the price is 'false', it'll still get set to DefaultAttachmentPrice)
		value.price = GM.DefaultAttachmentPrice
	end
end

for attName, price in pairs(GM.attachmentPrices) do
	CustomizableWeaponry.registeredAttachmentsSKey[attName].price = price
end

local PLAYER = FindMetaTable("Player")

function PLAYER:hasUnlockedAttachment(attachmentName)
	local attData = CustomizableWeaponry.registeredAttachmentsSKey[attachmentName]
	
	if not attData then
		return false
	end
	
	if not attData.price or attData.price < 0 then -- first we check whether the attachment is free by default
		return true
	end
	
	return self.ownedAttachments[attachmentName] 
end

function PLAYER:getNextAttachmentSlotPrice(slot)
	slot = slot or self.unlockedAttachmentSlots + 1
	
	local freeSlots = GAMEMODE:getFreeSlotCount()
	local slotPrice = GAMEMODE.BaseLockedSlotPrice + slot * GAMEMODE.PriceIncreasePerSlot
	
	return slotPrice
end

function PLAYER:getUnlockedAttachmentSlots()
	return math.Clamp(GAMEMODE:getFreeSlotCount() + self.unlockedAttachmentSlots, 0, GAMEMODE.MaxAttachments)
end

function PLAYER:canUnlockMoreSlots()
	return self:getUnlockedAttachmentSlots() < GAMEMODE.MaxAttachments
end

function PLAYER:isAttachmentSlotUnlocked(slot)
	return self.unlockedAttachmentSlots >= slot
end

function PLAYER:canUnlockAttachmentSlot()
	return self.experience >= self:getNextAttachmentSlotPrice()
end

function PLAYER:setUnlockedAttachmentSlots(slotAmount)
	self.unlockedAttachmentSlots = slotAmount
	
	if SERVER then
		self:sendUnlockedAttachmentSlots()
	end
end

function PLAYER:getAvailableAttachmentSlotCount()
	return self.unlockedAttachmentSlots + GAMEMODE:getFreeSlotCount()
end

function PLAYER:setExperience(exp)
	if SERVER then
		if not self:canUnlockMoreSlots() then
			return
		end
	
		self.experience = exp
		self:checkForAttachmentSlotUnlock()
		self:saveExperience()
		
		self:sendExperience()
	else
		self.experience = exp
	end
end