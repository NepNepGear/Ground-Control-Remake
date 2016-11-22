-- this system allows you to register maps that should be added to the download list upon switching to it

GM.AutoDownloadMap = {}

function GM:registerAutoDownloadMap(mapName, workshopID)
	self.AutoDownloadMap[mapName] = tostring(workshopID)
end

function GM:getAutoDownloadMapID(mapName)
	return self.AutoDownloadMap[mapName]
end

function GM:verifyAutoDownloadMap()
	local map = string.lower(game.GetMap())

	if self.AutoDownloadMap[map] then
		resource.AddWorkshop(self.AutoDownloadMap[map])
	end
end

GM:registerAutoDownloadMap("cs_jungle", "123379735")
GM:registerAutoDownloadMap("cs_siege_2010", "531654625")
GM:registerAutoDownloadMap("de_desert_atrocity_v3", "242494243")
GM:registerAutoDownloadMap("gc_outpost", "607623397")
GM:registerAutoDownloadMap("rp_downtown_v2", "107982746")
GM:registerAutoDownloadMap("cs_east_borough", "296957963")
GM:registerAutoDownloadMap("de_desert_atrocity_v3", "242494243")
GM:registerAutoDownloadMap("rp_downtown_v4c_v2", "110286060")
GM:registerAutoDownloadMap("ph_skyscraper_construct", "656887320")
GM:registerAutoDownloadMap("gc_depot_b1", "665179105")
GM:registerAutoDownloadMap("de_shanty_v3_fix", "528435972")
GM:registerAutoDownloadMap("de_secretcamp", "296555359")

--GM:registerAutoDownloadMap("gm_bay", "104484764")
-- example usage: GM:registerAutoDownloadMap("gm_some_map", "workshopID")
-- the workshop ID is numeric, ie 104484764, but has to be passed as a string, ie "104484764"