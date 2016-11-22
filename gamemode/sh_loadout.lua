AddCSLuaFile()
AddCSLuaFile("cl_loadout.lua")

GM.DefaultPrimaryIndex = 1 -- default indexes for primary and secondary weapons in case we fail to get the number
GM.DefaultSecondaryIndex = 1
GM.DefaultTertiaryIndex = 1

GM.DefaultPrimaryMagCount = 3
GM.DefaultSecondaryMagCount = 3

GM.DefaultSpareAmmoCount = 0
GM.MaxSpareAmmoCount = 400

GM.MaxPrimaryMags = 5
GM.MaxSecondaryMags = 5

if CLIENT then
	include("cl_loadout.lua")
end

GM.RegisteredWeaponData = {}

GM.PrimaryWeapons = GM.PrimaryWeapons or {}
GM.SecondaryWeapons = GM.SecondaryWeapons or {}
GM.TertiaryWeapons = GM.TertiaryWeapons or {}
GM.CaliberWeights = GM.CaliberWeights or {}

BestPrimaryWeapons = BestPrimaryWeapons or {damage = -math.huge, recoil = -math.huge, aimSpread = math.huge, firerate = math.huge, hipSpread = math.huge, spreadPerShot = -math.huge, velocitySensitivity = math.huge, maxSpreadInc = -math.huge, speedDec = math.huge, weight = -math.huge, magWeight = -math.huge, penetrationValue = -math.huge}
BestSecondaryWeapons = BestSecondaryWeapons or {damage = -math.huge, recoil = -math.huge, aimSpread = math.huge, firerate = math.huge, hipSpread = math.huge, spreadPerShot = -math.huge, velocitySensitivity = math.huge, maxSpreadInc = -math.huge, speedDec = math.huge, weight = -math.huge, magWeight = -math.huge, penetrationValue = -math.huge}

local PLAYER = FindMetaTable("Player")

function PLAYER:getDesiredPrimaryMags()
	return math.Clamp(self:GetInfoNum("gc_primary_mags", GAMEMODE.DefaultPrimaryIndex), 1, GAMEMODE.MaxPrimaryMags)
end

function PLAYER:getDesiredSecondaryMags()
	return math.Clamp(self:GetInfoNum("gc_secondary_mags", GAMEMODE.DefaultPrimaryIndex), 1, GAMEMODE.MaxSecondaryMags)
end

function PLAYER:getDesiredPrimaryWeapon()
	local primary = math.Clamp(self:GetInfoNum("gc_primary_weapon", GAMEMODE.DefaultPrimaryIndex), 0, #GAMEMODE.PrimaryWeapons) -- don't go out of bounds
	return GAMEMODE.PrimaryWeapons[primary], primary
end

function PLAYER:getDesiredSecondaryWeapon()
	local secondary = math.Clamp(self:GetInfoNum("gc_secondary_weapon", GAMEMODE.DefaultSecondaryIndex), 0, #GAMEMODE.SecondaryWeapons)
	return GAMEMODE.SecondaryWeapons[secondary], secondary
end

function PLAYER:getDesiredTertiaryWeapon()
	local tertiary = math.Clamp(self:GetInfoNum("gc_tertiary_weapon", GAMEMODE.DefaultTertiaryIndex), 0, #GAMEMODE.TertiaryWeapons)
	return GAMEMODE.TertiaryWeapons[tertiary], tertiary
end

function PLAYER:adjustMagCount(weaponData, desiredMags)
	if not weaponData then
		return 0
	end
	
	if weaponData.magOverride then
		return weaponData.magOverride
	end
	
	if weaponData.maxMags then
		desiredMags = math.min(desiredMags, weaponData.maxMags)
	end
	
	return desiredMags
end

function GM:applyWeaponDataToWeaponClass(weaponData, primaryWeapon, slot)
	local wepClass = weapons.GetStored(weaponData.weaponClass)
	wepClass.weight = weaponData.weight -- apply weight to the weapon class
	wepClass.isPrimaryWeapon = primaryWeapon
	wepClass.Slot = slot
	wepClass.penetrationValue = weaponData.penetration

	weaponData.weaponObject = wepClass
	weaponData.processedWeaponObject = weapons.Get(weaponData.weaponClass)
end

function GM:setWeaponWeight(wepClass, weight)
	local wepObj = weapons.GetStored(wepClass)
	wepObj.weight = weight
end

function GM:disableDropsForWeapon(wepClass)
	local wepObj = weapons.GetStored(wepClass)
	wepObj.dropsDisabled = true
end

function GM:registerPrimaryWeapon(weaponData)
	weaponData.id = weaponData.id or weaponData.weaponClass
	self.RegisteredWeaponData[weaponData.id] = weaponData
	
	self:applyWeaponDataToWeaponClass(weaponData, true, 0)
	self.PrimaryWeapons[#self.PrimaryWeapons + 1] = weaponData
end

function GM:registerSecondaryWeapon(weaponData)
	weaponData.id = weaponData.id or weaponData.weaponClass
	self.RegisteredWeaponData[weaponData.id] = weaponData
	
	self:applyWeaponDataToWeaponClass(weaponData, false, 1)
	self.SecondaryWeapons[#self.SecondaryWeapons + 1] = weaponData
end

function GM:registerTertiaryWeapon(weaponData)
	weaponData.id = weaponData.id or weaponData.weaponClass
	self.RegisteredWeaponData[weaponData.id] = weaponData
	
	self:applyWeaponDataToWeaponClass(weaponData, false, 2)
	weapons.GetStored(weaponData.weaponClass).isTertiaryWeapon = true
	self.TertiaryWeapons[#self.TertiaryWeapons + 1] = weaponData
end

-- 1 grain = 0.06479891 gram
function GM:registerCaliberWeight(caliberName, grams) -- when registering a caliber's weight, the caliberName value should be the ammo type that the weapon uses
	self.CaliberWeights[caliberName] = grams / 1000 -- convert grams to kilograms in advance
end

function GM:findBestWeapons(lookInto, output)
	for key, weaponData in ipairs(lookInto) do
		local wepObj = weaponData.weaponObject
		
		output.damage = math.max(output.damage, wepObj.Damage * wepObj.Shots)
		output.recoil = math.max(output.recoil, wepObj.Recoil)
		output.aimSpread = math.min(output.aimSpread, wepObj.AimSpread)
		output.firerate = math.min(output.firerate, wepObj.FireDelay)
		output.hipSpread = math.min(output.hipSpread, wepObj.HipSpread)
		output.spreadPerShot = math.max(output.spreadPerShot, wepObj.SpreadPerShot)
		output.velocitySensitivity = math.min(output.velocitySensitivity, wepObj.VelocitySensitivity)
		output.maxSpreadInc = math.max(output.maxSpreadInc, wepObj.MaxSpreadInc)
		output.speedDec = math.min(output.speedDec, wepObj.SpeedDec)
		output.weight = math.max(output.weight, wepObj.weight)
		output.penetrationValue = math.max(output.penetrationValue, wepObj.penetrationValue)
		
		local magWeight = self:getAmmoWeight(wepObj.Primary.Ammo, wepObj.Primary.ClipSize)
		wepObj.magWeight = magWeight
		
		output.magWeight = math.max(output.magWeight, magWeight)
	end
end

function GM:getAmmoWeight(caliber, roundCount)
	roundCount = roundCount or 1
	return self.CaliberWeights[caliber] and self.CaliberWeights[caliber] * roundCount or 0
end

-- this function gets called in InitPostEntity for both the client and server, this is where we register a bunch of stuff
function GM:postInitEntity()
	-- battle rifles
	local g3a3 = {}
	g3a3.weaponClass = "cw_g3a3"
	g3a3.weight = 4.1
	g3a3.penetration = 18

	self:registerPrimaryWeapon(g3a3)

	local scarH = {}
	scarH.weaponClass = "cw_scarh"
	scarH.weight = 3.72
	scarH.penetration = 18
	
	self:registerPrimaryWeapon(scarH)
	
	local m14 = {}
	m14.weaponClass = "cw_m14"
	m14.weight = 5.1
	m14.penetration = 18
	
	self:registerPrimaryWeapon(m14)
	
	-- assault rifles
	local ak74 = {}
	ak74.weaponClass = "cw_ak74"
	ak74.weight = 3.07
	ak74.penetration = 17
	
	self:registerPrimaryWeapon(ak74)

	local ar15 = {}
	ar15.weaponClass = "cw_ar15"
	ar15.weight = 2.88
	ar15.penetration = 16
	
	self:registerPrimaryWeapon(ar15)
	
	local g36c = {}
	g36c.weaponClass = "cw_g36c"
	g36c.weight = 2.82
	g36c.penetration = 16
	
	self:registerPrimaryWeapon(g36c)
	
	local g36c = {}
	g36c.weaponClass = "cw_l85a2"
	g36c.weight = 3.82
	g36c.penetration = 16
	
	self:registerPrimaryWeapon(g36c)
	
	local vss = {}
	vss.weaponClass = "cw_vss"
	vss.weight = 2.6
	vss.penetration = 15
	
	self:registerPrimaryWeapon(vss)
	
	-- sub-machine guns
	local mp5 = {}
	mp5.weaponClass = "cw_mp5"
	mp5.weight = 2.5
	mp5.penetration = 9
	
	self:registerPrimaryWeapon(mp5)
	
	local mac11 = {}
	mac11.weaponClass = "cw_mac11"
	mac11.weight = 1.59
	mac11.penetration = 6
	
	self:registerPrimaryWeapon(mac11)
	
	local ump45 = {}
	ump45.weaponClass = "cw_ump45"
	ump45.weight = 2.5
	ump45.penetration = 9
	
	self:registerPrimaryWeapon(ump45)
	
	local m249 = {}
	m249.weaponClass = "cw_m249_official"
	m249.weight = 7.5
	m249.penetration = 16
	m249.maxMags = 2
	
	self:registerPrimaryWeapon(m249)
	
	-- shotguns
	local m3super90 = {}
	m3super90.weaponClass = "cw_m3super90"
	m3super90.weight = 3.27
	m3super90.penetration = 5
	
	self:registerPrimaryWeapon(m3super90)
	
	local serbushorty = {}
	serbushorty.weaponClass = "cw_shorty"
	serbushorty.weight = 1.8
	serbushorty.penetration = 5
	
	self:registerPrimaryWeapon(serbushorty)
	
	-- sniper rifles	
	local l115 = {}
	l115.weaponClass = "cw_l115"
	l115.weight = 6.5
	l115.penetration = 30
	
	self:registerPrimaryWeapon(l115)
	
	-- handguns
	local deagle = {}
	deagle.weaponClass = "cw_deagle"
	deagle.weight = 1.998
	deagle.penetration = 17
	
	self:registerSecondaryWeapon(deagle)
	
	local mr96 = {}
	mr96.weaponClass = "cw_mr96"
	mr96.weight = 1.22
	mr96.penetration = 14
	
	self:registerSecondaryWeapon(mr96)
	
	local m1911 = {}
	m1911.weaponClass = "cw_m1911"
	m1911.weight = 1.105
	m1911.penetration = 7
	
	self:registerSecondaryWeapon(m1911)
	
	local fiveseven = {}
	fiveseven.weaponClass = "cw_fiveseven"
	fiveseven.weight = 0.61
	fiveseven.penetration = 11
	
	self:registerSecondaryWeapon(fiveseven)
	
	local p99 = {}
	p99.weaponClass = "cw_p99"
	p99.weight = 0.63
	p99.penetration = 7
	
	self:registerSecondaryWeapon(p99)
	
	local makarov = {}
	makarov.weaponClass = "cw_makarov"
	makarov.weight = 0.63
	makarov.penetration = 6
	
	self:registerSecondaryWeapon(makarov)
	
	local flash = {}
	flash.weaponClass = "cw_flash_grenade"
	flash.weight = 0.5
	flash.startAmmo = 2
	flash.hideMagIcon = true -- whether the mag icon and text should be hidden in the UI for this weapon
	flash.description = {{t = "Flashbang", font = "CW_HUD24", c = Color(255, 255, 255, 255)},
		{t = "Blinds nearby enemies facing the grenade upon detonation.", font = "CW_HUD20", c = Color(255, 255, 255, 255)},
		{t = "2x grenades.", font = "CW_HUD20", c = Color(255, 255, 255, 255)}
	}
		
	
	self:registerTertiaryWeapon(flash)
	
	local smoke = {}
	smoke.weaponClass = "cw_smoke_grenade"
	smoke.weight = 0.5
	smoke.startAmmo = 2
	smoke.hideMagIcon = true
	smoke.description = {{t = "Smoke grenade", font = "CW_HUD24", c = Color(255, 255, 255, 255)},
		{t = "Provides a smoke screen to deter enemies from advancing or pushing through.", font = "CW_HUD20", c = Color(255, 255, 255, 255)},
		{t = "2x grenades.", font = "CW_HUD20", c = Color(255, 255, 255, 255)}
	}
	
	self:registerTertiaryWeapon(smoke)
	
	local spareGrenade = {}
	spareGrenade.weaponClass = "cw_frag_grenade"
	spareGrenade.weight = 0.5
	spareGrenade.amountToGive = 1
	spareGrenade.skipWeaponGive = true
	spareGrenade.hideMagIcon = true
	spareGrenade.description = {{t = "Spare frag grenade", font = "CW_HUD24", c = Color(255, 255, 255, 255)},
		{t = "Allows for a second frag grenade to be thrown.", font = "CW_HUD20", c = Color(255, 255, 255, 255)}
	}
	
	function spareGrenade:postGive(ply)
		ply:GiveAmmo(self.amountToGive, "Frag Grenades")
	end
	
	self:registerTertiaryWeapon(spareGrenade)
	
	-- KNIFE, give it 0 weight and make it undroppable (can't shoot out of hand, can't drop when dying)
	local wepObj = weapons.GetStored(self.KnifeWeaponClass)
	wepObj.weight = 0
	wepObj.dropsDisabled = true
	wepObj.isKnife = true
	
	self:registerCaliberWeight("7.62x51MM", 25.4)
	self:registerCaliberWeight("7.62x39MM", 16.3)
	self:registerCaliberWeight("5.45x39MM", 10.7)
	self:registerCaliberWeight("5.56x45MM", 11.5)
	self:registerCaliberWeight("9x19MM", 8.03)
	self:registerCaliberWeight(".50 AE", 22.67)
	self:registerCaliberWeight(".44 Magnum", 16)
	self:registerCaliberWeight(".45 ACP", 15)
	self:registerCaliberWeight("12 Gauge", 50)
	self:registerCaliberWeight(".338 Lapua", 46.2)
	self:registerCaliberWeight("9x39MM", 24.2)
	self:registerCaliberWeight("9x17MM", 7.5)
	self:registerCaliberWeight("5.7x28MM", 6.15)
	self:registerCaliberWeight("9x18MM", 8)
	
	self:findBestWeapons(self.PrimaryWeapons, BestPrimaryWeapons)
	self:findBestWeapons(self.SecondaryWeapons, BestSecondaryWeapons)
	weapons.GetStored("cw_base").AddSafeMode = false -- disable safe firemode
	
	if CLIENT then
		self:createMusicObjects()
	end
	
	hook.Call("GroundControlPostInitEntity", nil)
end