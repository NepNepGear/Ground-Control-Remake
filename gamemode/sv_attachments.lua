AddCSLuaFile("cl_attachments.lua")
include("sh_attachments.lua")

util.AddNetworkString("GC_ATTACHMENTS")

local PLAYER = FindMetaTable("Player")

GM.AttachmentDirectory = GM.MainDataDirectory .. "/player_attachments/" -- where we save the attachments that players possess
GM.AttachmentLoadTable = {}
GM.ExpAmount = {exp = nil}

file.verifyDataFolder(GM.MainDataDirectory)
file.verifyDataFolder(GM.AttachmentDirectory)

function PLAYER:saveAttachments()
	local data = util.TableToJSON(self.ownedAttachments)
	
	file.Write(GAMEMODE.AttachmentDirectory .. self:SteamID64() .. ".txt", data)
end

function PLAYER:loadAttachments()
	local readData = file.Read(GAMEMODE.AttachmentDirectory .. self:SteamID64() .. ".txt", "DATA")
	readData = readData and util.JSONToTable(readData) or {}
	
	self.ownedAttachmentsNumeric = {}
	self.ownedAttachments = readData
	self:updateNumericAttachmentsTable(readData)
	self:sendAttachments()
end

function PLAYER:checkForAttachmentSlotUnlock()
	local reqExp = self:getNextAttachmentSlotPrice()
	local residue = self.experience - reqExp
	
	if residue > 0 then
		if self:canUnlockMoreSlots() then
			self:unlockAttachmentSlot()
			self:setExperience(residue)
		else
			self:setExperience(0)
		end
	end
end

function PLAYER:unlockAttachmentSlot()
	self.unlockedAttachmentSlots = self.unlockedAttachmentSlots + 1
	self:saveUnlockedAttachmentSlots()
	self:sendUnlockedAttachmentSlots()
end

function PLAYER:updateNumericAttachmentsTable(fillWith)
	if type(fillWith) == "string" then
		table.insert(self.ownedAttachmentsNumeric, fillWith)
	elseif type(fillWith) == "table" then
		for attachmentName, name in pairs(fillWith) do
			table.insert(self.ownedAttachmentsNumeric, attachmentName)
		end
	end
end

function PLAYER:unlockAttachment(attachmentName, isFree)
	local attachmentData = CustomizableWeaponry.registeredAttachmentsSKey[attachmentName]
	local price = nil
	
	if isFree then
		price = 0
	else
		price = attachmentData.price
	end
	
	if not isFree and (not price or price < 0) or self.ownedAttachments[attachmentName] then -- this attachment is free/already was bought, what are you doing
		return
	end
	
	if self.cash >= price then
		self.ownedAttachments[attachmentName] = true
		self:removeCash(price)
		self:sendUnlockedAttachment(attachmentName)
		self:saveAttachments()
		
		self:updateNumericAttachmentsTable(attachmentName)
	else
		umsg.Start("GC_NOT_ENOUGH_CASH", self)
			umsg.Long(price)
		umsg.End()
	end
end

function PLAYER:lockAttachment(attachmentName) -- no idea why you would need this, but whatever
	self.ownedAttachments[attachmentName] = nil
end

function PLAYER:sendUnlockedAttachment(attachmentName)
	umsg.Start("GC_UNLOCK_ATTACHMENT", self)
		umsg.String(attachmentName)
	umsg.End()
end

function PLAYER:sendAttachments()
	net.Start("GC_ATTACHMENTS")
		net.WriteTable(self.ownedAttachments)
	net.Send(self)
end

function PLAYER:setupAttachmentLoadTable(weaponObject)
	table.clear(GAMEMODE.AttachmentLoadTable)
	
	--local baseConvarName = weaponObject.isPrimaryWeapon and "gc_primary_attachment_" or "gc_secondary_attachment_"
	local targetTable = weaponObject.isPrimaryWeapon and GAMEMODE.PrimaryAttachmentStrings or GAMEMODE.SecondaryAttachmentStrings
	
	for i = 1, self:getAvailableAttachmentSlotCount() do -- get all attachments the player can set up on the client
		local desiredAttachment = self:GetInfo(targetTable[i]) --self:GetInfo(baseConvarName .. i)
		
		if desiredAttachment and self:hasUnlockedAttachment(desiredAttachment) then -- check whether the attachment exists
			for category, data in pairs(weaponObject.Attachments) do -- now we iterate over all weapon attachments, find it in it's category and assign the category to the attachment name
				for index, attachmentName in ipairs(data.atts) do
					if attachmentName == desiredAttachment then
						GAMEMODE.AttachmentLoadTable[category] = index
					end
				end
			end
		end
	end
end

function PLAYER:equipAttachments(targetWeapon, data)
	-- and lastly, we load all the attachments via CW 2.0's attachment preset system
	CustomizableWeaponry.preset.load(targetWeapon, data, "GroundControlPreset")
end

function PLAYER:sendUnlockedAttachmentSlots()
	umsg.Start("GC_UNLOCKED_SLOTS", self)
		umsg.Char(self.unlockedAttachmentSlots)
	umsg.End()
end

function PLAYER:loadUnlockedAttachmentSlots()
	local slots = self:GetPData("GroundControlUnlockedAttachmentSlots") or 0
	
	self.unlockedAttachmentSlots = tonumber(slots)
end

function PLAYER:saveUnlockedAttachmentSlots()
	self:SetPData("GroundControlUnlockedAttachmentSlots", self.unlockedAttachmentSlots)
end

function PLAYER:loadExperience()
	local exp = self:GetPData("GroundControlExperience") or 0
	
	self.experience = tonumber(exp)
end

function PLAYER:saveExperience()
	self:SetPData("GroundControlExperience", self.experience)
end

function PLAYER:sendExperience()
	umsg.Start("GC_EXPERIENCE", self)
		umsg.Long(self.experience)
	umsg.End()
end

function PLAYER:addExperience(amount, event)
	self:SetNWInt("GC_SCORE", self:GetNWInt("GC_SCORE") + amount)
	
	if not self:canUnlockMoreSlots() then
		return
	end
	
	self.experience = math.max(self.experience + amount, 0)
	self:checkForAttachmentSlotUnlock()
	self:saveExperience()
	
	self:sendExperience()
	
	if event then
		GAMEMODE.ExpAmount.exp = amount
		GAMEMODE:sendEvent(self, event, GAMEMODE.ExpAmount)
	end
end

concommand.Add("gc_buy_attachment", function(ply, com, args)
	local attName = args[1]
	
	if not attName then
		return
	end
	
	if not ply:hasUnlockedAttachment(attName) then
		ply:unlockAttachment(attName)
	end
end)